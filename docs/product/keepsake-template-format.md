# Mẫu kỷ niệm: the data portal and app share (D-068 #7, #8)

This is the contract between the portal (which writes templates) and the app (which draws them). The two
need no code change when a template is added or edited, as long as it only uses what is described here.

- **Source of truth**: `packages/contracts/src/keepsakes.ts`. It holds the zod schema used by the portal
  and by Functions on save and publish.
- **App mirror**: `apps/mobile/lib/features/keepsakes/keepsake_catalog.dart` (reader) and
  `keepsake_card_view.dart` (renderer).
- **Portal mirror**: `apps/portal/src/screens/Keepsakes.tsx`, function `CardPreview`.

## 1. Where it lives

| What | Where | Who writes | Who reads |
|---|---|---|---|
| Published catalog | Firestore `publicConfig/keepsakes` | Functions, on approval (`staffKeepsakesAct`) | App (any signed-in member), portal |
| Draft and history | `content/keepsakes/versions/kv_…` | Portal through `staffKeepsakesDraft` | Portal |
| Highest version ever used per template | `content/keepsakes.highest` | Functions | Functions |
| Pictures, music, preview videos | Storage `content/keepsakes/{asset}`, public and immutable | `staffKeepsakesAsset` | App, portal, renderer |
| Large uploads in flight | Storage `content/keepsakes-incoming/{staff uid}/{name}.{ext}`, staff only, ≤ 50 MB | Portal (the uploading staff member) | `staffKeepsakesAsset`, which deletes it |

## 2. The published document

```jsonc
// publicConfig/keepsakes
{
  "version": "ks_20261013_01",            // label of the release
  "publishedAt": "2026-10-13T03:00:00Z",
  "premium": { "access": "everyone", "badges": true },   // D-068 #8
  "templates": [ /* Template, §3 */ ],
  "music": [ /* Track, §3.1: published ones only */ ]
}
```

`premium.access` takes one of these values:
- `everyone`: Cao cấp templates can be used by anyone (the beta).
- `hidden`: Cao cấp templates are not offered.

A value the app does not know, such as a later `subscribers`, is treated as `hidden`, never as open.
`badges` controls whether "Miễn phí" / "★ Cao cấp" shows on templates.

## 3. A template

| Field | Type | Meaning |
|---|---|---|
| `id` | `card_[a-z0-9_]` / `video_[a-z0-9_]` | Stable. It never changes once published |
| `version` | int ≥ 1 | Assigned by the server on publish. Same content keeps the number; any change gets the next one; numbers are never reused |
| `kind` | `card` \| `video` | |
| `status` | `published` \| `draft` \| `archived` | Only `published` reaches the app. `draft` = hidden while being made |
| `tier` | `free` \| `premium` | Badge and access, under `premium.access` |
| `order` | 0–999 | Display order (smaller first) |
| `name`, `description` | `{vi, en}` | `description` may be null |
| `occasions` | occasion ids, §6 | Empty = every occasion |
| `ageDays` | `{min, max}` \| null | Suggested for babies this many days old |
| `layouts` | `{portrait?, square?, story?: Layer[]}` | **Cards**. The formats offered are the keys present. Null for videos |
| `composition` | `FirstMonth` \| `FirstWeek` \| `HundredDays` \| `LittleMoments` | **Videos**: the Remotion composition (`keepsakeCompositions`; the portal shows a list). Null for cards |
| `assets` | `{role: asset}` | **Videos**: e.g. `{"music": "lullaby_1a2b3c4d.m4a"}` |
| `photos` | `{min, max}` | Cards use 1 today; videos use their scene count |
| `scenes` | `[{hint {vi,en}, optional}]` | Videos: one per photo slot |
| `texts` | `[{key: quote\|title\|message, default {vi,en}, max}]` | Editable texts and their defaults |
| `palette` | `{background, ink, accent}` (`#RRGGBB`) | The template's colours |
| `palettes` | list of palettes | The choices under "Màu" (first = `palette`) |
| `durationSec` | int \| null | Videos only |
| `thumb` | asset \| null | Picture for lists |
| `defaultMusic` | track id \| null | **Videos**: the Thư viện nhạc track played unless the parent picks another (MM07). A published template may only name a published track. Null for cards |
| `preview` | `.mp4` asset \| null | **Videos**: a real video of the template, made from licensed sample photos, played by "Xem mẫu". Null: the app plays the composition with sample pictures (§10) |

