#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
MASTER="$HOME/Downloads/LMM_RR_JSCS_PUBLISHED_MASTER_2026-10-29"
python3 scripts/find_published_sources.py "$MASTER"
echo "Read-only inventory; this does NOT verify the published algorithms."
