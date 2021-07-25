source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<2) {
    cat("\n\tusage: filterToTargets.R TARGETS.BED INPUT.maf [OUTPUT.maf]\n\n")
    quit()
}

suppressPackageStartupMessages(require(tidyverse))

TARGETS=args[1]
INPUT_MAFFILE=args[2]

if(len(args)==3) {
    OUTPUT_MAFFILE=args[3]
} else {
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}

SDIR=Sys.getenv("SDIR")

#source("tools.R")
