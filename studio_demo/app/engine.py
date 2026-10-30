"""Auditable presentation layer for externally calibrated indexed RR processes.
No residuals or p-values are estimated from fitted LMMs here.
"""
import csv
import html
import json
import math
import statistics
from collections import defaultdict
from pathlib import Path

TRACE_COLUMNS = ('model','process','index','observed','lower','upper')
EVIDENCE_COLUMNS = ('model','process','p_value','calibration','scope','b_refits','origin','family_id','family_size','demo_signal')
PROCESS_INFO = {
    'mean_indexed': ('Indexed mean process', 'Mean specification / functional form', 'Inspect nonlinear or omitted fixed effects and scientifically meaningful orderings.'),
    'cluster_indexed': ('Cluster-indexed process', 'Grouping / between-cluster structure', 'Inspect grouping labels, cluster influence, omitted cluster-level covariates.'),
    'blup_indexed': ('BLUP-indexed process', 'Random-effect structure', 'Compare defensible random-intercept / random-slope specifications, inspect BLUP structure.'),
    'serial_indexed': ('Serial-order process', 'Within-cluster dependence', 'Examine within-cluster autocorrelation; evaluate an appropriate covariance structure.'),
    'scale_indexed': ('Scale-indexed process', 'Variance heterogeneity', 'Inspect residual scale by fitted values and groups; evaluate variance structures.'),
}

def _float(x, what):
    try:
        z = float(x)
    except (TypeError, ValueError):
        raise ValueError(f'Expected numeric {what}: {x!r}') from None
    if not math.isfinite(z):
        raise ValueError(f'Nonfinite {what}')
    return z

def _read(path, required):
    with open(path, newline='', encoding='utf-8-sig') as fh:
        reader = csv.DictReader(fh)
        if reader.fieldnames is None or not set(required).issubset(reader.fieldnames):
            raise ValueError(f'{path.name}: required columns are {required}')
        rows = list(reader)
    if not rows:
        raise ValueError(f'{path.name} is empty')
    return rows

def _holm(pvalues):
    """Holm step-down adjusted p values, same original item order."""
    n = len(pvalues)
    order = sorted(range(n), key=lambda i: pvalues[i])
    out = [0.0] * n
    last = 0.
    for rank, i in enumerate(order):
        last = max(last, (n - rank) * pvalues[i])
        out[i] = min(1., last)
    return out

