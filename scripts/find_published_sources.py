"""Read-only locator of research code in preserved published master, including archives.
Prints names/checksums, never extracts, executes, or alters the source.
"""
from pathlib import Path
import hashlib, json, sys, zipfile, tarfile

root=Path(sys.argv[1]).expanduser()
if not root.is_dir():sys.exit(f'Missing source master: {root}')
needle=('recursive_residuals.r','statistics.r','standard_audit.r','rpackage/lmmrrdiag/r/',
        '/lmmrrdiag/r/', 'lmmrrdiag/description','lmmrrdiag/tests/')
items=[]
for p in root.rglob('*'):
 if not p.is_file() or p.is_symlink(): continue
 rel=p.relative_to(root).as_posix()
 low=rel.lower()
 if any(n in low for n in needle):
  items.append(dict(location=rel,kind='file',bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
 if p.suffix.lower()=='.zip':
  try:
   with zipfile.ZipFile(p) as z:
    matches=[x.filename for x in z.infolist() if not x.is_dir() and any(n in x.filename.lower() for n in needle)]
    items.extend(dict(location=rel+' :: '+m,kind='zip-member') for m in matches)
  except (OSError,zipfile.BadZipFile) as exc:
   items.append(dict(location=rel,kind='unreadable-archive',reason=str(exc)))
print(json.dumps({'master':str(root),'matches':items,'source_parity':'NOT_TESTED'},indent=2))
Path('results').mkdir(exist_ok=True)
Path('results/published_source_inventory.json').write_text(json.dumps({'master':str(root),'matches':items},indent=2))
if not items:sys.exit('No published R code found; original-source parity BLOCKED')
