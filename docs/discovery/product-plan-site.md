# Product plan website (child-life-product-plan.arcanetoast.chatgpt.site) — extracted 2026-10-10

## Vision
Private space around the child's profile: co-parent care coordination, photos/videos/stories, share with family, look back on growth — without social media.
Reduce "when did baby last feed, who changed the diaper?"; turn scattered photos/videos into a reviewable growth journal.
- Ba mẹ: less to remember — latest status, quick log, co-manage profile & memories.
- Người chăm: clear coordination — log activity, see history, reminders; handover without messaging.
- Người thân: close despite distance — view shared content, react (thả thương), follow the journey.
Care focus first on newborns / under 1 year. Memories not age-locked; tracker not mandatory. No pressure to log everything.

## V1 scope (= entire current Figma)
- Care & stats: bottle, breastfeeding, pumping, sleep, diaper, growth. Quick log, timer, history, edit, filters. Feed/sleep stats, day–night ratio, charts, reminders.
- Memories & albums: photo, video, notes, milestones. Timeline, all photos, albums, favorites, multi-select. Share by permission, download, queue, background upload.
- Growth story: AI drafts from saved content. Edit text/photos, add milestones, reorder blocks, preview. Save, photo card, private link and revoke.
- Family & roles: invite via link, code, QR; enter immediately, save account later. Co-parent, caregiver, relative; extra view permissions. Role-based UI, member management, baby selection.
- Profile & storage: multiple babies, timezone, tracking choices. Personal profile, account, baby profile management. 10 GB shared per family, near-full/full, contact admin.
- Daily experience: Light / Night care and per-activity colors. Widget, lock screen, Dynamic Island; add from Photos app. Notifications, wait-for-Wi-Fi, offline and resync.

## Business rules
| Role | Main permissions |
|---|---|
| Cùng nuôi / ba mẹ | Co-manage care, profile, memories; invite, adjust permissions, choose shared content. |
| Người chăm sóc | Log/view care for assigned baby, view & mark reminders done. Edit only own records. Cannot see Memories, full profile, storage. |
| Người thân | View "Gia đình" memories, react (thương), private favorites, download photos; no editing. Parents can grant extra view of baby info or daily care. |

- Baby profile & care: data and permissions per baby. Relationship label separate from role. Switching baby switches data and permissions. Bottle = volume, breast = time; pumping not added to baby's intake. Timer, stats and sync must avoid duplicates/data loss.
- Sharing & album permissions: "Chỉ ba mẹ" and "Gia đình" are two view scopes. Changing "Ai thấy album" applies to items in album; photos added later follow album permission. Notify family with one generic notification without the photo. Deleting album ≠ deleting memories. Item in multiple albums needs a clear rule so permissions aren't unintentionally widened.
- Story & private link: AI creates draft; parents edit & preview before saving. Share only after saving, only allowed sources, never invent events. Link expiry 24h, 7d or 30d; options hide name/DOB, allow photo download, 4-digit passcode. View count and revoke. Downloaded cards cannot be revoked.
- Storage, background upload & offline: 10 GB shared for family, babies, and content parents upload; view by baby/type; contact admin to expand. Pending-sync records and upload queue have real status and retry. Video waits for Wi-Fi; re-check permissions before publishing. Widget, extension and background upload must be verified per OS.

## Development (business model before schema)
| Concept | Meaning |
|---|---|
| Identity & membership | Account = one person; permissions come from membership per baby. Relationship ("Bà/Bảo mẫu") separate from role. Enter-now-then-save-account must not lose permissions or records. |
| Family & baby profile | Family = 10 GB shared quota scope; each baby has profile, timezone, permitted people and own data. Decide family/profile owner in schema design. |
| Records & timer | Activity type, time, recorder, measurement. Timer = running session; on stop creates record exactly once. Stats are computed from records, not separately entered. |
| Memory & media | Memory has date, caption, milestone, creator, view scope; can attach photos/videos. Files, upload progress and processing are separate resources, not equal to memory being published. |
| Album & story | Album organizes items and applies permissions per Figma. Story = blocks + source memories; save draft, save post, create card and share are different actions. |
| Reminder & sharing | Reminder has due time and done state. Invitation grants membership; story link only grants viewing selected content, not membership. |

Flows:
- A Join family & permission change: choose relationship/role → create invite → accept → enter now or save account → see role-correct UI. Permissions and expiry checked server-side. Changing permission/removing member updates access; records they created are kept. Acceptance: expired invite, re-accept, wrong person, lost permission, temporary identity → account.
- B Care, timer & chart: choose baby → quick log or timer → save → update Today/history → update stats. Caregiver edits only own records. Bottle/breast/pump distinct units/meaning. Day 06:00–18:00, night 18:00–06:00 in baby's timezone. Acceptance: double save, two loggers, date/timezone change, offline. On overlapping sleep, let user choose correct one or edit manually per Figma; never auto-merge/overwrite.
- C Reminders & notifications: content/date-time/advance notice → save shared reminder → schedule LOCAL notification → mark done or edit. Anyone permitted sees reminders in-app; notification only scheduled on the device that created the reminder. Denying notification permission doesn't lose the saved reminder. Acceptance: overdue, edit/cancel, notifications off, baby timezone change. Do NOT auto-push to all devices instead of this.
- D Upload, album & family notify: pick files → date/milestone/album/who sees → queue → validate/process → publish → notify family if enabled. Shared quota; video waits for Wi-Fi, photos may use cellular. Distinguish retryable errors vs corrupt files. Notify family when upload completes, avoid duplicates on retry. Acceptance: app killed, network drop, quota full, partial upload, permission changed during processing. Album permission change updates items/later photos per Figma.
- E Story AI, card & private link: choose allowed sources → create/edit draft → arrange blocks → preview and save → share within family or externally. Only parents have external sharing; default hide real name/DOB. Link has expiry, optional passcode, download, view count, revoke. Acceptance: source deleted/made private, AI failure, link expired/revoked/wrong passcode. Source and render must both comply with permissions; downloaded card irrevocable.
- F Storage & delete baby profile: view usage by baby/type → contact admin to expand; profile owner types baby name to permanently delete. Only profile owner can delete. Care, media and stories of that baby deleted for whole family; never other babies' data. Acceptance: revoke access, purge files/sources/derived links, return quota. Failed job must resume; never report "deleted" while data remains.

Dependency order: 01 Foundation (dev/prod, design system, identity, baby profile, permissions; one real user flow app→Firebase) → 02 Care (records/timer → history/sync → stats/reminders; correct data before charts & widgets) → 03 Memories (quota/permissions → upload & media processing → timeline/album; spike video, background upload, share extension early) → 04 Story (media sources ready → AI/editor → save/card → link & recipient web; don't build sharing on uncontrolled sources) → 05 Completion (all Figma flows, native integration, landing/portal, data deletion, operations; full test both OS). Parallel branches allowed after data/permission contracts stabilize. Not a scope cut or time commitment.

Discovery questions: who owns family/profile, whose quota with multiple co-parents, what happens when they leave? Item in multiple albums with different permissions: final permission and feedback on change? When is AI draft initiated, sources, limits/storage? Auto-save drafts? Partial batch failure: when published/family notified? Native features differ iOS vs Android how? Portal: who is it for, what actions? How far does Figma describe account deletion, temp identity recovery, shared data?

Versions: V1 = Figma final, scope locked 09.10.2026, "design locked, implementation completion not confirmed". V2 undefined.
