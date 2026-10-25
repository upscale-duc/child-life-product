# Assets (rev 2)

All nodes below are in the Figma file `sJLG1fAXKDnDr9YI6Yx8ex`.

## Brand

| Asset | Node | Export | Notes |
|---|---|---|---|
| Logo / Lockup Horizontal · Color | `35:181` | SVG | Used in PI05 and PI10 |
| Color variables | Collection "Color" (Light) | Tokens | cloud, ink, ink-muted, mint, mint-deep, sunshine(-soft), peach-soft, care/* |
| Font | Be Vietnam Pro 500/600 | Google Fonts | OFL |
| Accent/Thread, Accent/Sun, Accent/SunHalo | Built in code from `threadPath` | SVG | The motif comes from the journey path in the website hero |
| Lumi button | `628:9074` (Chat/Nút trợ lý) | SVG/PNG | PI07 |

## Real UI

Every UI image below is a copy; the source designs were left untouched.

| Layer | Source node | Export | Notes |
|---|---|---|---|
| UICrop/HomNay_BuBinh | `273:950`, area x18 y175 w166 h152 | PNG @2x | PI05, PI06 |
| UICrop/HomNay_NhacNho | `273:879`, area x16 y640 w343 h80 | PNG @2x | PI05 |
| UICrop/Widget | `76:5441` (W1 Home screen), area x14 y60 w365 h168 | PNG @2x | PI06 |
| AppScreen/AppleWatch | `475:4588` | PNG @2x | PI06 |
| Card/Siri | Built in code (orb + 2 lines of text) | — | PI06. ⚠ Confirm Siri ships |
| Card/BanGiao | in `825:16921` (App/HomNayV2) | PNG @3x | PI06. ⚠ Confirm it is in the release build |
| Card/Member/Me, CoLan | `116:11310`, `116:11327` | PNG @3x | PI06 |
| UICrop/Lumi_Drafts | `613:7807` (CH04), area y84–684; "Chat/Mức dùng" is hidden | PNG @2x | PI07 |
| Card/GoiYHomNay, List/NhacViec | in `825:16921` | PNG @3x | PI07 |
| Card/GrowthChart | `346:47820` | PNG @2x + SVG line `346:47846` | PI08. Assessment labels are hidden |
| Card/Milestone | parts of `311:1436` | PNG @2x | PI08. Photos replaced (smile, motherbaby) |
| UICrop/Album_CaNha | `188:472`, area y0–440. Title changed to "Cả nhà mình" and cover photo replaced (family) | PNG @2x | PI08 |
| Card/Thiep | `531:9389` (MM12) | PNG @2x | PI09. ⚠ Check whether it is Free or Premium |
| Card/VideoPreview | `530:9437` (MM09) | PNG @2x | PI09. ⚠ Check the export quota |

## Photo audit (rev 2)

**Why the photos changed:** the earlier set came from Wikimedia, and several did not fit the story.

- The dad-and-newborn photo was dark, with a loud floral blanket.
- The album cover was a teddy bear and basket with no people, which does not say "family".
- The smiling baby was in a nappy, too close.
- Some photos needed CC BY attribution.

**New set:** all from **StockSnap via Openverse, all CC0** (no attribution required). They share a warm, soft palette.

| Key | Content | Author | Link | Used in |
|---|---|---|---|---|
| newborn | Newborn asleep in a striped hat | Candace McDaniel | stocksnap.io/photo/baby-newborn-ILUIZBPPTT | PI01, PI10 |
| toddler | Toddler on the beach | Luke Michael | stocksnap.io/photo/sea-ocean-AG33MQ8DB5 | PI01, PI10 |
| child3 | Child drawing at a table | Direct Media | stocksnap.io/photo/child-homework-GV5GIEXDBA | PI01 |
| child6 | Mother and child reading in the sun | Ben White | stocksnap.io/photo/sunlight-sunshine-XDNPCSL1U2 | PI01, PI10 |
| motherbaby | Mother holding baby, sibling hugging them | Direct Media | stocksnap.io/photo/mother-child-BNAI6KA86B | PI02, PI03, PI08 |
| smile | Baby smiling next to mum | Direct Media | stocksnap.io/photo/mother-joy-JURGOKWYHI | PI04, PI05, PI08 |
| feeding | Bottle feeding | Andrew Branch | stocksnap.io/photo/people-mother-E7EZ2CWZE5 | PI06 |
| father | Dad holding newborn on the sofa | Andrew Branch | stocksnap.io/photo/people-father-838KMHXY7F | PI06 |
| family | Family playing together | Direct Media | stocksnap.io/photo/family-playing-AJU8ODUJSV | PI08 (album cover) |
| basket | Newborn in a basket | Freestocks.org | stocksnap.io/photo/child-baby-WWBJ9TUT2B | PI09 |
| foot | Baby's foot | Studio 7042 | stocksnap.io/photo/small-baby-FKXNHWCQJK | PI09 |
| feet | Baby feet in a parent's hands | Bonnie Kittle | stocksnap.io/photo/hands-feet-CX86NMD6C1 | PI09 |
| sleepbed | Baby sleeping in bed | Dakota Corbin | stocksnap.io/photo/bedroom-bed-CDO5RB87O1 | PI09 |
| walk | Child walking with an adult | Freestocks.org | stocksnap.io/photo/young-girl-C0WTUJ65SZ | Spare |

⚠ The copies in Figma are **960px previews**. Before rendering, download the full-size files from the StockSnap links (about 4000px). The CC0 license needs no attribution, but brand-owned photos are still recommended for ads.

## Missing or to confirm

- The final VO: casting and a recording.
- A licensed music track.
- Full-resolution photos, or brand-owned photos with model releases.
- English versions of the Today, album and card/video screens, if the UI should match the English VO.
- Product sign-off on the flagged claims in `script.en.md`: Siri, the handoff card, free keepsakes, and approval of the proposed PI01/06/07 lines.
- Release status for the CTA ("Coming soon to iPhone & Android", following the website).
- The YouTube reference video could not be watched.
