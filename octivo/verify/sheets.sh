#!/usr/bin/env bash
# Rebuild contact sheets + base64 files from the CDN shots.tar if missing.
# Idempotent: no-ops when a.b64/f.b64 already exist. Env: SHOTS_GET (tar URL).
set -e
cd /home/user
[ -f a.b64 ] && [ -f f.b64 ] && exit 0
curl -sfSL -o s.tar "$SHOTS_GET"
tar xf s.tar
python3 - <<'P'
from PIL import Image; import glob
fs=sorted(glob.glob('shots/*.jpg'))
assert len(fs)==14, fs
def sheet(files,cols,out,tw,th,q):
    rows=(len(files)+cols-1)//cols
    im=Image.new('RGB',(cols*tw+(cols+1)*5, rows*th+(rows+1)*5),(7,7,34))
    for i,f in enumerate(files):
        t=Image.open(f); t.thumbnail((tw,th))
        r,c=divmod(i,cols)
        im.paste(t,(5+c*(tw+5),5+r*(th+5)))
    im.save(out,quality=q,optimize=True)
import os; os.makedirs('sheets',exist_ok=True)
sheet(fs[:10],2,'sheets/film.jpg',420,263,62)
sheet(fs[10:],2,'sheets/after.jpg',420,263,62)
P
base64 -w0 sheets/film.jpg > f.b64
base64 -w0 sheets/after.jpg > a.b64
md5sum sheets/*.jpg
wc -c f.b64 a.b64
