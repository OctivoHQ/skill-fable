#!/usr/bin/env bash
# Build a fully self-contained preview.html (frames, fonts, lenis inlined)
# and PUT it to a presigned URL so the page is viewable straight off the CDN.
# Env: RAW (repo raw base incl. SHA), FRAMES_GET (frames.zip URL),
#      HTML_PUT (presigned PUT URL), HTML_URL (final CDN URL, for the check)
set -e
cd /home/user
mkdir -p site/vendor/fonts
curl -sSL -o site/index.html "$RAW/octivo/site/index.html"
curl -sSL -o site/vendor/lenis.min.js "$RAW/octivo/site/vendor/lenis.min.js"
for f in fraunces-latin-400-normal fraunces-latin-600-normal fraunces-latin-600-italic \
         fraunces-latin-900-normal space-grotesk-latin-400-normal \
         space-grotesk-latin-500-normal space-grotesk-latin-700-normal; do
  curl -sSL -o "site/vendor/fonts/$f.woff2" "$RAW/octivo/site/vendor/fonts/$f.woff2"
done
[ -d site/frames ] || { curl -sfSL -o frames.zip "$FRAMES_GET" && unzip -qo frames.zip -d site; }
python3 - <<'P'
import base64, glob
html = open('site/index.html').read()
for p in sorted(glob.glob('site/vendor/fonts/*.woff2')):
    b = base64.b64encode(open(p, 'rb').read()).decode()
    name = p.split('/')[-1]
    assert f"url('vendor/fonts/{name}')" in html, name
    html = html.replace(f"url('vendor/fonts/{name}')", f"url(data:font/woff2;base64,{b})")
lenis = open('site/vendor/lenis.min.js').read()
assert '</script' not in lenis.lower()
html = html.replace('<script src="vendor/lenis.min.js"></script>', '<script>\n' + lenis + '\n</script>')
frames = [base64.b64encode(open(f, 'rb').read()).decode() for f in sorted(glob.glob('site/frames/*.jpg'))]
assert len(frames) == 301, len(frames)
arr = '["' + '","'.join('data:image/jpeg;base64,' + x for x in frames) + '"]'
old = "const framePath = i => `frames/f${String(i).padStart(4,'0')}.jpg`;"
assert old in html
html = html.replace(old, 'const __F=' + arr + ';const framePath = i => __F[i];')
assert "vendor/" not in html and "frames/f" not in html
open('preview.html', 'w').write(html)
print('PREVIEW_BYTES:', len(html))
P
curl -sS -o /dev/null -w "PUT_HTML:%{http_code}\n" -X PUT -H "Content-Type: text/html" --data-binary @preview.html "$HTML_PUT"
curl -sI "$HTML_URL" | head -8
echo SINGLEFILE_DONE
