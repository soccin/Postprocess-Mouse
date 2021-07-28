convertGeneSymbolsMouseToHuman <- function(mgg) {

    human = useMart("ensembl", dataset = "hsapiens_gene_ensembl")
    mouse = useMart("ensembl", dataset = "mmusculus_gene_ensembl")

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

if(!interactive()) source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<1) {
    cat("\n\tusage: addNormalFillData.R INPUT.maf [OUTPUT_BASE]\n\n")
    quit()
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
# Parse args
################################################################################

# Read config file

config=read_postConfig()

INPUT_MAFFILE=args[1]

if(len(args)==2) {
    OUTPUT_MAFFILE=args[2]
} else {
    OUTPUT_MAFFILE=cc("Proj",config$projectNo,"VEP_MAF_","PostV6a")
}

tumors=get_TumorSampleIDs(config$PIPELINEDIR)

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

maf1=maf %>%
    filter(Tumor_Sample_Barcode %in% tumors) %>%
    left_join(cohort.stats) %>%
    mutate_at(numeric.cols,as.numeric) %>%
    mutate(FILTER="PASS",FILTER.REASON="") %>%
    mutate(BINOM.pv=pbinom(t_var_freq,2,(POOL_tAD+1)/(POOL_tDP+1),lower=F)) %>%
    mutate(BINOM.or=BINOM.pv/(1-BINOM.pv)) %>%
    mutate(tVafFreqP=(t_alt_count+1)/(t_depth+2)) %>%
    mutate(BINOM.lor=log10((tVafFreqP/(1-tVafFreqP))/BINOM.or)) %>%
    mutate(BINOM.Q=-10*log10(BINOM.pv))

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

ii.f=which(!(maf1$BINOM.lor>log10(10) & maf1$BINOM.fdr<.2))
maf1$FILTER[ii.f]="REMOVE"
maf1$FILTER.REASON[ii.f]=paste(maf1$FILTER.REASON[ii.f],"PresentInPool",sep=",")

maf1=maf1 %>% mutate(FILTER.REASON=gsub("^,","",FILTER.REASON))

chromoLevels=paste0("chr",c(1:19,"X","Y","M","MT"))

mafHC=maf1 %>%
    filter(FILTER=="PASS") %>%
    filter(HGVSp!="" & HGVSp!="p.=")

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
    paste0("## PostProcess-Mouse::makeFinalMaf (v2021.1) [",GITTAG,"]")
    )

write_maf(maf1,paste0(OUTPUT_MAFFILE,".txt"),mafHeader)

mafHC=mafHC[,setdiff(colnames(mafHC),names(which(apply(maf1,2,function(x){len(unique(x))})==1)))]

params=bind_rows(
    tibble(KEY="PROGRAM",VALUE="makeFinalMAF.R"),
    tibble(KEY="VERSION",VALUE=VERSION),
    tibble(KEY="GIT",VALUE=GITTAG),
    tibble(KEY="DATE",VALUE=DATE()),
    tibble(KEY="INPUT",VALUE=INPUT_MAFFILE),
    tibble(KEY="OUTPUT",VALUE=OUTPUT_MAFFILE))

tbl=list(
    maf_Filter8=mafHC,
    maf_UnFiltered=maf1 %>% filter(HGVSp!="" & HGVSp!="p.="),
    PARAMS=params
    )

write.xlsx(tbl,paste0(OUTPUT_MAFFILE,"_HQ.xlsx"))

# mafDebug=mafHC %>% select(1,ETAG,HGVSp,matches("POOL|CTRL|^t_|Cohort|BINOM")) %>%
#     distinct(ETAG,.keep_all=T) %>%
#     arrange(desc(POOL_tVAF))






