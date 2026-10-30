# Non-bootstrap cross-language reference core; DOES NOT implement paper-specific
# calibration and is not asserted to be identical to the published lmmRRdiag source.
rr_nonbootstrap_core <- function(y, X, beta, Z, D, sigma2, group, index, row_id) {
  y <- as.numeric(y); X <- as.matrix(X); beta <- as.numeric(beta)
  Z <- as.matrix(Z); D <- as.matrix(D); index <- as.numeric(index)
  group <- as.character(group); row_id <- as.integer(row_id)
  n <- length(y)
  if (n < 4L || nrow(X)!=n || ncol(X)!=length(beta) || nrow(Z)!=n ||
      nrow(D)!=ncol(Z) || ncol(D)!=ncol(Z) ||
      length(group)!=n || length(index)!=n || length(row_id)!=n ||
      anyDuplicated(row_id) || anyNA(group) || any(group=="") ||
      any(!is.finite(c(y,X,beta,Z,D,index))) ||
      length(sigma2)!=1 || !is.finite(sigma2) || sigma2<=0)
    stop("Invalid model input/dimensions")
  if (max(abs(D-t(D)))>1e-10) stop("D must be symmetric")
  if (min(eigen(D,symmetric=TRUE,only.values=TRUE)$values)< -1e-10)
    stop("D must be positive semidefinite")
  innov <- numeric(n)
  cluster <- list()
  for (g in sort(unique(group),method="radix")) {
    ix <- which(group==g)
    ix <- ix[order(index[ix],row_id[ix],method="radix")]
    Zi <- Z[ix,,drop=FALSE]
    V <- Zi %*% D %*% t(Zi) + diag(sigma2,length(ix))
    # chol returns upper triangular R, R' R = V.
    L <- t(chol(V))
    innov[ix] <- as.vector(forwardsolve(L,y[ix]-X[ix,,drop=FALSE]%*%beta))
    cluster[[g]] <- list(n=length(ix),max_abs_innovation=max(abs(innov[ix])))
  }
  ord <- order(index,group,row_id,method="radix")
  s <- innov[ord]; k <- seq_len(n)
  cu <- cumsum(s)/sqrt(n)
  ce <- (cumsum(s)-(k/n)*sum(s))/sqrt(n)
  peak <- which.max(abs(ce))
  list(schema="nonbootstrap-core-0.1",n=n,groups=length(cluster),
       row_id=row_id[ord], group=group[ord],index=index[ord],
       innovation=s,cusum=cu,centered_cusum=ce,
       features=list(max_abs_innovation=max(abs(s)),
                     n_abs_innovation_ge_3=sum(abs(s)>=3),
                     frac_abs_innovation_ge_3=mean(abs(s)>=3),
                     max_abs_cusum=max(abs(cu)),
                     max_abs_centered_cusum=max(abs(ce)),
                     centered_peak_index=index[ord][peak],
                     mean_innovation=mean(s),sd_innovation=stats::sd(s),
                     terminal_cusum=cu[n]),
       per_cluster=cluster,
       inference=list(calibrated=FALSE,p_value=NULL,envelope=NULL,
                      global_alarm="NOT_AVAILABLE"))
}
