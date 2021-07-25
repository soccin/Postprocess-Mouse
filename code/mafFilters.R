addETAGtoMAF <- function(maf) {
     mutate(maf,ETAG=paste0(
        Chromosome,":",
        Start_Position,"-",End_Position,":",
        Reference_Allele,":",Tumor_Seq_Allele2
        )
    )
}