### 3.1 A track (Thư viện nhạc)

| Field | Type | Meaning |
|---|---|---|
| `id` | `music_[a-z0-9_]` | Stable; what templates and jobs refer to |
| `title` | `{vi, en}` | Shown in MM07's "Nhạc nền" sheet |
| `artist` | string | May be empty |
| `mood` | `gentle` \| `happy` \| `warm` \| `playful` | For staff; the app shows nothing for it yet |
| `durationSec` | int | Shown as m:ss |
| `asset` | `.mp3` / `.m4a` asset | The file |
| `licence` | `{kind: royaltyFree\|licensed\|original, source, reference, expiresOn}` | Required for a published track (source and reference not empty). Never published to the app |
| `status` | `published` \| `draft` \| `archived` | Only `published` tracks reach the app |
| `order` | 0–999 | Display order |

A parent's choice is sent as `musicId` with `requestMemoryStory`:
- left out: the template's `defaultMusic` (or the template's own `assets.music` when it has none);
- a track id: that track, which must still be published (else `music-unavailable`);
- `null`: no music.

The job stores the chosen `musicId`; the render uses the track's file.

## 4. A card: layers

A format is a list of layers drawn **in order** (the first is at the back).

The coordinate rules are the same for every layer:
- **Rect** `{x, y, w, h}`: fractions of the card. `x`, `w` are fractions of its width; `y`, `h` are
  fractions of its height. `0,0` is the top-left corner. Values may go slightly outside 0–1 to bleed.
- **Sizes**: text size, corner radius and outline thickness are fractions of the **card width**, so a card
  looks the same at any size, from a 54 px thumbnail to the 2160 px export.
- **Colours**:
  - `"background"`, `"ink"` or `"accent"` take the slot from the palette chosen under "Màu".
  - `#RRGGBB` or `#RRGGBBAA` (alpha last) is fixed and does not change with "Màu".
- **Format sizes**:

  | Format | Aspect | Export |
  |---|---|---|
  | `portrait` | 4:5 | 2160 × 2700 |
  | `square` | 1:1 | 2160 × 2160 |
  | `story` | 9:16 | 2160 × 3840 |

### 4.1 The five primitives

**`background`**: the whole card.

```json
{ "type": "background", "color": "background", "asset": null }
```

The colour fills the card. `asset` (optional) is a picture drawn over it, `cover`-fitted.

**`photo`**: the parent's photo. The parent taps to change it, drags to position it and pinches to zoom.

```json
{ "type": "photo", "slot": 0, "rect": {"x":0.19,"y":0.08,"w":0.62,"h":0.496}, "shape": "circle", "radius": 0 }
```

- `shape: circle` gives an ellipse in the rect.
- `rect` with `radius` gives rounded corners.
- The photo always covers its slot. The parent's position and zoom are kept with the card.

**`text`**: text filled in by the app.

```json
{ "type": "text", "field": "occasion", "rect": {"x":0,"y":0.606,"w":1,"h":0.17},
  "font": "beVietnamPro", "weight": 700, "size": 0.164, "color": "accent",
  "opacity": 1, "align": "center", "italic": false, "maxLines": 1 }
```

| `field` | Shows | Example |
|---|---|---|
| `occasion` | The big words of the occasion | 1 tháng · 100 ngày · 1 tuổi · Lần đầu cười |
| `name` | The baby's nickname | Teddy |
| `date` | The occasion's day, `dd.MM.yyyy` | 17.10.2026 |
| `nameDate` | Name · date | Teddy · 17.10.2026 |
| `quote` | The message ("Lời nhắn"), shown in quotes | “Một tháng yêu thương” |
| `title` | The template name | Tròn trịa |

