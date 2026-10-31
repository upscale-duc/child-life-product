# 02 · Feature inventory (Phase 0)

Snapshot 2026-10-31 at `e60e569b`. This is the **seed** for the Product Hub feature registry, not
the registry itself: Phase 1 turns each row into a reviewed record (see
[05](05-data-architecture.md)). Paths are repository-relative. Nothing here was checked on a
device or against dev Firebase.

## Evidence levels

Four separate fields, never collapsed into one status (brief §5.2):

| Field | Values used here |
|---|---|
| **Lifecycle** | `planned` · `designed` · `in_development` · `built` · `deprecated` |
| **Implementation** | `implemented` (main flow in code, client + server) · `partial` (part of the intended capability) · `not_found` (searched entry points, modules, contracts) |
| **Verification** | `code_read` (Phase 0 read the code; tests exist) · `tests_listed` (tests exist, not re-run in Phase 0) · `unverified` · `device_verified` (none yet — needs dev Firebase, iOS + Android, Light + Night, per `figma-coverage-checklist.md`) |
| **Release** | `not_released` for every feature: the app is pre-launch (D-147) |

**Tier** = default tier in code (`featureCatalogue` in `packages/contracts/src/features-hub.ts`)
or the capability in `entitlements.ts`. The live tier lives in `config/features` on each project
and can differ; Phase 0 did not read it. "—" = no catalogue entry; the feature is reached through a
free capability (`module.basic`, `moments.basic`, `health.guidance`, `history.read`, …).

**Confidence** (H/M/L): how sure Phase 0 is that the row's *implementation* claim is right.

Feature ids are proposals (`pillar.slug`); where a hub `FeatureKey` exists it is kept as the
`hubKey` so entitlements join without a mapping table.

## Care

