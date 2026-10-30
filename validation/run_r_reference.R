#!/usr/bin/env Rscript
options(digits=17)
args <- commandArgs(trailingOnly=TRUE)
if (length(args)!=2L) stop('Usage: Rscript validation/run_r_reference.R fixtures output_folder')
source(file.path('R','read_fixtures.R'))
folder <- args[1]; out <- args[2]
dir.create(out,recursive=TRUE,showWarnings=FALSE)
write_one <- function(ds,st,ordering) {
  inp <- rr_fixture_input(folder,ds,st,ordering)
  x <- do.call(rr_nonbootstrap_core,inp)
  id <- paste(ds,st,ordering,sep='__')
  utils::write.csv(data.frame(row_id=x$row_id,group=x$group,index=x$index,
                  innovation=x$innovation,cusum=x$cusum,centered_cusum=x$centered_cusum),
                  file.path(out,paste0(id,'.csv')),row.names=FALSE)
  # Also compare all numeric feature summaries, with no p-value fabrication.
  utils::write.csv(data.frame(name=names(x$features),value=as.numeric(unlist(x$features))),
                    file.path(out,paste0(id,'__features.csv')),row.names=FALSE)
  cat('R exported:',id,' n=',x$n,'\n')
}
for (ds in c('sleepstudy','Orthodont')) for (st in c('RI','RS'))
  for (order in c('time','marginal_fitted','reverse_time')) write_one(ds,st,order)
capture.output(sessionInfo(),file=file.path(out,'R_session_info.txt'))
cat('R REFERENCE FINISHED\n')