- Text starts at the top of its rect.
- `align` is `left`, `center` or `right`.
- `maxLines: 1` never wraps: a long name shrinks to fit the rect. Over 1 line it wraps and ends with "…".
- An empty value draws nothing. Without a `quote` layer, the editor hides "Lời nhắn".
- Line height is 1.25 × size.
- Fonts are bundled in the app:

  | `font` | Weights |
  |---|---|
  | `beVietnamPro` | 400, 500, 600, 700 |
  | `lora` | 400, 600; italic |
  | `dancingScript` | 400, 600 |

  A missing weight falls back to the nearest one.

**`shape`**: blocks, scrims, rings, decorative stars.

```json
{ "type": "shape", "shape": "rect", "rect": {"x":0,"y":0.45,"w":1,"h":0.55},
  "color": "#00000000", "gradientTo": "#00000099", "radius": 0, "stroke": 0 }
```

- `shape` is `rect`, `circle` or `star` (five points).
- `stroke: 0` fills the shape. `stroke > 0` draws only the outline, at that thickness.
- `gradientTo` makes a top-to-bottom gradient from `color` (filled `rect` and `circle` only).

**`image`**: an uploaded picture, such as a frame, sticker or texture.

```json
{ "type": "image", "asset": "frame-pink_1a2b3c4d.webp", "rect": {"x":0,"y":0,"w":1,"h":1},
  "fit": "contain", "opacity": 1 }
```

- `fit` is `cover` (fill and crop), `contain` (fit inside) or `fill` (stretch).
- Transparency is kept.
- If a picture cannot be loaded, it is left out (in the portal preview it is outlined in red).

### 4.2 A full example ("Tròn trịa", Dọc 4:5, from Figma MM11)

```json
[
  { "type": "background", "color": "background", "asset": null },
  { "type": "photo", "slot": 0, "rect": {"x":0.19,"y":0.08,"w":0.62,"h":0.496}, "shape": "circle", "radius": 0 },
  { "type": "text", "field": "occasion", "rect": {"x":0,"y":0.606,"w":1,"h":0.17}, "font": "beVietnamPro", "weight": 700, "size": 0.164, "color": "accent", "opacity": 1, "align": "center", "italic": false, "maxLines": 1 },
  { "type": "text", "field": "name", "rect": {"x":0,"y":0.7725,"w":1,"h":0.08}, "font": "beVietnamPro", "weight": 600, "size": 0.064, "color": "ink", "opacity": 1, "align": "center", "italic": false, "maxLines": 1 },
  { "type": "text", "field": "date", "rect": {"x":0,"y":0.8464,"w":1,"h":0.07}, "font": "beVietnamPro", "weight": 500, "size": 0.052, "color": "ink", "opacity": 0.6, "align": "center", "italic": false, "maxLines": 1 },
  { "type": "text", "field": "quote", "rect": {"x":0.06,"y":0.912,"w":0.88,"h":0.08}, "font": "beVietnamPro", "weight": 600, "size": 0.052, "color": "accent", "opacity": 1, "align": "center", "italic": false, "maxLines": 2 },
  { "type": "shape", "shape": "star", "rect": {"x":0.86,"y":0.04,"w":0.064,"h":0.08}, "color": "accent", "gradientTo": null, "radius": 0, "stroke": 0.006 }
]
```

### 4.3 From a Figma frame to layers

1. Draw the card in a frame of 250 × 312.5 (Dọc), 250 × 250 (Vuông) or 250 × 444.4 (Story).
2. For each element, divide by the frame:
   - x ÷ 250, w ÷ 250;
   - y ÷ height, h ÷ height;
   - font size ÷ 250, corner radius ÷ 250.
3. Export anything that is not a photo, text or plain shape (frames, illustrations, textures) as a PNG with
   a transparent background. Upload it under Thư viện and use its name in an `image` (or `background`)
   layer.
4. Put the photo, the texts and the shapes in as layers, back to front.

## 5. Assets

- **Name**: `{name}_{8-hex hash}.{webp|mp3|m4a|mp4}`, e.g. `frame-pink_1a2b3c4d.webp`.
  - Uploading the same file again gives the same name.
  - A file is never overwritten, so a published version always draws the same way.
