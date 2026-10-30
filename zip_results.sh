#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ ! -f results/parity/cross_language_results.json ]]; then
  echo 'PARITY RESULT MISSING: run ./run_mac.sh parity first' >&2
  exit 2
fi
OUT="$HOME/Downloads/LMM_RR_NonBootstrap_Parity_Mac_Results_2026-10-30.zip"
python3 - "$OUT" <<'PY'
from pathlib import Path
import zipfile,sys
out=Path(sys.argv[1])
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
 for p in sorted(Path('results').rglob('*')):
  if p.is_file(): z.write(p,p.as_posix())
 for p in [Path('fixtures/r_session_info.txt'),Path('README.md'),Path('docs/RELEASE_GATE.md')]:
  z.write(p,p.as_posix())
print('Results ZIP created:',out)
PY
