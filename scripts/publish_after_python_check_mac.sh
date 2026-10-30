#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO="aajjour/lmmrr-insight-studio"
if [[ ! -d .git ]]; then
  echo 'BLOCKED: Execute from the initialized Git repository.' >&2
  exit 2
fi
# The smoke gate executes the PUBLISHED R recursive-residual function from Python.
# It must NOT execute any bootstrap routine.
./run_python_rr_mac.sh
command -v gh >/dev/null || { echo 'BLOCKED: Install GitHub CLI (brew install gh).'; exit 2; }
gh auth status >/dev/null
python3 - <<'PY'
from pathlib import Path
import json
assert '10.1080/00949655.2026.2748404' in Path('README.md').read_text()
assert '10.1080/00949655.2026.2748404' in Path('CITATION.cff').read_text()
assert Path('reference/published_r/lmmRRdiag/LICENSE').is_file()
s = Path('reference/published_r/lmmRRdiag/DESCRIPTION').read_text()
assert 'MIT' in s, 'Check the original R source license before publication'
ci = Path('.github/workflows/parity.yml').read_text()
for command in ('./run_mac.sh selftest', './run_mac.sh parity'):
    assert command in ci, f'Unexpected CI contents: {command}'
print('Metadata, source license, DOI and known CI entrypoints: checked')
PY
# Refresh inventory for the new Python/R bridge files.
git add -A
python3 - <<'PY'
from pathlib import Path
from hashlib import sha256
from subprocess import check_output
names=check_output(['git','ls-files','-z']).split(b'\0')
rows=[]
for item in names:
    if not item: continue
    rel=item.decode()
    if rel=='FILE_CHECKSUMS.sha256': continue
    p=Path(rel)
    if p.is_symlink(): raise SystemExit(f'BLOCKED: tracked symlink {rel}')
    if not p.is_file(): raise SystemExit(f'BLOCKED: absent tracked file {rel}')
    rows.append(f'{sha256(p.read_bytes()).hexdigest()}  {rel}')
Path('FILE_CHECKSUMS.sha256').write_text('\n'.join(sorted(rows))+'\n')
print('Refreshed checksums for',len(rows),'tracked files')
PY
git add FILE_CHECKSUMS.sha256
git diff --cached --check
# Create an initial commit or update an existing branch.
if ! git diff --cached --quiet; then
  git commit -m 'Release R-backed Python access to published LMM RR diagnostics (no bootstrap run)'
fi
if gh repo view "$REPO" >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    REMOTE=$(git remote get-url origin)
    case "$REMOTE" in
      *aajjour/lmmrr-insight-studio*) ;;
      *) echo "BLOCKED: Existing remote points elsewhere: $REMOTE" >&2; exit 2;;
    esac
  else
    git remote add origin "https://github.com/${REPO}.git"
  fi
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --remote=origin --push \
    --description 'R/Python LMM diagnostics; Python API for published R indexed recursive residuals, CUSUM explorer, R bootstrap source.'
fi
gh api --method PUT -H 'Accept: application/vnd.github+json' \
  "repos/$REPO/topics" --input github_topics.json
printf '\nPUBLISHED: https://github.com/%s\n' "$REPO"
printf 'DOI: https://doi.org/10.1080/00949655.2026.2748404\n'
printf 'Bootstrap executed: NO\n'
