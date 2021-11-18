convertGeneSymbolsMouseToHuman <- function(mgg) {

    human = useMart("ensembl", dataset = "hsapiens_gene_ensembl", host="www.ensembl.org")
    mouse = useMart("ensembl", dataset = "mmusculus_gene_ensembl", host="www.ensembl.org")

    mggu=unique(sort(mgg))

    genesV2 = getLDS(
        attributes = c("mgi_symbol"),
        filters = "mgi_symbol",
        values = mggu,
        mart = mouse,
        attributesL = c("hgnc_symbol"),
        martL = human,
        uniqueRows=T)

    genesV2

}

################################################################################
# Parse args
################################################################################

if(!exists("len")) source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<1) {
    cat("\n\tusage: addNormalFillData.R [MANIFEST=MANIFESTFILE] INPUT.maf [OUTPUT_BASE]\n\n")
    quit()
}

MANIFEST_FILE=NULL
ii=grep("MANIFEST=",args)
if(len(ii)==1) {
    MANIFEST_FILE=gsub(".*=","",args[ii])
    args=args[-ii]
}

suppressPackageStartupMessages({
    require(biomaRt)
    require(tidyverse)
    require(openxlsx)
    })

SDIR=Sys.getenv("SDIR")

source(file.path(SDIR,"tools.R"))
source(file.path(SDIR,"mafFilters.R"))
source(file.path(SDIR,"VERSION.R"))

################################################################################
################################################################################

# Read config file

config=read_postConfig()

INPUT_MAFFILE=args[1]

if(len(args)==2) {
    OUTPUT_MAFFILE=args[2]
} else {
    OUTPUT_MAFFILE=cc("Proj",config$projectNo,"VEP_MAF_","PostV6c")
}

if(is.null(MANIFEST_FILE)) {
    tumors=get_TumorSampleIDs(config$PIPELINEDIR)
    cohortNormals=get_CohortNormalIDs(config$PIPELINEDIR)
} else {
    manifest=read_csv(MANIFEST_FILE)
    tumors=manifest %>% filter(TYPE=="T")  %>% distinct(SAMPLE) %>% pull
    cohortNormals=manifest %>% filter(TYPE=="N")  %>% distinct(SAMPLE) %>% pull
}

cat("\n\n")
cat("   Tumors =", paste(tumors),"\n\n")
if(len(cohortNormals)>0) {
    cat("   Cohort Normals =", paste(cohortNormals),"\n\n")
} else {
    cat("\n\n")
    cat("  No normals found\n")
    cat("\n    Need to specify explict manifest file to indicate tumors/normals\n\n")
    cat("           MANIFEST.CSV:\n")
    cat("            SAMPLE,TYPE\n")
    cat("            S1,T\n")
    cat("            S2,N\n")
    cat("\n")
    quit()

}

################################################################################
# Read MAF
################################################################################

mafHeader=read_mafHeader(INPUT_MAFFILE)
maf=read_maf(INPUT_MAFFILE)

cohort.stats=maf %>%
    filter(Tumor_Sample_Barcode %in% tumors) %>%
    count(ETAG) %>%
    mutate(Cohort.PCT=n/len(tumors)) %>%
    rename(Cohort.N=n)

numeric.cols=vars(matches("^Normal_CTRLS_|^POOL_"))

# maf1=maf %>%
#     filter(Tumor_Sample_Barcode %in% tumors) %>%
#     left_join(cohort.stats,by="ETAG") %>%
#     mutate_at(numeric.cols,as.numeric) %>%
#     mutate(FILTER="PASS",FILTER.REASON="") %>%
#     mutate(BINOM.pv=pbinom(t_var_freq,2,(POOL_tAD+1)/(POOL_tDP+1),lower=F)) %>%
#     mutate(BINOM.or=BINOM.pv/(1-BINOM.pv)) %>%
#     mutate(tVafFreqP=(t_alt_count+1)/(t_depth+2)) %>%
#     mutate(BINOM.lor=log10((tVafFreqP/(1-tVafFreqP))/BINOM.or)) %>%
#     mutate(BINOM.Q=-10*log10(BINOM.pv))

maf1=maf %>%
    filter(Tumor_Sample_Barcode %in% tumors) %>%
    left_join(cohort.stats,by="ETAG") %>%
    mutate_at(numeric.cols,as.numeric) %>%
    mutate(FILTER="PASS",FILTER.REASON="") %>%
    mutate(AllNormal_tDP=Normal_CTRLS_tDP+POOL_tDP) %>%
    mutate(AllNormal_tAD=Normal_CTRLS_tAD+POOL_tAD) %>%
    mutate(AllNormal_tFreqP=(AllNormal_tAD+1)/(AllNormal_tDP+2)) %>%
    mutate(tVafFreqP=(t_alt_count+1)/(t_depth+2)) %>%
    mutate(BINOM.pv=pbinom(t_var_freq,2,(AllNormal_tAD+1)/(AllNormal_tDP+1),lower=F)) %>%
    mutate(SNR.lor=log10((tVafFreqP/(1-tVafFreqP))/(AllNormal_tFreqP/(1-AllNormal_tFreqP))))


ii.f=maf1$filter.Targetted!=""
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"NotTargetted",sep=",")

ii.fdr=maf1$FILTER=="PASS"
maf1$BINOM.fdr=NA
maf1$BINOM.fdr[ii.fdr]=p.adjust(maf1$BINOM.pv[ii.fdr],"fdr")

ii.f=grepl("^rs\\d+",maf1$dbSNP_RS)
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"NotNovel",sep=",")

