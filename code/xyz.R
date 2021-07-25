source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<1) {
    cat("\n\tusage: xyz.R INPUT.maf [OUTPUT.maf]\n\n")
    quit()
}

suppressPackageStartupMessages(require(tidyverse))

INPUT_MAFFILE=args[1]

if(len(args)==2) {
    OUTPUT_MAFFILE=args[2]
} else {
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}

SDIR=Sys.getenv("SDIR")

source(file.path(SDIR,"tools.R"))
