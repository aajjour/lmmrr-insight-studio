"""Reference R lme4 REML fitted parameters, with no refitting in this step."""
import csv
from pathlib import Path
import numpy as np
from .core import Input

DATASETS=('sleepstudy','Orthodont')
MODELS=('RI','RS')

def read_csv(p):
    with Path(p).open(newline='',encoding='utf-8-sig') as f:
        return list(csv.DictReader(f))

def get_input(folder,dataset,structure,ordering='time'):
    if dataset not in DATASETS or structure not in MODELS:
        raise ValueError('Unsupported fixture model')
    folder=Path(folder)
    data=read_csv(folder/(dataset+'.csv'))
    rows=read_csv(folder/'r_metrics.csv')
    m=dataset+'__'+structure
    vals={(r['metric'],r['name']):float(r['value']) for r in rows if r['model']==m}
    n=len(data)
    x=np.asarray([float(r['x']) for r in data])
    if dataset=='sleepstudy':
        names=['Intercept','x']; X=np.column_stack([np.ones(n),x]); candidate=x
        znames=['Intercept'] if structure=='RI' else ['Intercept','x']
        Z=X[:,:len(znames)]
    else:
        age=np.asarray([float(r['age_c']) for r in data])
        female=np.asarray([float(r['Female']) for r in data])
        names=['Intercept','age_c','Female','age_c:Female']
        X=np.column_stack([np.ones(n),age,female,age*female])
        candidate=age
        znames=['Intercept'] if structure=='RI' else ['Intercept','age_c']
        Z=X[:,:1] if structure=='RI' else X[:,:2]
    beta=np.asarray([vals['fixed',nm] for nm in names])
    D=np.zeros((len(znames),len(znames)))
    for j,nj in enumerate(znames):
        for k,nk in enumerate(znames):
            key=('random_cov',f'{nj}|{nk}')
            if key not in vals:key=('random_cov',f'{nk}|{nj}')
            D[j,k]=vals[key]
    idx={'time':candidate,'marginal_fitted':X@beta,'reverse_time':-candidate}.get(ordering)
    if idx is None:raise ValueError('Unknown ordering')
    return Input(y=np.asarray([float(r['y']) for r in data]),X=X,beta=beta,
        Z=Z,D=D,sigma2=vals[('sigma2','residual')],
        group=np.asarray([r['group'] for r in data]),index=idx,
        row_id=np.asarray([int(r['row_id']) for r in data]))
