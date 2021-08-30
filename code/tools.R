suppressPackageStartupMessages({
    require(fs)
    require(readr)
})

read_postConfig<-function() {
    config=list()
    xx=readLines("../config")
    parseConfig=str_match(xx,"(.*)=(.*)")
    for(ii in seq(nrow(parseConfig))) {
        config[[parseConfig[ii,2]]]=parseConfig[ii,3]
    }
    config
}


get_TumorSampleIDs<-function(pipeLineDir) {
    pairFile=dir_ls(pipeLineDir,regex="_sample_pairing.txt")
    samps=read_tsv(pairFile,col_names=c("Normal","Tumor"),col_types = cols(.default = "c"))
    tumors=setdiff(samps$Tumor,samps$Normal)
    tumors
}

#' get_CohortNormalIDs
#'
#' The cohort normals are the matched normals from the project.
#' They are both paired with their matched tumor and are also
#' paired against the normal pool to look for potential artifacts
#' and strain/germlin events
#'
#' @param pipeLineDir path to pipeline output directory
#' @return list of normal sample IDs
#'
get_CohortNormalIDs<-function(pipeLineDir) {
    pairFile=dir_ls(pipeLineDir,regex="_sample_pairing.txt")
    samps=read_tsv(pairFile,col_names=c("Normal","Tumor"),col_types = cols(.default = "c"))
    #
    # The cohort normals show up as both normals and tumors
    # e.g.:
    #      NormA        TumorA
    #      PooledNormal NormA
    #
    normals=intersect(samps$Tumor,samps$Normal)

    pairedAgainstPool=unique(samps$Tumor[grep("POOL.*NORM",samps$Normal)])
    if(len(normals)!=len(pairedAgainstPool)) {

        tumors=samps %>% filter(!grepl("POOLED",Normal)) %>% pull(Tumor)
        normals=samps %>% filter(Tumor %in% tumors) %>% distinct(Normal) %>% pull(Normal)
        manifest=
            tibble(SAMPLE=unique(c(samps$Normal,samps$Tumor)),TYPE="") %>%
            mutate(TYPE=case_when(
                                    SAMPLE %in% tumors ~ "T",
                                    SAMPLE %in% normals ~ "N",
                                    grepl("POOLED",SAMPLE) ~ "P",
                                    T ~ "x"
                                ))

        write_csv(manifest,"_sample_manifest.csv")

        cat("\n\n    FATAL ERROR: Detection of Normal Samples Failed\n\n")
        cat("        normals  =",paste0(normals,collapse=", "),"\n")
        cat("        normals2 =",paste0(pairedAgainstPool,collapse=", "),"\n")
        cat("\n")
        cat("\n    Need to specify explict manifest file to indicate tumors/normals\n\n")
        stop("FATAL:ERROR:tools:get_CohortNormalIDs")

    }

    normals
}


read_mafHeader<-function(fname){

    header=readLines(fname,100)
    colNameRow=grep("^Hugo_Symbol",header)
    if(len(colNameRow)==0){
        cat("\n\nFATAL ERROR: INVALID MAF HEADER\n\n")
        stop("collapseNormalizedMAF.R::L-14")
    }

    return(header[1:(colNameRow-1)])

}

addETAGtoMAF <- function(maf) {
     mutate(maf,ETAG=paste0(
        Chromosome,":",
        Start_Position,":",
        Reference_Allele,":",Tumor_Seq_Allele2
        )
    )
}

.MAF_NUMERIC_COLS=c(
    "Start_Position", "End_Position",
    "t_depth", "t_ref_count", "t_alt_count",
    "n_depth", "n_ref_count", "n_alt_count",
    "t_var_freq", "n_var_freq"
    )


read_maf<-function(fname) {
    read_tsv(fname,comment="#",col_types = cols(.default = "c"),na=character()) %>%
        addETAGtoMAF %>%
        mutate_at(.MAF_NUMERIC_COLS,as.numeric)
}

write_maf<-function(maf,mafFile,mafHeader=NULL) {
    if(!is.null(mafHeader)) {
        write(mafHeader,mafFile)
    }
    maf=maf %>% mutate_if(is.character,~replace(., .=="", NA))
    write_tsv(maf,mafFile,na="",append=!is.null(mafHeader),col_names=T)
}

TCGA.Max.Col=34
dropEmptyColumns<-function(tbl) {
    allEmptyCols=which(apply(tbl,2,function(x){all(x=="" | is.na(x))}))
    #
    # Do not remove TCGA cols (1-34)
    allEmptyCols=names(which(allEmptyCols>TCGA.Max.Col))
    select(tbl,-all_of(allEmptyCols))
}


addETAGtoGBMCFillOut<-function(fout) {
    fout %>%
        select(Chrom,Start,Ref,Alt) %>%
        mutate(isDel=nchar(Ref)>1,isIns=nchar(Alt)>1) %>%
        mutate(RefN=case_when(isDel ~ substr(Ref,2,nchar(Ref)), isIns ~ "-", T ~ Ref)) %>%
        mutate(AltN=case_when(isDel ~ "-", isIns ~ substr(Alt,2,nchar(Alt)), T ~ Alt)) %>%
        mutate(StartN=ifelse(isDel,Start+1,Start)) %>%
        mutate(ETAG=paste0(Chrom,":",StartN,":",RefN,":",AltN)) %>%
        select(Chrom,Start,Ref,Alt,ETAG)
}

read_GBMCFillOut<-function(fillFile,eTags=NULL) {

    fout=read_tsv(fillFile,col_types=cols(.default = "c"),na=character()) %>%
        mutate(Start=as.numeric(Start))

    firstDataCol=(grep("Occurence_in_Normals",colnames(fout))+1)
    dataCols=colnames(fout)[firstDataCol:ncol(fout)]
    fout=select(fout,Chrom,Start,Ref,Alt,all_of(dataCols))

    fout=left_join(fout,addETAGtoGBMCFillOut(fout),by = c("Chrom", "Start", "Ref", "Alt"))

    if(!is.null(eTags)) {
        fout=fout %>% filter(ETAG %in% eTags)
    }

    fout %>%
        gather(Sample,Value,all_of(dataCols)) %>%
        separate_rows(Value,sep=";") %>%
        separate(Value,c("Field","Value"),sep="=") %>%
        mutate(Value=as.numeric(Value))

}