def analyze(folder):
    folder = Path(folder)
    trace = _read(folder/'traces.csv', TRACE_COLUMNS)
    meta = _read(folder/'evidence.csv', EVIDENCE_COLUMNS)
    paths = defaultdict(list)
    for line_num, r in enumerate(trace, 2):
        model = (r['model'] or '').strip()
        proc = (r['process'] or '').strip()
        if not model or not proc or len(model)>150 or len(proc)>150:
            raise ValueError(f'Invalid model/process on traces.csv line {line_num}')
        idx = _float(r['index'], 'index')
        o = _float(r['observed'], 'observed')
        lo = _float(r['lower'], 'lower')
        hi = _float(r['upper'], 'upper')
        if not lo < hi:
            raise ValueError(f'Invalid envelope on traces.csv line {line_num}')
        paths[(model,proc)].append({'index':idx, 'observed':o, 'lower':lo, 'upper':hi})
    for key, points in paths.items():
        indices = [p['index'] for p in points]
        if len(points) < 20 or any(b<=a for a,b in zip(indices,indices[1:])):
            raise ValueError(f'{key}: minimum 20 rows and strictly increasing index required')
    lookup = {}
    for r in meta:
        key = (r['model'].strip(), r['process'].strip())
        if key in lookup: raise ValueError(f'Duplicate evidence row: {key}')
        lookup[key] = r
    if set(lookup) != set(paths):
        raise ValueError(f'Evidence keys must exactly match traces. Missing {set(paths)-set(lookup)}; unexpected {set(lookup)-set(paths)}')
    prepared = []
    for key, pts in paths.items():
        m = lookup[key]
        pval = m['p_value'].strip()
        pval = None if pval == '' else _float(pval, 'p_value')
        if pval is not None and not (0 < pval <= 1):
            raise ValueError(f'{key}: p_value must be in (0,1]')
        bstr = m['b_refits'].strip()
        if not bstr.isdigit(): raise ValueError(f'{key}: b_refits must be integer')
        B = int(bstr)
        family_size = m['family_size'].strip()
        if not family_size.isdigit() or int(family_size)<1:
            raise ValueError(f'{key}: family_size must be positive integer')
        declared = (m['calibration'].strip()=='refit_parametric_bootstrap' and
                    m['scope'].strip()=='global_process' and
                    m['origin'].strip()=='user_supplied' and
                    pval is not None and B >= 99 and
                    pval >= (1/(B+1)-1e-10))
        excursion = [p['observed']<p['lower'] or p['observed']>p['upper'] for p in pts]
        runs, run = 0, 0
        for q in excursion:
            run = run+1 if q else 0
            runs=max(runs,run)
        norms=[]
        for p in pts:
            center=(p['upper']+p['lower'])/2
            half=(p['upper']-p['lower'])/2
            norms.append(abs((p['observed']-center)/half))
        top=max(range(len(pts)),key=lambda i:norms[i])
        signed = [(q['observed'] - (q['upper'] + q['lower']) / 2) /
                  ((q['upper'] - q['lower']) / 2) for q in pts]
        deviations = [max(abs(v)-1.0, 0.0) for v in signed]
        x=[q['index'] for q in pts]
        span=x[-1]-x[0]
        # Index-weighted trapezoid integral; scale is dimensionless.
        area = sum((deviations[i] + deviations[i+1]) / 2 * (x[i+1]-x[i])
                   for i in range(len(pts)-1)) / span
        xf = [(v-x[0])/span for v in x]
        ym=statistics.fmean(signed)
        xm=statistics.fmean(xf)
        denom=sum((v-xm)**2 for v in xf)
        slope=sum((xx-xm)*(yy-ym) for xx,yy in zip(xf,signed))/denom
        positive=sum(v>1 for v in signed)
        negative=sum(v< -1 for v in signed)
        # Monte Carlo uncertainty approximates the Monte Carlo precision
        # of a supplied refit-bootstrap p-value, not its scientific validity.
        mcse=(math.sqrt(pval*(1-pval)/(B+1)) if pval is not None and B>0 else None)
        portion=top/max(len(pts)-1,1)
        region='early' if portion<1/3 else ('middle' if portion<2/3 else 'late')
        described = PROCESS_INFO.get(key[1],(key[1].replace('_',' ').title(),'Exploratory diagnostic process','Investigate the diagnostic ordering and model assumptions.'))
        prepared.append({
            'model':key[0], 'process':key[1], 'display':described[0],
            'candidate':described[1], 'next_step':described[2],
            'points':pts, 'n':len(pts),'max_ratio':round(norms[top],3),
            'peak_index':pts[top]['index'],'region':region,
            'excursion_fraction':round(sum(excursion)/len(pts),3),
            'longest_excursion':runs,
            'n_excursions':sum(excursion), 'positive_excursions':positive,
            'negative_excursions':negative, 'integrated_excess':round(area,6),
            'mean_signed_ratio':round(ym,5), 'signed_ratio_slope':round(slope,5),
            'peak_direction':'above' if signed[top]>0 else 'below',
            'mc_standard_error':None if mcse is None else round(mcse,7),
            'mc_min_p':None if B==0 else round(1/(B+1),8),
            'p_value':pval,'b_refits':B,
            'calibration':m['calibration'].strip(),'scope':m['scope'].strip(),
            'origin':m['origin'].strip(), 'family_id':m['family_id'].strip(),
            'family_size':int(family_size), 'eligible':declared,
            'demo_signal':m['demo_signal'].strip().lower() in ('true','1','yes'),
            'holm_p':None,
        })
    # Holm only if the COMPLETE prespecified family was provided, with every member eligible.
    families=defaultdict(list)
    for p in prepared: families[(p['model'],p['family_id'])].append(p)
    for family, members in families.items():
        n=len(members)
        complete = (family[1] != '' and n == members[0]['family_size'] and
                    all(x['family_size']==n and x['eligible'] for x in members))
        if complete:
            adj=_holm([x['p_value'] for x in members])
            for r, z in zip(members,adj): r['holm_p']=round(z,7)
    models=sorted(set(p['model'] for p in prepared))
    return {'models':models,'processes':prepared,'demo':all(p['origin']=='synthetic_demo' for p in prepared),
            'notes':[
              'A red validated signal requires a supplied global-process refit-bootstrap p-value and a complete Holm family.',
              'Process-specific departures do not establish the unique cause or an estimated probability of any candidate misspecification.',
              'Colored synthetic demonstrations do not represent validated statistical decisions.',
              'A lack of signal is not proof of adequate model specification.',
              'Envelope crossings and feature heuristics are exploratory unless their inferential scope has been calibrated.'
            ]}

def status(p, alpha=.05):
    if p['origin']=='synthetic_demo':
        return 'demo_signal' if p['demo_signal'] else 'demo_quiet'
    if p['holm_p'] is not None:
        return 'signal' if p['holm_p']<=alpha else 'not_detected'
    return 'unverified'

def explanations(obj, model, alpha=.05):
    rows=[p for p in obj['processes'] if p['model']==model]
    items=[]
    for p in rows:
        st=status(p,alpha)
        pattern=('Sustained excursion' if p['longest_excursion']>=6 else
                 'Localized excursion' if p['longest_excursion']>0 else 'No pointwise excursion')
        if st=='signal':
            headline='Calibrated global signal (Holm adjusted p = %.4g)'%p['holm_p']
        elif st=='not_detected':
            headline='No global signal at selected alpha (Holm adjusted p = %.4g)'%p['holm_p']
        elif st.startswith('demo_'):
            headline='Illustrative pattern only; no calibrated inference'
        else:
            headline='Uncalibrated / incomplete family: inference withheld'
        items.append({'process':p['display'],'status':st,'headline':headline,
                      'pattern':pattern,'where':p['region'],'candidate':p['candidate'],
                      'advice':p['next_step'],
                      'interpretation': ('This process can motivate a check of '+p['candidate'].lower()+
                                         '. This is a diagnostic lead, not an identified cause.'),
                      'index':p['peak_index']})
    return items
