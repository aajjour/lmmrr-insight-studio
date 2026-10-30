#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -e results/parity/cross_language_results.json ]]; then
  echo 'BLOCKED: R/Python numerical parity results not present. Run ./run_mac.sh parity on Mac.' >&2
  exit 2
fi
python3 - <<'PY'
import json
p=json.load(open('results/parity/cross_language_results.json'))
if p.get('gate') != 'MATCHED_NONBOOTSTRAP_PROTOTYPE_PASS':
    raise SystemExit('BLOCKED: Paired non-bootstrap R/Python prototype parity did not pass.')
print('PAIRED PROTOTYPE GATE PASSED.')
print('ORIGINAL PUBLISHED SOURCE EQUIVALENCE: NOT VALIDATED.')
print('Only publish as explicitly exploratory, non-bootstrap prototype, not as a complete Python port.')
PY
if [[ ! -d .git ]]; then
  echo "After inspecting metadata, optionally initialize a PRIVATE repository with:"
  echo "git init && git add . && git commit -m 'Non-bootstrap R/Python prototype' && gh repo create aajjour/lmmrr-insight-studio --private --source=. --remote=origin --push"
else
  echo 'Existing git directory found; inspect remote/status before any push.'
fi
