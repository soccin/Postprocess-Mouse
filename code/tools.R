getMAFHeader<-function(fname){

    header=readLines(fname,100)
    colNameRow=grep("^Hugo_Symbol",header)
    if(len(colNameRow)==0){
        cat("\n\nFATAL ERROR: INVALID MAF HEADER\n\n")
        stop("collapseNormalizedMAF.R::L-14")
    }

    return(header[1:(colNameRow-1)])

}
