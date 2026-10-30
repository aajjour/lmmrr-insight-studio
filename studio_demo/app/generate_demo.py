"""Synthetic traces for interface demonstration; NOT published LMM RR bootstrap outputs."""
import csv, math, random
from pathlib import Path

def generate(where):
    d=Path(where); d.mkdir(parents=True, exist_ok=True)
    models=['A · Baseline illustration','B · Mean drift illustration','C · Grouping illustration',
            'D · Serial illustration','E · Random-slope illustration']
    processes=['mean_indexed','cluster_indexed','serial_indexed','blup_indexed']
    traces=[]; evidence=[]
    for mi,model in enumerate(models):
        for pi,process in enumerate(processes):
            rng=random.Random(1000+mi*41+pi*19)
            is_signal=((mi,pi) in [(1,0),(2,1),(3,2),(4,3)])
            obs=0.
            for j in range(120):
                t=(j+1)/120
                obs=0.87*obs+0.13*rng.gauss(0,.95)
                val=obs + .22*math.sin(t*7+pi)
                if is_signal:
                    val+= 2.6/(1+math.exp(-16*(t-.5)))
                upper=1.15+ .12*math.sin(t*math.pi)
                lo=-upper
                traces.append([model,process,j+1,round(val,5),round(lo,5),round(upper,5)])
            evidence.append([model,process,'','synthetic_only','illustrative',0,
                             'synthetic_demo',f'synthetic_{mi}',4,str(is_signal).lower()])
    with (d/'traces.csv').open('w',newline='',encoding='utf8') as f:
        w=csv.writer(f);w.writerow(['model','process','index','observed','lower','upper']);w.writerows(traces)
    with (d/'evidence.csv').open('w',newline='',encoding='utf8') as f:
        w=csv.writer(f);w.writerow(['model','process','p_value','calibration','scope','b_refits','origin','family_id','family_size','demo_signal']);w.writerows(evidence)
    (d/'README.txt').write_text('SYNTHETIC INTERFACE DEMONSTRATION ONLY. No LMM is fitted; no refit-bootstrap calibration is performed; no p-values are estimated.\n')

if __name__=='__main__':
    import sys
    generate(sys.argv[1])
