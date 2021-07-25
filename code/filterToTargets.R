if(!interactive()) source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<2) {
    cat("\n\tusage: filterToTargets.R TARGETS.BED INPUT.maf [OUTPUT.maf]\n\n")
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

TARGETS=args[1]

if(grepl(":",TARGETS)) {
    TARGET_TAG=strsplit(TARGETS,":")[[1]][1]
    TARGETS=strsplit(TARGETS,":")[[1]][2]
} else {
    TARGET_TAG=gsub("_targets.*","",basename(TARGETS))
}

INPUT_MAFFILE=args[2]

if(len(args)==3) {
    OUTPUT_MAFFILE=args[3]
} else {
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}


################################################################################
# Get target regions
################################################################################

bed4Cols=cols(
  chr = col_character(),
  start = col_double(),
  end = col_double(),
  DAT = col_character()
)

targets=read_tsv(TARGETS,col_names=c("chr","start","end","DAT"),col_types=bed4Cols)

################################################################################
# Process MAF
################################################################################

mafHeader=read_mafHeader(INPUT_MAFFILE)
maf=read_maf(INPUT_MAFFILE)

maf.f=filter.TargettedEvents(maf,targets) %>% dropEmptyColumns

mafHeader=c(mafHeader,"## PostProcess-Mouse::filterToTargets (v2021.1) targets:M-IMPACT_v1_mm10")

write_maf(maf.f,OUTPUT_MAFFILE,mafHeader)


