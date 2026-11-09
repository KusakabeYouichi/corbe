#!/usr/bin/env bash
# 索引の元データ(Unicode 17.0.0)を tmp/sources へ取得する。生データはコミットしない(tmp/ は gitignore)。
#   Unihan.zip                     kRSUnicode / kTotalStrokes / kJis0 / kJapanese(tmp/sources/unihan/ へ展開)
#   CJKRadicals.txt                部首番号 → 代表字・CJK Radicals Supplement の字
#   EquivalentUnifiedIdeograph.txt 部首の字 → 統合漢字
# BabelStone IDS は URL が常に最新版を返すため、採用した版を third_party/babelstone/IDS.TXT としてコミットしている(ここでは取らない)。
#
# 版は固定し、取得した各ファイルを tools/sources.sha256 と突き合わせてから tmp/ へ置く(écritu の fetch_unihan_raw.sh と同じ作法)。
# 版を上げるときは UNICODE_VERSION を変え、--print-hashes の実測で manifest を同じコミットで更新する。
#   使い方: bash tools/fetch_sources.sh [--force] [--print-hashes] [--dest <path>]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$ROOT_DIR/tmp/sources"
UNICODE_VERSION="17.0.0"
BASE_URL="https://www.unicode.org/Public/${UNICODE_VERSION}/ucd"
FILES=(Unihan.zip CJKRadicals.txt EquivalentUnifiedIdeograph.txt)
MANIFEST_PATH="$ROOT_DIR/tools/sources.sha256"
FORCE=false
PRINT_HASHES=false

while (($# > 0)); do
  case "$1" in
    --force) FORCE=true; shift ;;
    --print-hashes) PRINT_HASHES=true; shift ;;
    --dest)
      (($# >= 2)) || { echo "[sources] Missing value for --dest" >&2; exit 1; }
      DEST_DIR="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "[sources] Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -f "$DEST_DIR/unihan/Unihan_IRGSources.txt" && -f "$DEST_DIR/CJKRadicals.txt" \
  && -f "$DEST_DIR/EquivalentUnifiedIdeograph.txt" && "$FORCE" != "true" ]]; then
  echo "[sources] 既に取得済み: $DEST_DIR (再取得は --force)"
  exit 0
fi

[[ -f "$MANIFEST_PATH" ]] || { echo "[sources][error] manifest が見つかりません: $MANIFEST_PATH" >&2; exit 1; }

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

for name in "${FILES[@]}"; do
  echo "[sources] downloading $BASE_URL/$name"
  curl -fsSL --max-time 300 -o "$tmp_dir/$name" "$BASE_URL/$name"
done

# 照合: 取得した全ファイルを manifest と突き合わせ、1 件でも合わなければ DEST_DIR には置かない
mismatches=()
actual_lines=()
for name in "${FILES[@]}"; do
  actual_hash="$(shasum -a 256 "$tmp_dir/$name" | cut -d' ' -f1)"
  actual_lines+=("$actual_hash  $name")
  expected_hash="$(grep -E "^[0-9a-f]{64}  ${name}$" "$MANIFEST_PATH" | cut -d' ' -f1 || true)"
  if [[ -z "$expected_hash" ]]; then
    mismatches+=("$name: manifest に無い(実測 $actual_hash)")
  elif [[ "$expected_hash" != "$actual_hash" ]]; then
    mismatches+=("$name: 期待 $expected_hash / 実測 $actual_hash")
  fi
done

if [[ "$PRINT_HASHES" == "true" ]]; then
  echo "[sources] 実測ハッシュ(manifest 形式):"
  printf '%s\n' "${actual_lines[@]}"
fi

if ((${#mismatches[@]} > 0)); then
  echo "[sources][error] 取得したファイルが tools/sources.sha256 と一致しません。tmp/ には置きません。" >&2
  printf '  %s\n' "${mismatches[@]}" >&2
  echo "[sources][error] 版を上げる意図なら UNICODE_VERSION を変え、--print-hashes の実測で manifest を同じコミットで更新してください(version=${UNICODE_VERSION})" >&2
  exit 1
fi
echo "[sources] manifest と一致(${#FILES[@]} ファイル、version=${UNICODE_VERSION})"

mkdir -p "$DEST_DIR/unihan"
unzip -oq "$tmp_dir/Unihan.zip" -d "$DEST_DIR/unihan"
mv -f "$tmp_dir/CJKRadicals.txt" "$tmp_dir/EquivalentUnifiedIdeograph.txt" "$DEST_DIR/"
echo "[sources] done:"
ls -1 "$DEST_DIR" "$DEST_DIR/unihan"
