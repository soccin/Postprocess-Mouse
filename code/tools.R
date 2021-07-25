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
        Start_Position,"-",End_Position,":",
        Reference_Allele,":",Tumor_Seq_Allele2
        )
    )
}

.MAF_NUMERIC_COLS=c(
    "Start_Position", "End_Position",
    "t_depth", "t_ref_count", "t_alt_count",
    "n_depth", "n_ref_count", "n_alt_count",
    "t_var_freq", "n_var_freq",
    "DISTANCE"
    )


read_maf<-function(fname) {
    read_tsv(fname,comment="#",col_types = cols(.default = "c")) %>%
        addETAGtoMAF %>%
        mutate_at(.MAF_NUMERIC_COLS,as.numeric)
}

dropEmptyColumns<-function(tbl) {
    allNACols=names(which(apply(tbl,2,function(x){all(is.na(x))})))
    select(tbl,-all_of(allNACols))
}

write_maf<-function(maf,mafFile,mafHeader=NULL) {
    if(!is.null(mafHeader)) {
        write(mafHeader,mafFile)
    }
    write_tsv(maf,mafFile,na="",append=!is.null(mafHeader),col_names=T)
}
