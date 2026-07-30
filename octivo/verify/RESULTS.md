# Octivo scroll-film — verification results (draft chain)

Run: 2026-07-30, Higgsfield sandbox, headless Chromium 1440x900 (software raster).
Page at commit `729b2bf` (FRAME_COUNT=301, seam #7d5871).

## Captures — 14/14 rendered
`?jump=` dev contract used for deterministic loads. META: film 7650px,
sections at what=8064 / work=8947 / quote=9885 / cta=10330.

| shot | scrollY | check |
|---|---|---|
| 01-hero | 0 | wordmark + tagline over starfield, ambient glisten |
| 02–08 junctions/beats | 1350–5400 | canvas draws distinct frame at every position, beat copy visible (edge-density spikes at each beat vs neighbours) |
| 09-beat5 | 6278 | gathering scene + CTA beat |
| 10-seam | 6548 | seam fade engaged (brightest frame, mean 86) |
| 11–14 after-film | 7974–10290 | cards, work rows, quote, CTA + footer all render |

Luminance arc 34 → 86 across the film matches the void→fire art direction.
No blank/black canvas at any position (dark% ≤ 5).

## Jank (wheel scrub with lenis, full film + after-film)
- `window.__jank`: **max 50ms, p95 33ms** — no decode stalls; the
  ImageBitmap sliding window holds. endY 10131 (reached the footer).
- Software rendering; real-GPU hardware will only improve this.

## Independent visual read (Higgsfield video analysis of the shot reel)
Scene-by-scene analysis matched every chapter in order: space descent,
constellations, veil + embers, crystalfield with warm glow, six figures
around the fire under a drawn constellation, then cards / work list /
CTA button with email + social footer.

## Artifacts (CDN)
- shots (14 full-res JPEG, tar): e754e6c8-ca31-46d6-b8a8-f0ac225087b2.tar
- frames.zip (301 frames, 8.6MB): 11fb1e43-6bfc-4768-8a60-4d45b2981c45.zip
- contact sheets: a2eaea35 (film), f04ab856 (after-film) .jpg
- shot reel: cdc87240-9001-46b2-91d4-39d61a5ba056.mp4
(all under https://d2ol7oe51mr4n9.cloudfront.net/user_3DcoKKJzH3SBkPcfmcDa4zGDmFc/)

## Status
Draft chain verified end-to-end. Pending user approval: master pass
(higher-res regen/upscale of the 5 clips) and deploy.
