# Xem mẫu media: sources and clearance

The "Xem mẫu" previews and covers of video templates (`scripts/make-previews.ts`) and the music
library are published to every parent, so everything in them must be cleared for publishing,
downloads and social sharing (owner, 2026-10-14).

## Photos

Rule: a photo of a real person needs a licence for the photo **and** either a model / guardian
release or the owner's recorded acceptance of a free licence without one (owner, 2026-10-14:
"dùng ảnh thật mà free trên mạng được xài"). `make-previews.ts` enforces this from the folder's
`licence.json` (`release`, or `ownerApproved` with a CC0 / Pexels / Unsplash licence); anything else
stops the script.

| Set | Status |
|---|---|
| `design/sample-photos` (18 CC0 photos from StockSnap, listed with photographer and page) | **In use** for all 16 video previews and covers on dev. Free licence, **no model release** (risk accepted by the owner, 2026-10-14). Not stored in the repo: `fetch.mjs` downloads them. |
| `player/samples/1–6.jpg` | Illustrations, no people; the WebView player's automatic sample. |
| Model-released photos | Not bought. If the owner wants to remove the release risk before prod, buy model-released images, list them with `release`, re-run `make-previews.ts` and publish. |

## Music

| Track | Id | Mood | Status |
|---|---|---|---|
| Ru êm | `music_ru_em` | gentle | Original (engineering, `compose-music.mjs`), owned — **placeholder** |
| Nắng mai | `music_nang_mai` | happy / playful | Original, owned — **placeholder** |
| Bình minh | `music_binh_minh` | emotional (piano) | Original, owned — **placeholder** |
| Mơ màng | `music_mo_mang` | dreamy | Original, owned — **placeholder** |
| Tiệc vui | `music_tiec_vui` | festive (celebration) | Original, owned — **placeholder** |

These are legally clean (composed and synthesised here, no samples) but are synthesised
placeholders. Production needs 4–5 commercially licensed instrumentals covering emotional piano,
warm acoustic, playful, dreamy and celebration, with a licence that allows server-rendered video,
downloads and social sharing; staff add them in the portal (Nhạc nền) with the licence fields
filled. The library holds up to 100 tracks.

## Art

The decorative art library is original (`design/keepsake-art`, manifest and licence there).
