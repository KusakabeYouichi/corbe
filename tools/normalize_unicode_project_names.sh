#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME_PATH="$ROOT_DIR/corbé.xcodeproj/xcshareddata/xcschemes/corbé.xcscheme"

if [[ ! -f "$SCHEME_PATH" ]]; then
  exit 0
fi

# Keep scheme identifiers in NFC/precomposed form to avoid noisy diffs (écritu と同じ対策)
perl -CSDA -i -pe 's/corb(?:e&#x301;|e&#769;|&#x[eE]9;|&#233;|e\x{301}|Ã©|é)\.xcodeproj/corb\x{E9}.xcodeproj/g; s/corb(?:e&#x301;|e&#769;|&#x[eE]9;|&#233;|e\x{301}|Ã©|é)"/corb\x{E9}"/g' "$SCHEME_PATH"
