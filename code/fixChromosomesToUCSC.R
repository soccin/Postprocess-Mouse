#!/opt/common/CentOS_7/R/R-3.6.1/bin/Rscript --no-save --vanilla

suppressPackageStartupMessages(require(stringr, warn.conflicts = F))

###############################################################################
len<-function(x){length(x)}

getMAFHeader<-function(fname){

    header=readLines(fname,100)
    colNameRow=grep("^Hugo_Symbol",header)
    if(len(colNameRow)==0){
        cat("\n\nFATAL ERROR: INVALID MAF HEADER\n\n")
        stop("fixChromosomesToUCSC.R::L-14")
    }

    return(header[1:(colNameRow-1)])

}

###############################################################################

cArgs=commandArgs(trailing=T)

#
# This code will parse command line args in the form of
#    KEY=VAL
# and sets
#    args[[KEY]]=VAL
#

# Set defaults first

args=list(IN=NULL,RevisionTAG="unknown",OUT=NULL)
parseArgs=str_match(cArgs,"(.*)=(.*)")
dummy=apply(parseArgs,1,function(x){args[[str_trim(x[2])]]<<-str_trim(x[3])})

if(is.null(args$IN)) {
    cat("\n\tusage: fixChromosomesToUCSC.R IN=input.maf [OUT=output.maf]\n")
    cat("\t  default OUT=input_PPv5.txt\n\n")
    quit()
}

suppressPackageStartupMessages(library(data.table, warn.conflicts = F))
suppressPackageStartupMessages(library(readr, warn.conflicts = F))

mafHeader=getMAFHeader(args$IN)

maf=data.table(
    read_tsv(
        args$IN,
        comment="#",
        col_types=list(Chromosome=col_character(),PUBMED=col_character())
        )
    )

if(is.null(args$OUT)) {
    OUTMAFFILE=gsub("(.maf|.txt)$","_PPv5.txt",args$IN)
} else {
    OUTMAFFILE=args$OUT
}

maf[,Chromosome:=paste0("chr",Chromosome)]
maf$NCBI_Build="mm10"

getSDIR<-function() {
    SDIR=grep("--file=",commandArgs(),value=T)
    SDIR=gsub(".*file=","",SDIR)
    normalizePath(dirname(SDIR))
}

source(file.path(getSDIR(),"VERSION.R"))

mafHeader=c(mafHeader,paste0("## PostProcess-Mouse::fixChromosomeToUCSC (",VERSION,")"))

write(mafHeader,OUTMAFFILE)

write_tsv(maf,OUTMAFFILE,na="",append=T,col_names=T)

