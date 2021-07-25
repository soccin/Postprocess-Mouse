
filter.TargettedEvents<-function(maf,targets) {

    maf.events=maf %>% select(chr=Chromosome,start=Start_Position,end=End_Position,ETAG) %>%
        mutate(start=as.numeric(start),end=as.numeric(end)) %>%
        distinct

    events_targetted=genome_intersect(maf.events,targets,by = c("chr", "start", "end")) %>% filter(!grepl("^rs\\d+",DAT))

    maf %>%
        mutate(filter.Targetted=ifelse(ETAG %in% events_targetted$ETAG,"",paste0("NotTargetted::",TARGET_TAG))) %>%
        mutate(TargetPanel=ifelse(ETAG %in% events_targetted$ETAG,TARGET_TAG,""))

}

