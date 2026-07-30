#!/usr/bin/env bash
# Octivo scroll-film verification — runs INSIDE the Higgsfield sandbox.
# Self-contained: fetches the site from the public repo, rebuilds frames from
# the draft clips, serves locally, captures beats/junctions + jank via cap.js,
# then PUTs artifacts to presigned URLs.
# Env (exported by the launcher call):
#   RAW        raw.githubusercontent.com base incl. commit SHA
#   SHOTS_PUT  presigned PUT URL for shots.tar (shots/ + sheets/)
#   FRAMES_PUT presigned PUT URL for frames.zip (optional)
set -e
cd /home/user
mkdir -p site/vendor/fonts site/frames shots sheets tmpf
curl -sSL -o site/index.html "$RAW/octivo/site/index.html"
curl -sSL -o site/vendor/lenis.min.js "$RAW/octivo/site/vendor/lenis.min.js"
for f in fraunces-latin-400-normal fraunces-latin-600-normal fraunces-latin-600-italic \
         fraunces-latin-900-normal space-grotesk-latin-400-normal \
         space-grotesk-latin-500-normal space-grotesk-latin-700-normal; do
  curl -sSL -o "site/vendor/fonts/$f.woff2" "$RAW/octivo/site/vendor/fonts/$f.woff2"
done
grep -q "FRAME_COUNT" site/index.html || { echo FATAL_BAD_HTML; exit 1; }
echo "FETCHED:$(du -sk site | cut -f1)K"

CLIPS="https://d8j0ntlcm91z4.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/hf_20260729_160844_f2828048-2549-44b1-839e-3897de8f7321.mp4 https://d8j0ntlcm91z4.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/hf_20260729_162216_969aae85-d891-432f-89b7-8667bec17136.mp4 https://d8j0ntlcm91z4.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/hf_20260729_163459_dfdba4a0-5b19-45b5-9a77-edee60948ec0.mp4 https://d8j0ntlcm91z4.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/hf_20260729_164922_259d8fd4-f40c-4e23-9d4a-c40d2f723c73.mp4 https://d8j0ntlcm91z4.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/hf_20260729_170218_09c47069-1578-4314-a708-cb8a70116a7b.mp4"
i=0; INPUTS=(); FILTER=""
for u in $CLIPS; do
  curl -sSL -o "c$i.mp4" "$u"
  INPUTS+=(-i "c$i.mp4")
  # Drop the duplicate junction frame on clips 2+ (chain overlap).
  if [ $i -eq 0 ]; then FILTER+="[0:v]setpts=PTS-STARTPTS[v0];"
  else FILTER+="[${i}:v]select='gte(n,1)',setpts=PTS-STARTPTS[v${i}];"; fi
  i=$((i+1))
done
CONCAT=""; for ((k=0;k<i;k++)); do CONCAT+="[v${k}]"; done
FILTER+="${CONCAT}concat=n=${i}:v=1:a=0[out]"
ffmpeg -y -v error "${INPUTS[@]}" -filter_complex "$FILTER" -map "[out]" \
  -fps_mode vfr -c:v libx264 -crf 16 -preset medium -pix_fmt yuv420p master.mp4
echo "MASTER:$(ffprobe -v error -select_streams v -show_entries stream=width,height,nb_frames -of csv=p=0 master.mp4)"
ffmpeg -v error -i master.mp4 -vf "select='not(mod(n,2))',scale=1280:-2" -fps_mode vfr -q:v 4 tmpf/f%04d.jpg
n=0; for f in tmpf/f*.jpg; do mv "$f" "$(printf 'site/frames/f%04d.jpg' $n)"; n=$((n+1)); done
echo "FRAME_COUNT:$(ls site/frames | wc -l)"
(cd site && zip -qr ../frames.zip frames)
if [ -n "$FRAMES_PUT" ]; then
  curl -sS -o /dev/null -w "PUT_FRAMES:%{http_code}\n" -X PUT -H "Content-Type: application/zip" --data-binary @frames.zip "$FRAMES_PUT"
fi

(cd site && nohup python3 -m http.server 8788 >/dev/null 2>&1 &)
sleep 1
export NODE_PATH=$(npm root -g 2>/dev/null)
node cap.js
echo CAPS_DONE
montage $(ls shots/*.jpg | head -10) -tile 2x5 -geometry 500x313+5+5 -background '#070722' -quality 74 sheets/film.jpg || echo MONTAGE1_FAIL
montage $(ls shots/*.jpg | tail -4) -tile 2x2 -geometry 500x313+5+5 -background '#070722' -quality 74 sheets/after.jpg || echo MONTAGE2_FAIL
echo "SHEETS:$(wc -c sheets/*.jpg 2>/dev/null | tr '\n' ' ')"
tar -cf shots.tar shots sheets
curl -sS -o /dev/null -w "PUT_SHOTS:%{http_code}\n" -X PUT -H "Content-Type: application/x-tar" --data-binary @shots.tar "$SHOTS_PUT"
echo ALLDONE
