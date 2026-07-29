#!/usr/bin/env bash
# Mechanical chain helpers (no model): download clip -> extract last frame -> SSIM gate.
# Engine transport is the Higgsfield MCP connection (driven by Claude); this script does
# only the pure-shell parts of the chain contract.
set -euo pipefail
FF="${FFMPEG:-ffmpeg}"
DIR="$(cd "$(dirname "$0")" && pwd)"

cmd="$1"; shift
case "$cmd" in
  download)          # download <url> <out.mp4>
    curl -sSL --retry 4 --retry-delay 2 -o "$2" "$1"
    ls -la "$2" ;;
  lastframe)         # lastframe <clip.mp4> <out.png>
    "$FF" -y -sseof -0.05 -i "$1" -update 1 -q:v 1 "$2" 2>/dev/null
    ls -la "$2" ;;
  firstframe)        # firstframe <clip.mp4> <out.png>
    "$FF" -y -i "$1" -vf "select=eq(n\,0)" -vframes 1 -q:v 1 "$2" 2>/dev/null
    ls -la "$2" ;;
  ssim)              # ssim <A-last.png> <B-first.png>  -> prints All score
    "$FF" -i "$1" -i "$2" -lavfi "scale2ref[a][b];[a][b]ssim" -f null - 2>&1 | grep -o 'All:[0-9.]*' | tail -1 ;;
  *) echo "unknown cmd: $cmd" >&2; exit 1 ;;
esac
