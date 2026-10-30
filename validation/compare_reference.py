"""Compare independently executed R and Python results; hard failure on missing R outputs."""
import argparse,csv,json,math
from pathlib import Path
import numpy as np
from lmmrr_crosslang.core import compute
from lmmrr_crosslang.fixtures import get_input, read_csv, DATASETS, MODELS

ORDERINGS=('time','marginal_fitted','reverse_time')
VECTOR_TOL=3e-8
FEATURE_TOL=3e-8

def compare(fixtures,ref,out):
    out.mkdir(parents=True,exist_ok=True)
    cases=[]; failures=[]; records=[]
    for dataset in DATASETS:
      for model in MODELS:
       for ordering in ORDERINGS:
        label=f'{dataset}__{model}__{ordering}'
        p=ref/(label+'.csv'); f=ref/(label+'__features.csv')
        if not p.is_file() or not f.is_file():
            failures.append(f'MISSING R REFERENCE: {label}')
            cases.append({'case':label,'status':'BLOCKED','max_abs_diff':None})
            continue
        result=compute(get_input(fixtures,dataset,model,ordering))
        r=read_csv(p)
        if len(r)!=result['n']:
            failures.append('Row count mismatch: '+label)
            cases.append({'case':label,'status':'FAIL','max_abs_diff':None})
            continue
        maxdiff=0.0; nchecks=0
        for j,row in enumerate(r):
            if int(row['row_id'])!=result['row_id'][j] or row['group']!=result['group'][j]:
                failures.append(f'ORDERING MISMATCH {label}, row {j}')
                break
            for k in ('index','innovation','cusum','centered_cusum'):
                expected=float(row[k]); actual=result[k][j]
                err=abs(expected-actual)
                maxdiff=max(maxdiff,err); nchecks+=1
                if not math.isfinite(err) or err>VECTOR_TOL:
                    failures.append(f'{label}/{k}/{j}: abs delta {err:.6g}')
        frows=read_csv(f)
        for z in frows:
            feature=z['name']; exp=float(z['value']); obs=result['features'].get(feature)
            if obs is None:failures.append(f'{label}: missing feature {feature}');continue
            err=abs(exp-obs);maxdiff=max(maxdiff,err);nchecks+=1
            if not math.isfinite(err) or err>FEATURE_TOL:
                failures.append(f'{label}/{feature}: abs delta {err:.6g}')
        status='FAIL' if any(x.startswith(label) or label in x for x in failures) else 'PASS'
        cases.append({'case':label,'status':status,'max_abs_diff':maxdiff,'n_checks':nchecks})
        records.append(result)
    gate='PASS' if len(cases)==12 and all(x['status']=='PASS' for x in cases) else 'FAIL'
    payload={'gate':'MATCHED_NONBOOTSTRAP_PROTOTYPE_'+gate,'scope':
             'R/Python paired Cholesky innovation and indexed accumulation, using same lme4-fitted parameters',
             'published_original_lmmRRdiag_parity':'NOT_TESTED',
             'bootstrap':'EXCLUDED',
             'native_python_publication_claim':'BLOCKED_PENDING_ORIGINAL_SOURCE_PARITY',
             'cases':cases,'failures':failures[:80], 'threshold':VECTOR_TOL}
    (out/'cross_language_results.json').write_text(json.dumps(payload,indent=2))
    with (out/'cross_language_results.csv').open('w',newline='') as h:
        w=csv.DictWriter(h,fieldnames=['case','status','max_abs_diff','n_checks']);w.writeheader();w.writerows(cases)
    print('MATCHED R/PYTHON PROTOTYPE:',gate,'cases',len(cases),'failures',len(failures))
    for x in cases:print(' ',x['case'],x['status'],x['max_abs_diff'])
    return gate=='PASS'

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--fixtures',type=Path,default=Path('fixtures'))
    ap.add_argument('--reference',type=Path,default=Path('results/r_reference'))
    ap.add_argument('--output',type=Path,default=Path('results/parity'))
    a=ap.parse_args();raise SystemExit(0 if compare(a.fixtures,a.reference,a.output) else 2)
