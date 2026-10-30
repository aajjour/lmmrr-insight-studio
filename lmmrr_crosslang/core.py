"""Cross-language, non-bootstrap LMM innovation and indexed-process core.

This is a *transparent mathematical prototype*, NOT an independently certified
port of the published lmmRRdiag implementation. It uses externally fitted
fixed effects and covariance parameters: the marginal innovation vector is
L_i^-1 (y_i-X_i beta), L_i L_i'=Z_i D Z_i'+sigma^2 I. Indexed process
order and normalization are explicitly declared; inferential p-values and
critical envelopes are deliberately absent.
"""
from dataclasses import dataclass
from typing import Any
import numpy as np

SCHEMA_VERSION = 'nonbootstrap-core-0.1'

@dataclass(frozen=True)
class Input:
    y: np.ndarray
    X: np.ndarray
    beta: np.ndarray
    Z: np.ndarray
    D: np.ndarray
    sigma2: float
    group: np.ndarray
    index: np.ndarray
    row_id: np.ndarray


def _validate(v: Input):
    y=np.asarray(v.y,dtype=float).reshape(-1)
    X=np.asarray(v.X,dtype=float); b=np.asarray(v.beta,dtype=float).reshape(-1)
    Z=np.asarray(v.Z,dtype=float); D=np.asarray(v.D,dtype=float)
    groups=np.asarray(v.group).astype(str)
    index=np.asarray(v.index,dtype=float).reshape(-1)
    row=np.asarray(v.row_id,dtype=int).reshape(-1)
    n=y.size
    if n<4 or X.ndim!=2 or Z.ndim!=2 or D.ndim!=2:
        raise ValueError('Requires n >= 4 and two-dimensional design/covariance matrices')
    if X.shape!=(n,b.size) or Z.shape[0]!=n or D.shape!=(Z.shape[1],Z.shape[1]):
        raise ValueError('Matrix dimensions do not agree')
    if n!=len(groups) or n!=len(index) or n!=len(row) or len(set(row.tolist()))!=n:
        raise ValueError('IDs, groups, or indices invalid')
    if np.any(groups=='') or not all(np.isfinite(x).all() for x in (y,X,b,Z,D,index)):
        raise ValueError('Nonfinite numeric value or missing group')
    if not np.isfinite(v.sigma2) or v.sigma2<=0:
        raise ValueError('sigma2 must be positive')
    if not np.allclose(D,D.T,atol=1e-10,rtol=1e-10):
        raise ValueError('D must be symmetric')
    try: np.linalg.cholesky(D + 1e-14*np.eye(D.shape[0]))
    except np.linalg.LinAlgError: raise ValueError('D must be positive semidefinite') from None
    return y,X,b,Z,D,groups,index,row


def compute(v:Input) -> dict[str,Any]:
    """Independent cluster whitening followed by globally indexed accumulation.

    Ties: ordered by group string and unique row ID, after the scientific index.
    Centered CUSUM is a descriptive transform, not a Brownian-bridge test.
    """
    y,X,b,Z,D,g,index,row=_validate(v)
    n=y.size; innovations=np.empty(n)
    per_cluster={}
    for label in sorted(set(g.tolist())):
        ix=np.flatnonzero(g==label)
        ix=ix[np.lexsort((row[ix], index[ix]))]
        Zi=Z[ix]; Vi=Zi@D@Zi.T+float(v.sigma2)*np.eye(len(ix))
        L=np.linalg.cholesky(Vi)
        innovations[ix]=np.linalg.solve(L,y[ix]-X[ix]@b)
        per_cluster[label]={'n':len(ix),'max_abs_innovation':float(np.max(np.abs(innovations[ix])))}
    order=np.lexsort((row,g,index))
    s=innovations[order]; k=np.arange(1,n+1,dtype=float)
    cusum=np.cumsum(s)/np.sqrt(n)
    centered=(np.cumsum(s) - k/n*np.sum(s))/np.sqrt(n)
    hit=np.flatnonzero(np.abs(s)>=3.0)
    peak=int(np.argmax(np.abs(centered)))
    return dict(
        schema=SCHEMA_VERSION,n=n,groups=len(per_cluster),
        row_id=row[order].astype(int).tolist(),group=g[order].tolist(),index=index[order].tolist(),
        innovation=s.tolist(),cusum=cusum.tolist(),centered_cusum=centered.tolist(),
        features={'max_abs_innovation':float(np.max(np.abs(s))),
                  'n_abs_innovation_ge_3':int(len(hit)),
                  'frac_abs_innovation_ge_3':float(len(hit)/n),
                  'max_abs_cusum':float(np.max(np.abs(cusum))),
                  'max_abs_centered_cusum':float(np.max(np.abs(centered))),
                  'centered_peak_index':float(index[order][peak]),
                  'mean_innovation':float(s.mean()),
                  'sd_innovation':float(s.std(ddof=1)),
                  'terminal_cusum':float(cusum[-1])},
        per_cluster=per_cluster,
        inference={'calibrated':False, 'p_value':None, 'envelope':None,
                   'global_alarm':'NOT_AVAILABLE',
                   'warning':'Descriptive only. No bootstrap, calibrated p-value or validated misspecification type.'})