- **Pictures**: PNG, JPEG or WebP, ≤ 8 MB. Stored as WebP at most 2160 px wide, with transparency kept.
- **Music**: MP3 or M4A, stored as is.
- **Preview videos**: MP4, stored as is.
- **Size**: pictures ≤ 8 MB, sent inline. Music, video and pictures over ~5.6 MB go first to
  `content/keepsakes-incoming/{uid}/` (≤ 50 MB, staff only, own folder) and are then checked and moved by
  `staffKeepsakesAsset` with `{name, incoming}`; the server reads the file type from its bytes.
- **Path**: `content/keepsakes/{asset}`, public. This is template artwork only, never a child's media.
- **Checks**: a draft cannot be saved while it names an asset that is not uploaded. Cards may use pictures
  only.

## 6. Occasions (MM10 "Chọn dịp")

| id | Chip | Date | Milestone on the saved memory |
|---|---|---|---|
| `d7` | 7 ngày | DOB + 7 days | `p_seven_days` |
| `m1` | 1 tháng | DOB + 1 month | `p_one_month` |
| `d100` | 100 ngày | DOB + 100 days | `p_hundred_days` |
| `first_smile` | Lần đầu cười | Newest memory tagged with it, else today | `p_first_smile` |
| `rolls_over` | Lần đầu biết lẫy | as above | `p_rolls_over` |
| `crawls` | Biết bò | as above | `p_crawls` |
| `first_steps` | Bước đi đầu tiên | as above | `p_first_steps` |
| `y1` | Sinh nhật 1 tuổi | DOB + 12 months | `p_first_birthday` |

## 7. What a saved card records

The card is saved through the usual upload, as a JPEG ≤ 4096 px. The memory and its item keep:

```json
"generated": { "kind": "card", "templateId": "card_round", "templateVersion": 2, "occasion": "m1", "format": "portrait" }
```

The server refuses the save (`template-unavailable`) when:
- the template is not a published card;
- the version is newer than the published one;
- the template is Cao cấp while Cao cấp is hidden.

An older version still on a phone is accepted. The image is the result: it is never redrawn by a later
version.

## 8. Compatibility rules (why no release is needed)

1. **Unknown fields are ignored** by the app, so the portal can add a field ahead of the app.
2. **An unknown layer type**, or a layer missing a required field, **hides that format**. A template with
   no format left is hidden. An older app never draws a newer template wrongly; it just does not offer it.
3. **An unknown `premium.access`** means hidden.
4. **An unknown occasion id** in `occasions` is ignored.
5. **Changes reach phones** on the next read of `publicConfig/keepsakes`. Firestore keeps the last
   catalog offline.
6. **Portal preview and app use the same rules** (§4). Any change to a primitive must be made in both
   renderers, and in the schema, together.

## 9. What does need code

| Wish | Needs |
|---|---|
| A new layer type or option (rotation, shadow, blend, curved text, filters) | Schema + app renderer + portal preview, and an app release. Older apps hide templates that use it (rule 2) |
| Several photos in one card | App editor (pick N photos). The schema already allows `slot` 0–29 |
| A new font | Bundle it in the app, then an app release |
| A new text field (weight, height, free text) | Schema + app (where the value comes from) + preview |
| A new occasion | Contracts list + app list, then an app release |
| A new video motion | Add the name to `keepsakeCompositions` and a composition in `apps/renderer` (one test checks they match). Deploy the renderer (`scripts/deploy-renderer.sh`), the preview page (`hosting:player`), functions and the portal. No app release: the template's preview and render both come from the renderer code |

## 10. Video previews

Each video template can be played on the phone before it is used ("Xem mẫu"), and the parent's own choices can be
played before "Tạo video" ("Xem trước" on MM07). Both use the renderer's compositions with `@remotion/player` on the
preview page (`apps/renderer/player`, Hosting target `player`), in a WebView.

- **Xem mẫu** plays the template's `preview` MP4 when the portal has one (a real export with licensed
  sample photos and its default track). Otherwise it plays the composition with sample illustrations
  served by the page.
- **Xem trước** uses the chosen photos, passed from the phone as data URLs. They never leave the phone.
- **What the app sends:** the composition name and the same props the renderer gets:
  - photos, title, message, name, date line, mark;
  - the palette as `#RRGGBB`;
  - the music URL (the chosen or default track, a public template asset);
  - `durationSec`.
