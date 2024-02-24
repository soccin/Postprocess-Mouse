args=commandArgs(trailing=T)

if(len(args)<1) {
    cat("\n\tusage: mkManifest.R sample_pairing.txt\n\n")
    quit()
}

try({pairs=readr::read_tsv(args[1],col_names=F)})

if(class(.Last.value)[1]=="try-error") {
    cat("\n\nInvalid pairing file\n","   ",args[1],"\n")
    cat("\n   usage: mkManifest.R sample_pairing.txt\n\n")
    quit()
}

suppressPackageStartupMessages({require(tidyverse)})

normals=unique(pairs$X1)
tumors=setdiff(unique(pairs$X2),normals)

manifest=rbind(tibble(SAMPLE=normals,TYPE="N"),tibble(SAMPLE=tumors,TYPE="T"))
write_csv(manifest,cc("manifest",gsub("Proj_","",gsub("_sample_pairing.txt","",basename(args[1]))),".csv"))
