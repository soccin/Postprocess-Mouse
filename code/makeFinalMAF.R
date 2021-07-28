if(!interactive()) source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<2) {
    cat("\n\tusage: addNormalFillData.R INPUT.maf [OUTPUT_BASE]\n\n")
    quit()
}

suppressPackageStartupMessages({
    require(tidyverse)
    require(tidygenomics)
    })

SDIR=Sys.getenv("SDIR")

source(file.path(SDIR,"tools.R"))
source(file.path(SDIR,"mafFilters.R"))
source(file.path(SDIR,"VERSION.R"))

################################################################################
# Parse args
################################################################################


INPUT_MAFFILE=args[1]

if(len(args)==2) {
    OUTPUT_MAFFILE=args[2]
} else {
    halt("DDDD")
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}

################################################################################
# Read MAF
################################################################################

mafHeader=read_mafHeader(INPUT_MAFFILE)
maf=read_maf(INPUT_MAFFILE)

if("filter.Targetted" %in% colnames(maf)) {
    mtags=maf %>% filter(filter.Targetted=="") %>% distinct(ETAG) %>% pull(ETAG)
} else {
    mtags=NULL
}

#mafHeader=c(mafHeader,"## PostProcess-Mouse::makeFinalMaf (v2021.1)")
#write_maf(omaf,OUTPUT_MAFFILE,mafHeader)

#-10*pbinom(VAF=0.106,2,CTRLS_tVAF=0.00175,lower.tail=F,log=T)






