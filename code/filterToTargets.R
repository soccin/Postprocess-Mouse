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

TARGETS=args[1]
INPUT_MAFFILE=args[2]

if(len(args)==3) {
    OUTPUT_MAFFILE=args[3]
} else {
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}

SDIR=Sys.getenv("SDIR")

source(file.path(SDIR,"tools.R"))

bed4Cols=cols(
  chr = col_character(),
  start = col_double(),
  end = col_double(),
  DAT = col_character()
)

targets=read_tsv(TARGETS,col_names=c("chr","start","end","DAT"),col_types=bed4Cols)

mafHeader=getMAFHeader(INPUT_MAFFILE)
maf=read_tsv(INPUT_MAFFILE,comment="#",col_types = cols(.default = "c"))

halt()

 # %>%



 #    mutate(ETAG=paste0(
 #        Chromosome,":",
 #        Start_Position,"-",End_Position,":",
 #        Reference_Allele,":",Tumor_Seq_Allele2
 #        )
 #    )



maf.events=maf %>% select(chr=Chromosome,start=Start_Position,end=End_Position,ETAG) %>%
    mutate(start=as.numeric(start),end=as.numeric(end)) %>%
    distinct


events_targetted=genome_intersect(maf.events,targets) %>% filter(!grepl("^rs\\d+",DAT))

maf.filt=maf %>% filter(ETAG %in% events_targetted$ETAG)
