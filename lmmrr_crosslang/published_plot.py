"""Zero-dependency presentation of the original R result's numeric components.

Nothing here is a confidence envelope, calibrated threshold, or diagnostic p-value.
"""
import csv
from collections import defaultdict
from html import escape
from pathlib import Path
from math import isfinite


def make_report(numeric_csv: str | Path, html_path: str | Path, *, max_panels: int = 8) -> Path:
    by_component = defaultdict(list)
    with Path(numeric_csv).open(encoding='utf-8', newline='') as handle:
        for row in csv.DictReader(handle):
            try:
                i, v = int(row['index']), float(row['value'])
            except (ValueError, KeyError):
                continue
            if isfinite(v):
                by_component[row['component']].append((i, v))
    candidates = [(name, sorted(pts)) for name, pts in by_component.items() if len(pts) >= 4]
    candidates.sort(key=lambda x: (-len(x[1]), x[0]))
    sections = []
    for name, values in candidates[:max_panels]:
        w, h = 700, 205
        xs = [v[0] for v in values]
        ys = [v[1] for v in values]
        x0,x1 = min(xs),max(xs)
        y0,y1 = min(ys),max(ys)
        yspan = (y1-y0) if y1>y0 else 1
        xspan = (x1-x0) if x1>x0 else 1
        points = ' '.join(f'{40+620*(x-x0)/xspan:.2f},{170-135*(y-y0)/yspan:.2f}' for x,y in values)
        sections.append(
            f'<article><h2>{escape(name)}</h2><small>{len(values)} finite values · Range {y0:.5g} to {y1:.5g}</small>'
            f'<svg viewBox="0 0 {w} {h}" role="img" aria-label="Raw numerical sequence for {escape(name)}">'
            '<rect x="30" y="24" width="635" height="150" fill="#f5f7fb" rx="6"/>'
            f'<polyline fill="none" stroke="#2563eb" stroke-width="2" points="{points}"/>'
            '</svg></article>'
        )
    if not sections:
        sections = ['<p>No numeric vectors of length four or more were returned. Examine the RDS and structure text.</p>']
    html = f'''<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Published LMM RR · Python/R numeric explorer</title>
<style>body{{font-family:system-ui,sans-serif;max-width:920px;margin:40px auto;padding:0 20px;color:#14213d;background:#f9fafc}}article{{background:white;border-radius:14px;margin:20px 0;padding:20px;box-shadow:0 2px 18px #152b4e13}}h1{{margin-bottom:2px}}h2{{font-size:17px;margin:0 0 8px}}small{{color:#596777}}svg{{width:100%}}.note{{border-left:4px solid #bd7315;padding:12px;background:#fff7ed}}a{{color:#2256a4}}</style></head>
<body><h1>Published LMM RR — numeric component explorer</h1><p>Python interface to the published R engine · <a href="https://doi.org/10.1080/00949655.2026.2748404">Scientific article DOI: 10.1080/00949655.2026.2748404</a></p>
<p class="note"><b>Uncalibrated:</b> The following plots display raw numeric components of the R return object, retaining their source paths. They are not validated indexed RR diagnostic charts, confidence envelopes, p-values, model-misspecification alarms, or bootstrap outputs. Interpret components using the original function documentation.</p>
{''.join(sections)}</body></html>'''
    destination = Path(html_path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(html, encoding='utf-8')
    return destination
