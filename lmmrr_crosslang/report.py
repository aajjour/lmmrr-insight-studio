"""Offline numeric report. Red marks individual |innovation| >= 3 descriptively."""
from pathlib import Path
import json,html,math
from .core import compute
from .fixtures import get_input,DATASETS,MODELS

def _svg(trace,title):
    vals=trace['centered_cusum']; n=len(vals)
    w,h=750,255;pad=38
    scale=max(max(abs(v) for v in vals),1e-9)
    def x(i):return pad+(w-2*pad)*i/max(n-1,1)
    def y(v):return h/2-(h/2-pad)*v/scale
    line=' '.join(f'{x(i):.1f},{y(v):.1f}' for i,v in enumerate(vals))
    # The centered CUSUM deliberately has no reference envelope.
    dots=''.join(f'<circle cx="{x(i):.1f}" cy="{y(vals[i]):.1f}" r="3.2" fill="#D94350"><title>Row {trace["row_id"][i]}, |innovation|≥3 (descriptive)</title></circle>' for i,v in enumerate(trace['innovation']) if abs(v)>=3)
    return f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="{html.escape(title)}"><line x1="{pad}" y1="{h/2}" x2="{w-pad}" y2="{h/2}" stroke="#97A5B9" stroke-dasharray="4 4"/><polyline points="{line}" fill="none" stroke="#176CBB" stroke-width="2.4" stroke-linejoin="round"/>{dots}<text x="{pad}" y="20" fill="#253D5B" font-size="13">Centered indexed CUSUM • descriptive only</text><text x="{pad}" y="{h-7}" fill="#566780" font-size="11">Scientific-index order →</text></svg>'

def report(fixtures,output):
    output=Path(output);output.parent.mkdir(parents=True,exist_ok=True)
    traces={}
    for ds in DATASETS:
      for model in MODELS:
       for ordering in ('time','marginal_fitted','reverse_time'):
        traces[f'{ds}__{model}__{ordering}']=compute(get_input(fixtures,ds,model,ordering))
    cards=[];table=[]
    for tag,t in traces.items():
        f=t['features']; div=t['inference']
        text=('Review individual extremes; cannot determine cause or significance.' if f['n_abs_innovation_ge_3'] else 'No individual |innovation| ≥ 3. This does not establish model adequacy.')
        table.append(f'<tr><td>{html.escape(tag)}</td><td>{t["n"]}</td><td>{f["max_abs_innovation"]:.4f}</td><td>{f["n_abs_innovation_ge_3"]}</td><td>{f["max_abs_centered_cusum"]:.4f}</td><td class="amber">Uncalibrated</td></tr>')
        cards.append(f'<section class="card"><div class="headline"><h3>{html.escape(tag)}</h3><span class="pill">Descriptive only</span></div><p class="sub">Max |innovation|: {f["max_abs_innovation"]:.3f} &nbsp;·&nbsp; Rows with |innovation| ≥3: <strong class="red">{f["n_abs_innovation_ge_3"]}</strong> &nbsp;·&nbsp; Max |centered CUSUM|: {f["max_abs_centered_cusum"]:.3f}</p>{_svg(t,tag)}<p class="sub">{text} Red dots flag individual extremes, not an inferential test or identified misspecification.</p></section>')
    result={'scope':'Cholesky innovation indexed-process descriptive features from R fitted LMM parameters',
            'datasets':list(DATASETS),'model_structures':list(MODELS),'orderings':['time','marginal_fitted','reverse_time'],
            'bootstrap':'NOT_IMPLEMENTED','published_RR_reference_parity':'NOT_TESTED',
            'models':{tag:t['features'] for tag,t in traces.items()}}
    (output.parent/'nonbootstrap_results.json').write_text(json.dumps(result,indent=2))
    css='''body{background:#f3f6fc;color:#193150;font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;margin:0}main{max-width:1180px;margin:auto;padding:27px}header{background:linear-gradient(115deg,#102d53,#176dbb);color:white;padding:32px;border-radius:18px}header p{color:#dbeaff}.tabs{display:flex;gap:8px;flex-wrap:wrap;margin:20px 0}.tabs button{border:1px solid #d4deed;border-radius:18px;padding:10px 14px;background:white;color:#253D5B;cursor:pointer}.tabs button.active{background:#176dbb;color:white}.card{background:white;border-radius:16px;padding:22px;margin:15px 0;border:1px solid #e3e9f4;box-shadow:0 4px 18px #dce3ef66}.headline{display:flex;align-items:center;justify-content:space-between;gap:12px}.headline h3{margin:0}.pill{border-radius:15px;padding:5px 12px;background:#fff0d3;color:#855a13;font-size:12px;font-weight:bold}.amber{color:#996511;font-weight:600}.red{color:#ce3949}.sub{color:#62738b}table{width:100%;border-collapse:collapse;background:white}td,th{text-align:left;padding:9px;border-bottom:1px solid #e6ecf4;font-size:13px}.scroll{overflow-x:auto}svg{width:100%;height:auto} .notice{border-left:5px solid #d5942e;background:#fff8ea;padding:13px;border-radius:7px;margin-top:15px}'''
    js='''document.querySelectorAll("button[data-ds]").forEach(b=>b.addEventListener("click",()=>{document.querySelectorAll("button[data-ds]").forEach(x=>x.classList.remove("active"));b.classList.add("active");document.querySelectorAll(".card[data-tag]").forEach(x=>x.hidden= !x.dataset.tag.startsWith(b.dataset.ds) && b.dataset.ds!=="all");}));'''
    sections=''.join('<div class="card" data-tag="'+html.escape(k)+'">'+c+'</div>' for k,c in zip(traces,cards))
    # avoid nested .card wrappers; use per model sections directly
    sections=''.join('<div data-tag="'+html.escape(k)+'">'+c+'</div>' for k,c in zip(traces,cards))
    page=f'''<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>LMM RR — non-bootstrap validation report</title><style>{css}</style></head><body><main><header><h1>LMM RR · Cross-language Diagnostic Studio</h1><p>R-fitted LMM parameter inputs → marginal Cholesky innovations → indexed CUSUM profiles. Reproducibility prototype.</p></header><div class="notice"><strong>AMBER: No calibrated inferential verdicts.</strong> Red chart dots mark |innovation| ≥ 3 as a descriptive threshold. Their presence does not prove misspecification, and the centered CUSUM has NO universal critical envelope here. Bootstrap, published-source parity, and Python publication certification remain pending.</div><div class="card"><h2>Numerical evidence matrix</h2><div class="scroll"><table><thead><tr><th>Model / ordering</th><th>N</th><th>Max |innovation|</th><th>Individual extremes</th><th>Max |centered CUSUM|</th><th>Status</th></tr></thead><tbody>{''.join(table)}</tbody></table></div></div><h2>Indexed-process explorer</h2><div class="tabs"><button data-ds="all" class="active">All</button><button data-ds="sleepstudy">sleepstudy</button><button data-ds="Orthodont">Orthodont</button></div>{sections}<footer class="sub">No bootstrap was run. The reported process is an independently specified prototype and not yet a confirmed byte-equivalent implementation of the published lmmRRdiag code. DOI: 10.1080/00949655.2026.2748404.</footer></main><script>{js}</script></body></html>'''
    output.write_text(page,encoding='utf-8')
    return output