ii.f=which(!(maf1$Normal_CTRLS_maxVF<.25))
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"PresentInControls",sep=",")

ii.f=which(!(maf1$SNR.lor>log10(10) & maf1$BINOM.fdr<.2))
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"PresentInPool",sep=",")

if.f=which(maf1$t_alt_count>=8)
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"ADToLow",sep=",")

if.f=which(maf1$t_var_freq>0.02)
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"VAFToLow",sep=",")

#
# Mark events that were also detected in any one of the
# cohort normals
#

cohortNormalEvents=maf %>%
    filter(Tumor_Sample_Barcode %in% cohortNormals) %>%
    filter(t_var_freq>0.10 & t_alt_count>=10) %>%
    select(ETAG,Tumor_Sample_Barcode,Matched_Norm_Sample_Barcode,matches("[tn]_(count|depth)|t_var_freq")) %>%
    rename_at(-1,~paste0("CohortNormal.",.))

ii.f=which(maf1$ETAG %in% cohortNormalEvents$ETAG)

#
# Since we may not always want to filter these out
# create a table with them so it is easy to see what was
# removed with this filter
#

cohorNormalFilteredEvents=maf1[ii.f,] %>%
    filter(FILTER.REASON=="") %>%
    select(
            Tumor_Sample_Barcode,Matched_Norm_Sample_Barcode,
            Hugo_Symbol,Chromosome,Start_Position,Variant_Classification,
            Reference_Allele,matches("[tn]_(count|depth)|t_var_freq"),ETAG
            ) %>%
    left_join(cohortNormalEvents,by="ETAG") %>%
    arrange(desc(CohortNormal.t_alt_count)) %>%
    distinct(ETAG,Tumor_Sample_Barcode,.keep_all=T)

maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"PresentInCohortNormal",sep=",")

#
# Clean up the filter reason
#

maf1=maf1 %>% mutate(FILTER.REASON=gsub("^,","",FILTER.REASON))

chromoLevels=paste0("chr",c(1:19,"X","Y","M","MT"))

mafHC=maf1 %>%
    filter(FILTER=="PASS") %>%
    filter(HGVSp!="" & HGVSp!="p.=")

hcMaf=TRUE
if(nrow(mafHC)<1) {
    cat("\n\n  No HC mutations found\n\n")
    mafHC=maf1 %>%
        filter(filter.Targetted=="") %>%
        filter(HGVSp!="" & HGVSp!="p.=")

    hcMaf=FALSE
    if(nrow(mafHC)<1) {
        cat("\n\n No LC mutations found\n\n")
        quit()
    }
}

genesV2=convertGeneSymbolsMouseToHuman(mafHC$Hugo_Symbol)

mafHC=mafHC %>%
    left_join(genesV2,by=c(Hugo_Symbol="MGI.symbol")) %>%
    arrange(factor(Chromosome,levels=chromoLevels),Start_Position) %>%
    select(Hugo_Symbol,HGNC.symbol,
        all_of(2:TCGA.Max.Col),
        matches("^[tn]_.*(count|depth|freq)"),
        matches("FILTER|Cohort"),
        everything()
        ) %>%
    dropEmptyColumns

gTagNames=names(git2r::tags(SDIR))

GITTAG=paste0(
    gTagNames[len(gTagNames)],"-g",
    substr(git2r::commits(SDIR)[[1]]$sha,1,8)
    )

mafHeader=c(mafHeader,
    paste0("## PostProcess-Mouse::makeFinalMaf (v2021.2) [",GITTAG,"]")
    )

write_maf(maf1,paste0(OUTPUT_MAFFILE,".txt"),mafHeader)

degenCols=names(which(apply(maf1,2,function(x){len(unique(x))})==1))

requiredCols=c("Matched_Norm_Sample_Barcode","Tumor_Sample_Barcode")
degenCols=setdiff(degenCols,requiredCols)

hcCols=setdiff(colnames(mafHC),degenCols)

mafHC=mafHC[,hcCols]

params=bind_rows(
    tibble(KEY="PROGRAM",VALUE="makeFinalMAF.R"),
    tibble(KEY="VERSION",VALUE=VERSION),
    tibble(KEY="GIT",VALUE=GITTAG),
    tibble(KEY="DATE",VALUE=DATE()),
    tibble(KEY="INPUT",VALUE=INPUT_MAFFILE),
    tibble(KEY="OUTPUT",VALUE=OUTPUT_MAFFILE),
    tibble(KEY="TUMORS",VALUE=paste(tumors,collapse=",")),
    tibble(KEY="COHORT_NORMALS",VALUE=paste(cohortNormals,collapse=","))
    )

if(hcMaf) {
    
    tbl=list(
        maf_Filter8=mafHC,
        UnFilt_NonSilent=maf1 %>% filter(HGVSp!="" & HGVSp!="p.="),
        cohortNormalFilter=cohorNormalFilteredEvents,
        PARAMS=params
    )

    write.xlsx(tbl,paste0(OUTPUT_MAFFILE,"_HQ.xlsx"))

} else {

    tbl=list(
        lowQual=mafHC,
        UnFilt_NonSilent=maf1 %>% filter(HGVSp!="" & HGVSp!="p.="),
        cohortNormalFilter=cohorNormalFilteredEvents,
        PARAMS=params
    )

    write.xlsx(tbl,paste0(OUTPUT_MAFFILE,"_UnFilt.xlsx"))

}
# mafDebug=mafHC %>% select(1,ETAG,HGVSp,matches("POOL|CTRL|^t_|Cohort|BINOM")) %>%
#     distinct(ETAG,.keep_all=T) %>%
#     arrange(desc(POOL_tVAF))