| Id | Feature | Mobile module | Backend | Tier / entitlement | Lifecycle · Impl. · Verif. | Conf. | Key docs / decisions |
|---|---|---|---|---|---|---|---|
| `care.feeding` | Feeding: bottle, breastfeeding, pumping (quick log, timer, edit) | `features/care` (`care_sheets.dart`, `timer_screens.dart`, `bottle_suggestions.dart`) | `care.ts`; client writes `babies/{b}/records` under Rules | — (`module.basic`) | built · implemented · tests_listed (`care_calc_test`, `care_flow*`) | H | business-map §7.3–7.4; pumping ≠ intake (plan site) |
| `care.sleep` | Sleep log, timer, overlap handling, ambient sound | `features/care` (`timer_*`, `sleep_ambient.dart`) | `care.ts`, `conflicts` | — | built · implemented · tests_listed | H | §7.4; never auto-merge overlaps |
| `care.diaper` | Diaper log | `features/care` | records | — | built · implemented · tests_listed | H | §7.3 |
| `care.history_stats` | History, filters, day/night stats, charts | `features/care` (`history_screen.dart`, `stats_screens.dart`, `stacked_days_chart.dart`) | computed from records | — (`history.read`) | built · implemented · tests_listed | H | §7.5; night 18:00–06:00 (R-086, D-151 #1) |
| `care.reminders` | Shared reminders, local notifications, rule reminders, all-day/assignee | `features/reminders` | `reminder-rules.ts`, `vaccine-reminders.ts` | — | built · implemented · tests_listed (`rule_reminders_test`, `try_reminders_test`) | H | §6.4, §7.6; `reminders-allday-assignee-plan.md` |
| `care.care_plan` | Cùng Chăm Con: shared day plan, shifts, handover, report | `features/care_plan` (13 files) | `care-plan*.ts`, `care-duty.ts`, `handover-send.ts` | — (handover summary uses AI credits, D-075) | in_development · implemented · tests_listed (`care_duty_test`, goldens `care_plan*`) | M | D-137 (must match Figma `1349:22026`); D-13x Cùng Chăm Con answers |
| `care.vaccines` | Vaccination book, schedule by country, overdue, reminders | `features/vaccines` | `vaccine-reminders.ts`, `reference-data.ts` | — (`health.guidance`) | built · implemented · tests_listed (`vaccine_test`, goldens `vx`) | H | `vaccination-plan.md`, `vaccines-by-country.md` |
| `care.first_aid` | First-aid guides (reviewed content) | `features/first_aid` | `content.ts`; `publicConfig/content_firstAid` | — | built · implemented · tests_listed | H | `first-aid-plan.md`; D-058 two-person publish |
| `care.nutrition` | Nutrition by stage | `features/nutrition` | `content-nutrition.ts` | — | built · implemented · tests_listed | H | `nutrition-plan.md`, D-083 |
| `care.solids` | Solids: foods, recipes, guides, diary, family | `features/solids` | `content-solids.ts`; `meals` | — | built · implemented · tests_listed | H | `solids-plan.md`, D-085 |
| `care.spending` | Baby spending, currency, import | `features/spending` | client + `spending-import` contracts | — | built · implemented · tests_listed | M | `spending-*-plan.md`; kept out of Lumi chat (D-075 #2) |
| `care.visit_report` | Doctor-visit report from records | `features/care/visit_report.dart` | — | — | built · partial? · unverified | L | goldens `visit`; no plan doc found |
| `care.family_roles` | Family, invites (link/code/QR), roles per baby, member management | `features/family` | `family.ts`, `babies.ts` | — | built · implemented · code_read (+ emulator tests per product-audit 01) | H | §2.1, §5, §6.1, §7.2 |
| `care.utilities` | Care utilities tab | `features/utilities` | — | — | built · implemented · unverified | L | figma-extract `21-care-utilities-tabs.md` |

## Grow

| Id | Feature | Mobile module | Backend | Tier / entitlement | Lifecycle · Impl. · Verif. | Conf. | Key docs / decisions |
|---|---|---|---|---|---|---|---|
| `grow.growth` | Growth log, WHO charts, standards screen | `features/care` (`growth_chart.dart`, `who_growth*.dart`) | `reference-data.ts`; `who-reference.g.ts` | — | built · implemented · tests_listed | H | §7.5 |
| `grow.milestones` | Milestones, link to Moment and card | `features/milestones` | `content-milestones.ts` | — | built · implemented · tests_listed | H | product-audit 01 (link best-effort/race) |
| `grow.rhythm` | Nhịp lớn lên: reference calendar, check-in | `features/rhythm` (38 files) | `rhythm-content.ts` | hubKey `rhythm` · Free · `wonder.reference`, `rhythm.checkin` | built · implemented · tests_listed (`rhythm_*_test`) | H | D-148, D-152 (1–3 y pack published) |
| `grow.personalization` | Cross-module suggestions, advanced rhythm, "Gợi ý cho hôm nay" | `features/rhythm`, `features/today` | `personalization-v2.ts`, `personalization-*.ts` | hubKey `personalization` · Premium · `personalization.cross_module`, `rhythm.advanced` | built · implemented · tests_listed | H | `personalization-v2-plan.md`, D-153 (Free → Premium invite) |
| `grow.insights` | Hiểu con: "Điều đáng chú ý" card + screen | `features/insights` | `insights.ts` | Premium (D-150) — **gated by `rhythm.advanced`**, i.e. by the `personalization` tier | in_development · implemented · tests_listed (`insights_test`) | M | D-150, D-151; `hieu-con-insights-analysis.md` |
| `grow.daily_suggestion` | Gợi ý mỗi ngày (engagement) | `features/engagement` | `engagement*.ts`; `daily-suggestion` contract | flags `engagement*` | built · implemented · tests_listed | M | D-152 (silent for older children) |
| `grow.stages` | Giai đoạn của bé (stage content) | `features/library` / stage screens | `content.ts`; `contentStages` | — | built · implemented · tests_listed | M | D-076; buckets to 36 months only |
| `grow.library` | Thư viện chăm bé (articles, readability, intl) | `features/library` | `content-library.ts` | — | built · implemented · tests_listed (`library_*_test`) | H | `library-readability-intl-plan.md` |

## Remember

| Id | Feature | Mobile module | Backend | Tier / entitlement | Lifecycle · Impl. · Verif. | Conf. | Key docs / decisions |
|---|---|---|---|---|---|---|---|
| `remember.moments` | Memories timeline: photo, video, note, milestone tag, audience | `features/memories` | `memories.ts`; `memories`, `media` | — (`moments.basic`) | built · implemented · code_read | H | §7.9; D-001, D-002 |
| `remember.upload` | Upload queue, background upload, Wi-Fi wait, quota | `features/memories` (`upload_queue.dart`, `background_uploads.dart`) + native | `memories.ts`, `quota.ts`, `video-*.ts` | flags `media_upload`, `video_upload` | built · implemented · code_read | H | §6.5, P-170; 10 GB per family |
| `remember.albums` | Albums, reactions, favourites, family messages | `features/memories` (`album_*`, `social_widgets.dart`, `messages_screen.dart`) | `albums.ts`, social | — | built · implemented · tests_listed (album Rules) | H | D-002 (most permissive wins) |
| `remember.share_extension` | Add from Photos / Android share target | `ios/share`, `share_inbox.dart` | upload path | — | built · implemented · unverified (per-OS) | M | D-004 |
| `remember.auto_save` | Tự lưu kỷ niệm: on-device face match, suggestions | `features/auto_save` (11 files) | local PhotoKit/Vision; `featureAccess` | hubKey `auto_save` · Beta · flag `auto_save` | built · implemented · tests_listed (3 suites) | H | D-066, P-148, `auto-save-plan.md`; iOS only |
| `remember.milestone_cards` | Thiệp cột mốc | `features/keepsakes` (`milestone_card_screens.dart`) | `keepsake-content.ts` | hubKey `milestone_cards` · Beta | built · implemented · tests_listed | H | D-068 #3 |
| `remember.memory_video` | Video kỷ niệm (Remotion render on Cloud Run) | `features/keepsakes` (`memory_story_screens.dart`) | `keepsake-jobs.ts`, `video-quota.ts`, `apps/renderer` | hubKey `memory_story` · Beta · `render.video` (every plan, own quota) | built · implemented · tests_listed (renderer 24) | M | D-068; product-audit 01 (P0 file fencing) |
| `remember.premium_templates` | Mẫu Cao cấp / Premium48 | `features/premium` (`premium48_*`), `features/keepsakes` | `keepsakes-premium48*.ts` | hubKey `templates_premium` · Premium · `templates.premium` | in_development · partial · tests_listed | M | `remember-2-templates.md`, premium48 phase reviews |
| `remember.stories` | Story (article) with AI drafts and paragraph assist | `features/stories` | `stories.ts`, `ai.ts` | hubKey `ai_story_drafts` · Beta | built · implemented · tests_listed | M | D-003 (≤ 3 drafts / baby / week) |
| `remember.share_links` | Private story link (expiry, passcode, revoke) | `features/stories` | `links.ts`, `pages.ts` | flag `story_share_link` | built · implemented · tests_listed | M | §7.13 |
| `remember.print_studio` | Print Studio (print moments) | `features/print_studio` (15 files) | `print-studio.ts`, `print-render.ts` | — | in_development · implemented · tests_listed (`print_studio_test`) | M | `print-studio-plan.md`, figma-extract 42 |
| `remember.letter` | Thư của con (per-reader letter) | **not found** | not found | — | designed · not_found · — | M | D-149 (approved), no module found by name search |

## Intelligence & platform

| Id | Feature | Mobile module | Backend | Tier / entitlement | Lifecycle · Impl. · Verif. | Conf. | Key docs / decisions |
|---|---|---|---|---|---|---|---|
| `platform.lumi` | Lumi assistant: chat, logging, reads, images, care guidance, timers | `features/assistant` (19 files, ~20 k lines) | `assistant*.ts` (~35 files) | hubKey `assistant` · Premium tier with credits (Free uses Free budget, D-075 #1) | built · implemented · tests_listed (fake suite; live runs per `lumi-live-test-cost`) | H | `docs/assistant/*`, `lumi-plan.md`, D-075, D-145, D-146 |
| `platform.lumi_voice` | Voice input to Lumi | `features/assistant/assistant_voice.dart` | assistant | as Lumi | built · implemented · unverified | M | — |
| `platform.ai_summaries` | AI summaries: handover, explain, moment | `features/ai` | `ai-summary.ts` | hubKey `ai_assist` · Premium tier, open within credits · `ai.assistance` | built · implemented · tests_listed (`ai_summary_test`) | H | D-075 #1, P-151 |
| `platform.adaptive_today` | Adaptive Today and navigation | `features/adaptive`, `features/today`, `features/home` | `adaptive` contract | — | built · implemented · tests_listed (`adaptive_*_test`) | H | `adaptive-experience-plan.md`, figma-extract 40 |
| `platform.notifications` | Notification inbox, smart engagement, templates | `features/notifications`, `features/engagement` | `notification-*.ts`, `engagement*.ts` | flags `engagement*` | built · implemented · tests_listed | H | `docs/notifications/*` (00–09), P-174 |
| `platform.widgets_live` | Home/lock widgets, Live Activities (timer, upload, keepsake), Android Glance | `ios/widget` (`LockAndLive.swift`, `UploadLive.swift`, `KeepsakeLive.swift`), `features/glance` | — | flag `lock_widgets` | built · implemented · unverified (per-OS) | M | §7.8, D-004 |
| `platform.watch` | Apple Watch app | `ios/watch` | `WatchLink.swift` | — | in_development · partial · unverified | L | `apple-watch-plan.md`, figma-extract 23 |
| `platform.premium` | Premium plans, paywall, purchase, invites, grants, beta | `features/premium` | `billing.ts`, `entitlements.ts`, `premium-v2.ts`, `premium-ops.ts` | defines the tiers | built · implemented · code_read; store purchase not live | H | D-089, D-147, `premium-v2-plan.md` |
| `platform.onboarding` | Onboarding, sign-in, baby profile | `features/onboarding`, `features/auth`, `features/baby` | `babies.ts`, `auth-mail.ts` | — | built · implemented · tests_listed | H | §7.1 |
| `platform.account_storage` | Me, account, storage use, export, deletion | `features/me` | `account.ts`, `quota.ts`, `export-download.ts` | — | built · implemented · code_read | M | §6.2, §7.11 |
| `platform.app_update` | Forced / soft app update | `features/app_update` | `app-update.ts` | — | built · implemented · tests_listed | H | `docs/development/app-updates.md` |
| `platform.feedback` | Feedback and rating | `features/feedback` | `feedback.ts` | — | built · implemented · tests_listed | H | figma-extract 26 |
| `platform.appearance` | Light / Night care, auto night | `features/appearance` | — | flag `night_auto` | built · implemented · unverified | M | §7.1 |
| `platform.offline_sync` | Offline, pending sync, retry | cross-cutting | — | — | built · partial? · unverified | L | §7.7 |
| `platform.product_analytics` | Private product observations | `features/analytics` | `product-analytics*.ts` | flag `product_analytics` | built · implemented · tests_listed | H | `docs/product-analytics/*` |

**Out of scope for the catalog** (internal tools, not product features): staff portal, landing
site, launch film, renderer service as a deliverable, QA personas (D-152), diagnostics,
showcase.

## Checklist items from the brief that were **not** found as separate features

| Brief item | Finding |
|---|---|
| Health Records | No separate module; covered by vaccines, growth, visit report, first aid |
| Developmental Guidance | Covered by stages, library, milestones and Nhịp content |
| Photo Albums / Memory Templates | Present (`remember.albums`, `remember.milestone_cards`, `remember.premium_templates`) |
| Voice Journaling | Only voice **input to Lumi** found; no voice-journal feature |
| Family Sharing (as a plan) | Family roles exist; no "family plan" SKU found — Premium is per household |
| Chapters CH02–CH04 | Product audit 05 finds chapters partially implemented (content to 36 months); CH02–04 marketed on landing only |

## Known cross-feature dependencies worth showing on day one

- `grow.insights` is Premium **because** it checks `rhythm.advanced`, which belongs to the
  `personalization` hub feature. Changing the `personalization` tier silently changes Hiểu con.
- `platform.ai_summaries`, `care.care_plan` handover and `platform.lumi` share **one credit
  pool** per household (D-075 #1).
- `remember.memory_video` is open to every plan but limited by `render.video` quota, while its
  rollout is the `memory_story` flag.
- `remember.milestone_cards` depends on `grow.milestones` (milestone → moment link).
- `grow.personalization` and `platform.adaptive_today` both feed Hôm nay; D-153 decides what a
  Free household sees there.

## Totals (for the Overview tiles, once reviewed)

| Pillar | Features | of which hub-catalogue (tierable) |
|---|---:|---:|
| Care | 14 | 0 |
| Grow | 8 | 2 |
| Remember | 12 | 5 |
| Intelligence & platform | 15 | 2 |
| **Total** | **49** | **9** |

Default tiers in code: Free 1 (`rhythm`), Premium 4 (`personalization`, `ai_assist`, `assistant`,
`templates_premium`), Beta 4 (`milestone_cards`, `memory_story`, `auto_save`, `ai_story_drafts`);
the other 40 features have no tier and use free capabilities. Hiểu con is Premium by decision
(D-150) through `rhythm.advanced`.
