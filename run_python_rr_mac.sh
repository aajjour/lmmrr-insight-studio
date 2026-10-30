#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command -v Rscript >/dev/null || { echo 'BLOCKED: Rscript not installed'; exit 2; }
Rscript -e 'for (p in c("lme4", "jsonlite")) if (!requireNamespace(p, quietly=TRUE)) stop(paste("R dependency missing:", p))'
PYTHON="${PYTHON:-python3}"
"$PYTHON" -m unittest discover -s tests -v
"$PYTHON" -m lmmrr_crosslang.published_rr --inspect
"$PYTHON" -m lmmrr_crosslang.published_rr \
  --data fixtures/sleepstudy.csv \
  --formula 'y ~ x + (1|group)' \
  --output results/published_python_rr/sleepstudy_RI
"$PYTHON" - <<'PY'
import json
from pathlib import Path
p = Path('results/published_python_rr/sleepstudy_RI/published_rr_numeric_components.csv')
assert p.is_file() and p.stat().st_size > 40, 'No recursive residual output produced'
print('PUBLISHED R ENGINE CALLED SUCCESSFULLY FROM PYTHON')
print('Saved:', p)
print('Bootstrap executed: NO')
PY
