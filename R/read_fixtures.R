source(file.path("R","rr_core.R"))
rr_fixture_input <- function(folder, dataset, structure, ordering="time") {
  stopifnot(dataset %in% c("sleepstudy","Orthodont"),structure %in% c("RI","RS"))
  d <- read.csv(file.path(folder,paste0(dataset,".csv")),stringsAsFactors=FALSE,
                colClasses=c(group="character"))
  m <- read.csv(file.path(folder,"r_metrics.csv"),stringsAsFactors=FALSE)
  m <- m[m$model==paste(dataset,structure,sep="__"),]
  value <- function(metric,name) {
    z <- m$value[m$metric==metric & m$name==name]
    if (length(z)!=1L) stop("Missing metric: ",metric, " ",name)
    as.numeric(z)
  }
  n <- nrow(d)
  if (dataset=="sleepstudy") {
    X <- cbind(Intercept=rep(1,n),x=d$x)
    nm <- c("Intercept","x"); xn <- d$x
    zn <- if(structure=="RI") "Intercept" else c("Intercept","x")
    Z <- X[,zn,drop=FALSE]
  } else {
    X <- cbind(Intercept=rep(1,n),age_c=d$age_c,Female=d$Female,
               `age_c:Female`=d$age_c*d$Female)
    nm <- colnames(X); xn <- d$age_c
    zn <- if(structure=="RI") "Intercept" else c("Intercept","age_c")
    Z <- X[,zn,drop=FALSE]
  }
  beta <- vapply(nm,function(z)value("fixed",z),0.0)
  D <- matrix(0,length(zn),length(zn),dimnames=list(zn,zn))
  for (j in seq_along(zn)) for(k in seq_along(zn)) {
    n1 <- paste(zn[j],zn[k],sep="|")
    n2 <- paste(zn[k],zn[j],sep="|")
    nam <- if(any(m$metric=="random_cov" & m$name==n1)) n1 else n2
    D[j,k] <- value("random_cov",nam)
  }
  index <- switch(ordering,time=xn,marginal_fitted=as.vector(X%*%beta),reverse_time=-xn,
                  stop("Unknown ordering"))
  list(y=d$y,X=X,beta=beta,Z=Z,D=D,
       sigma2=value("sigma2","residual"),group=d$group,
       index=index,row_id=d$row_id)
}
