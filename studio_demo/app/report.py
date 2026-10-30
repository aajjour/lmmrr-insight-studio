"""Static HTML report, standard library only; can be printed to PDF in browser."""
from html import escape
from pathlib import Path
from .engine import explanations, status

def svg(points):
    values=[v for p in points for v in (p['observed'],p['lower'],p['upper'])]
    mini,maxi=min(values),max(values)
    if mini==maxi:maxi+=1
    n=len(points)
    def xx(i):return 55+(i/max(n-1,1))*690
    def yy(y):return 214-((y-mini)/(maxi-mini))*185
    def lines(field):return ' '.join(f'{xx(i):.1f},{yy(p[field]):.1f}' for i,p in enumerate(points))
    envelope=' '.join([f'{xx(i):.1f},{yy(p["upper"]):.1f}' for i,p in enumerate(points)]+
                      [f'{xx(i):.1f},{yy(p["lower"]):.1f}' for i,p in reversed(list(enumerate(points)))])
    return ('<svg viewBox="0 0 790 245" role="img" aria-label="Indexed process and supplied bounds">'
        '<rect width="790" height="245" fill="#fff"/>'
        '<path d="M55 20V214H745" fill="none" stroke="#cbd5e1"/>'
        f'<polygon points="{envelope}" fill="#dceafe" opacity=".85"/>'
        f'<polyline points="{lines("observed")}" fill="none" stroke="#1453a4" stroke-width="2.6"/>'
        '<text x="55" y="239" fill="#64748b" font-size="12">Indexed position</text></svg>')

def render_report(obj, dest, alpha=.05):
    root=['<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">',
    '<title>LMM RR Insight Report</title><style>body{font:15px -apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#1d2943;background:#f3f6fc;max-width:1000px;margin:35px auto;padding:0 18px}.card{background:white;border:1px solid #d9e2f0;border-radius:16px;padding:22px;margin:16px 0;page-break-inside:avoid}h1{font-size:30px}.note{background:#fff2d6;padding:14px;border-left:4px solid #d49625;border-radius:7px}small{color:#66758e}.signal{color:#b52430}.not_detected{color:#16745b}.unverified{color:#666d7b}.demo_signal{color:#b52430}.demo_quiet{color:#666d7b}svg{width:100%;max-width:790px}p{line-height:1.6}@media print{body{background:white;margin:0}.card{border-color:#d2d2d2}}</style></head><body>',
    '<h1>LMM RR · Interpretive diagnostic report</h1>',
    '<p class="note"><b>Scope:</b> This is an interpretive layer for user-supplied indexed process traces and evidence. It does not estimate LMM recursive residuals or bootstrap p-values. Synthetic examples are illustrative.</p>',
    f'<p><small>Selected alpha: {alpha:.3g}. Familywise Holm corrections apply only to complete, appropriately labeled supplied bootstrap families. Article DOI: 10.1080/00949655.2026.2748404.</small></p>']
    for model in obj['models']:
        root.append(f'<h2>{escape(model)}</h2>')
        explanations_by_process=explanations(obj,model,alpha)
        for p,ex in zip([p for p in obj['processes'] if p['model']==model], explanations_by_process):
            st=status(p,alpha)
            root.append('<section class="card">')
            root.append(f'<h3>{escape(p["display"])} · <span class="{st}">{escape(ex["headline"])}</span></h3>')
            root.append(svg(p['points']))
            root.append(f'<p><b>Pattern:</b> {escape(ex["pattern"])} near {escape(ex["where"])} ordering. Peak index {escape(str(p["peak_index"]))}. Maximum observed/bound normalized ratio {p["max_ratio"]:.2f} (descriptive, not a p-value).</p>')
            root.append(f'<p><b>Candidate check:</b> {escape(ex["candidate"])}. {escape(ex["advice"])}</p>')
            root.append('</section>')
    root.append('<p><small>No absence of a signal establishes correct specification. A signal is not a unique misspecification diagnosis. Generated locally; no data uploaded.</small></p></body></html>')
    dest=Path(dest);dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text(''.join(root),encoding='utf8')
    return dest
