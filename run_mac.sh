#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
command="${1:-all}"
PY="${PYTHON:-python3}"
if ! "$PY" -c 'import numpy' >/dev/null 2>&1; then
  echo 'Missing numpy. Install using: python3 -m venv .venv && source .venv/bin/activate && pip install -e .' >&2
  exit 2
fi
case "$command" in
  selftest)
    "$PY" -m unittest discover -s tests -v
    ;;
  report)
    PYTHONPATH=. "$PY" -m lmmrr_crosslang.cli --fixtures fixtures --output results/nonbootstrap_report.html
    ;;
  parity)
    command -v Rscript >/dev/null || { echo 'BLOCKED: Rscript not found'; exit 2; }
    mkdir -p results/r_reference
    Rscript validation/run_r_reference.R fixtures results/r_reference
    PYTHONPATH=. "$PY" validation/compare_reference.py --fixtures fixtures --reference results/r_reference --output results/parity
    ;;
  all)
    "$0" selftest
    "$0" studio-selftest
    "$0" report
    "$0" parity
    ;;
  studio)
    echo "SYNTHETIC DEMO ONLY: apparent red signals are illustrations, not calibrated inference."
    ( cd studio_demo && "$PY" -m app.server --data examples/demo )
    ;;
  studio-selftest)
    ( cd studio_demo && "$PY" -m unittest discover -s tests -v )
    ;;
  source-audit)
    bash scripts/locate_published_reference.sh
    ;;
  *) echo 'Usage: ./run_mac.sh [selftest|report|parity|all|source-audit|studio|studio-selftest]'; exit 2;;
esac
