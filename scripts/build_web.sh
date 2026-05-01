#!/usr/bin/env bash
# Build the web export and apply cache-busting in one step.
# Run from project root:  bash scripts/build_web.sh
set -euo pipefail

GODOT=${GODOT:-$HOME/.local/bin/godot}

cd "$(dirname "$0")/.."

echo "→ exporting to docs/play/"
"$GODOT" --headless --export-release "Web" docs/play/index.html

echo "→ cache-busting versioned filenames"
python3 scripts/cache_bust.py

echo "→ done"
ls docs/play/ | head -10
