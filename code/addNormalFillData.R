if(!interactive()) source("~/.Rprofile")
args=commandArgs(trailing=T)
if(len(args)<2) {
    cat("\n\tusage: addNormalFillData.R INPUT.maf FILLOUT.out [OUTPUT.maf]\n\n")
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

if(len(args)==3) {
    OUTPUT_MAFFILE=args[3]
} else {
    OUTPUT_MAFFILE=cc(basename(INPUT_MAFFILE),"FilterToTargets.txt")
}

FILLOUTFILE=args[2]

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

################################################################################
# Get fillout for
################################################################################

fillout=read_GBMCFillOut(FILLOUTFILE,mtags)

ff.samp=fillout %>%
    filter(grepl("^ctrl\\.samp\\.",Sample)) %>%
    select(ETAG,Sample,Field,Value) %>%
    filter(Field %in% c("DP","AD","VF")) %>%
    spread(Field,Value) %>%
    mutate(VF=ifelse(DP<10,-1,VF)) %>%
    group_by(ETAG) %>%
    summarize(maxVF=max(VF,na.rm=T),tAD=sum(AD),tDP=sum(DP)) %>% mutate(tVAF=tAD/tDP) %>%
    filter(maxVF>=0) %>%
    rename_at(-1,~cc("Normal_CTRLS",.))

ff.pool=fillout %>%
    filter(grepl("^ctrl\\.pool\\.",Sample)) %>%
    select(ETAG,Sample,Field,Value) %>%
    filter(Field %in% c("DP","AD","VF")) %>%
    spread(Field,Value) %>%
    mutate(VF=ifelse(DP<10,-1,VF)) %>%
    group_by(ETAG) %>%
    summarize(maxVF=max(VF,na.rm=T),tAD=sum(AD),tDP=sum(DP)) %>% mutate(tVAF=tAD/tDP) %>%
    filter(maxVF>=0) %>%
    rename_at(-1,~cc("POOL",.))

omaf=left_join(maf,ff.samp,by="ETAG") %>% left_join(ff.pool,by="ETAG")

mafHeader=c(mafHeader,"## PostProcess-Mouse::addNormalFillData (v2021.1)")
write_maf(omaf,OUTPUT_MAFFILE,mafHeader)

#-10*pbinom(VAF=0.106,2,CTRLS_tVAF=0.00175,lower.tail=F,log=T)






