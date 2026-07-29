#!/usr/bin/env bash
# Runs INSIDE the Higgsfield sandbox (bash). Mechanical lane — no model.
# Expects CLIP_URLS (space-separated, in order) and ZIP_PUT_URL (presigned) in env,
# or edit inline. Concat drops the duplicate junction frame on clips 2+, encodes
# master with -fps_mode vfr, extracts ~300 frames at 1280w q4, samples seam hex,
# zips frames and PUTs the zip.
set -e
i=0; INPUTS=(); FILTER=""
for u in $CLIP_URLS; do
  curl -sSL -o "c$i.mp4" "$u"
  INPUTS+=(-i "c$i.mp4")
  if [ $i -eq 0 ]; then FILTER+="[${i}:v]setpts=PTS-STARTPTS[v${i}];"
  else FILTER+="[${i}:v]select='gte(n,1)',setpts=PTS-STARTPTS[v${i}];"; fi
  i=$((i+1))
done
CONCAT=""; for ((k=0;k<i;k++)); do CONCAT+="[v${k}]"; done
FILTER+="${CONCAT}concat=n=${i}:v=1:a=0[out]"
ffmpeg -y -v error "${INPUTS[@]}" -filter_complex "$FILTER" -map "[out]" \
  -fps_mode vfr -c:v libx264 -crf 16 -preset medium -pix_fmt yuv420p master.mp4
echo "MASTER:$(ffprobe -v error -select_streams v -show_entries stream=width,height,nb_frames -of csv=p=0 master.mp4)"
mkdir -p frames
ffmpeg -v error -i master.mp4 -vf "select='not(mod(n,2))',scale=1280:-2" -fps_mode vfr -q:v 4 frames/f%04d.jpg
# rename to 0-based f0000.jpg... (ffmpeg starts at 1)
n=0; for f in frames/f*.jpg; do mv "$f" "$(printf 'frames/g%04d.jpg' $n)"; n=$((n+1)); done
for f in frames/g*.jpg; do mv "$f" "${f/g/f}"; done
COUNT=$(ls frames | wc -l)
echo "FRAME_COUNT:$COUNT SIZE:$(du -sh frames | cut -f1)"
LAST=$(ls frames/f*.jpg | tail -1)
SEAM=$(ffmpeg -v error -i "$LAST" -vf "crop=iw:ih*0.12:0:ih*0.88,scale=1:1" -frames:v 1 -f rawvideo -pix_fmt rgb24 - | od -An -tx1 | tr -d ' \n' | cut -c1-6)
echo "SEAM:#$SEAM"
zip -qr frames.zip frames
echo "ZIP:$(wc -c < frames.zip)"
curl -sS -o /dev/null -w "ZIP_PUT:%{http_code}\n" -X PUT -H "Content-Type: application/zip" --data-binary @frames.zip "$ZIP_PUT_URL"
