# Sample photos for "Xem mẫu" previews

Real baby photos with a free licence, used only for template previews and covers (owner,
2026-10-14: "dùng ảnh thật mà free trên mạng được xài"). `licence.json` lists each one: where it
comes from, the photographer, the licence (CC0 1.0 via StockSnap) and the owner's acceptance.

- **Licence:** CC0 1.0 waives the photographer's copyright, so commercial use, downloads and
  social sharing are allowed without attribution (photographers are listed anyway).
- **Known risk (owner accepted, 2026-10-14):** CC0 says nothing about the people in the photos;
  there is no model / guardian release. Before prod the owner may swap these for model-released
  photos; `apps/renderer/scripts/make-previews.ts` accepts either a `release` or this recorded
  acceptance, and refuses anything else.
- The photos are not kept in the repository: `node design/sample-photos/fetch.mjs <dir>` downloads
  them, with this `licence.json`, into `<dir>`.
