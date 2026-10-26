# Terminology glossary (vi / en)

Built from `apps/mobile/lib/l10n/app_vi.arb` and `app_en.arb` on 2026-10-25 (6,097 keys, full
parity), plus `docs/product/business-map.md`, the product docs and the landing content. Counts are
word-boundary matches across all strings.

## Two independent status dimensions

| Implementation (`Impl.`) | Meaning |
|---|---|
| **Implemented** | Exists in the current application (code / ARB) |
| **Approved / Planned** | Approved in a product decision or roadmap, not yet built |
| **Proposed** | Suggested (a design, a proposal doc, engineering), not approved |
| **Deprecated** | Retired or superseded |
| **Verify** | The sources disagree or are ambiguous; check with the owner before relying on it |

| Terminology (`Term`) | Meaning |
|---|---|
| **Verified** | The established wording; use it |
| **Recommended** | Preferred among existing variants; use it for new copy, migrate when touched |
| **Owner decision** | Changing or adopting it needs explicit owner approval (`senior-ui-ux` §3) |

The two are independent: a feature can be *Approved / Planned* with *Verified* wording, or
*Implemented* with wording that is an *Owner decision*. **Absence from Flutter or ARB doesn't
mean a feature is unapproved:** check `business-map.md` (D-, R-, P-, Q- entries) and the product
docs.

**Never silently rename an established product concept.** When you meet a variant:

1. document it;
2. say what's ambiguous;
3. recommend a pair and why;
4. mark it owner decision if it is canonical.

## 1. Navigation and places

| Concept | vi | en | Context | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|---|
| Today tab | Hôm nay | Today | Tab, title | — | Implemented | Verified | `tabToday`, `todayTitle` |
| Memories tab | Kỷ niệm | Memories | Tab | Avoid en "Moments" for the tab | Implemented | Verified | `tabMemories` |
| Care tab / hub | Chăm sóc | Care | Tab v1, hub title | — | Implemented | Verified | `tabCare`, `careTitle` |
| Utilities tab | Tiện ích | Utilities | Tab v1 | — | Implemented | Verified | `tabUtilities` |
| Explore tab (NavBar v2) | Khám phá | Explore | Adaptive nav (P-178) | — | Implemented (flagged) | Verified | `tabExplore` |
| Profile tab (NavBar v2) | Hồ sơ | Profile | Adaptive nav | — | Implemented (flagged) | Verified | `tabProfile` |
| Me | Tôi | Me | Header avatar → account | — | Implemented | Verified | `tabMe`, `a11yOpenMe` |
| Family | Gia đình | Family | Screen, audience option | Avoid "Nhà" as a screen name | Implemented | Verified | `tabFamily`, `audFamily` |
| Settings | Cài đặt | Settings | Links into settings | Avoid "Thiết lập", "Cấu hình" | Implemented | Verified | `remindersOpenSettings` |
| Notifications inbox | Thông báo | Notifications | Bell, inbox | — | Implemented | Verified | `ntInboxTitle` |
| Growth | Tăng trưởng | Growth | Tracker, care hub | — | Implemented | Verified | `trackerGrowth`, `careGrowth` |

## 2. Care tracking

| Concept | vi | en | Preferred usage / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| Feeding (category) | Bú | Feeding (category) · Feeds (counted, filter) | "Bú" for the category; en "Feeding" as a category name, "feeds" when counted. Avoid mixing "Feeds" / "Feeding" for one filter | Implemented | Recommended | `filterFeed` "Feeds", `ruleTypeFeed` "Feeding" |
| One feed | cữ bú | a feed | "Ghi cữ bú" / "Log a feed". Avoid "cữ ăn" for milk ("ăn" is solids) | Implemented | Verified | `feedSheetTitle`, `emptyFeedWhat` |
| Bottle / Breastfeeding | Bú bình / Bú mẹ | Bottle / Breastfeeding | — | Implemented | Verified | `trackerBottle`, `trackerBreast` |
| Sleep | Ngủ · giấc ngủ | Sleep | "Ghi giấc ngủ" / "Log sleep" | Implemented | Verified | `sleepChooserTitle` |
| Diaper | Tã (category) · Thay tã (action, tracker) | Diaper · Diaper change | Avoid en "Diapers" vs "Diaper" in one view | Implemented | Verified | `trackerDiaper`, `legendDiaper`, `diaperTitle` |
| Pumping | Hút sữa | Pumping | "Ghi hút sữa" / "Log pumping" | Implemented | Verified | `trackerPump`, `pumpTitle` |
| Solids | Ăn dặm | Solids | Avoid "Weaning" | Implemented | Verified | `careSolids` |
| To log (verb) | Ghi | Log | "Ghi" for the act, "Lưu" for saving a form. Avoid "Ghi lại", "Ghi nhận" as a button | Implemented | Verified | `logNow`, `savedToast` |
| Quick log | Ghi nhanh | Quick log | — | Implemented | Verified | `quickLogTitle` |
| A logged item (noun) | **ghi nhận** (88) · bản ghi (19) · nhật ký (65) · ghi chép (25) | log (130) · note (106) · record (39) · entry (8) | Recommended: vi "ghi nhận" for a care item, "nhật ký" for the Memories journal; en "log" for care items, "note" only for written notes | Implemented | **Owner decision** (canonical, ~70 strings) | `aiStateStaleTitle`, `offlineBanner`, `careSaveFailed` |
| History / Statistics | Lịch sử / Thống kê | History / Statistics · stats | — | Implemented | Verified | `careHistory`, `careStats`, `feedStatsTitle` |
| Daily care | Chăm sóc hằng ngày (4) · Chăm hằng ngày (2) | Daily care | "Chăm sóc hằng ngày" for the permission; "Chăm hằng ngày" only as the compact hub group label (D-069) | Implemented | Recommended | `rightDailyCare`, `careDaily` |
| Reminders | **nhắc việc** (56) · nhắc nhở (9) | Reminder(s) | Recommended: "Nhắc việc" (the list, the channel and "Nhắc việc mới" use it); the screen title is "Nhắc nhở" | Implemented | **Owner decision** (screen title) | `remindersTitle`, `reminderNew`, `notifChannel` |

## 3. Growth and development

| Concept | vi | en | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| Milestones (area) | Mốc phát triển | Milestones | Avoid "Cột mốc" for the area | Implemented | Verified | `careMilestones` |
| A milestone | mốc | milestone | — | Implemented | Verified | `composeMilestone` |
| Measurement | số đo | measurement | Avoid "chỉ số" | Implemented | Verified | `saveGrowth` |
| Age | `{age}` via `ageLong` / `ageShort` | — | Never hand-build ages | Implemented | Verified | `lib/core/format/age.dart` |
| Wonder Weeks | Wonder Weeks | Wonder Weeks | Don't translate the brand | Implemented | Verified | `careWonderWeek` |
| Rhythm | Nhịp ("Nhịp lớn lên"); "nhịp ngủ" | rhythm | Avoid "Nhịp" alone where it could mean the product or the pattern | Implemented | Verified | `sleepRhythm`, D-102 |

## 4. Memories

| Concept | vi | en | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| Memories (the space) | Kỷ niệm | Memories | Avoid en "Moments" for the feature | Implemented | Verified | `tabMemories` |
| One memory | kỷ niệm | memory | — | Implemented | Verified | `quickMemory` |
| Moments (common noun) | khoảnh khắc | moments | en "moments" only as a common noun, not the feature (`rhIntMoments`, `pmPlanExpiredBody` use it as the feature) | Implemented | Recommended | `rhIntMoments` |
| Journal / Album / Stories | Nhật ký / Album / Câu chuyện | Journal / Album(s) / Stories | — | Implemented | Verified | `memJournal`, `memAlbums`, `memStories` |
| Milestone cards (UI name) | Thiệp cột mốc | Milestone cards | The user-facing name | Implemented | Verified | `ksCardTitle` |
| **Milestone Magic** | — | — | **Internal / product-doc name** for the milestone-card family (`docs/product-audit/01-current-product-inventory.md` "Thiệp/Milestone Magic"; `docs/product/remember-2-templates.md`, a template spec whose status is "proposal for owner review"). Not a UI string. Don't put it in UI unless the owner adopts it | Implemented (cards); the doc's new templates are Proposed | **Owner decision** (as a UI name) | product-audit 01, 02, 07; remember-2 |
| Memory video (UI name) | Video kỷ niệm | Memory video (feature) · Keepsake video (in export quota) | Recommended en: "Memory video"; avoid two names | Implemented | Recommended | `ksVideoTitle`, `asVideoQuotaTitle` |
| **Memory Story** | — | — | **Internal / product-doc name** for the memory-video feature (Remotion jobs, `keepsake-jobs.ts`; product-audit 00, 01, 07, 13, 15, 16; remember-2 §5). Not a UI string; the UI says "Video kỷ niệm" / "Memory video" | Implemented (feature) | **Owner decision** (as a UI name) | product-audit; remember-2 |
| Printed keepsakes | Kỷ vật | Keepsakes | — | Implemented | Verified | `psTab` |
| Who sees | Ai thấy | Who sees | — | Implemented | Verified | `composeWho` |

## 5. AI and personalisation

| Concept | vi | en | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| The assistant | **Lumi** (29) · Trợ lý (14) · Trợ lý Child Life · AI (63) | Lumi · the assistant · AI | Recommended: "Lumi" for the character; "AI" only where the technology matters (consent, privacy, availability). "Trợ lý Child Life" as a title is a candidate to retire | Implemented | **Owner decision** (`asEntryTitle`, `spFromAssistant`) | `asLumiName`, `asLumiIntroTitle` |
| Lumi credit | credit | credit(s) | "credit" for Lumi; "lượt" for video exports (D-101: Q-099 … Q-104 "credit for Lumi, lượt for video") | Implemented | Verified | `pv2CreditsLeft`, D-101 |
| Older AI usage label | Lượt hỗ trợ AI | AI help | Conflicts with D-101's "credit for Lumi" | Implemented | **Owner decision** | `asUsageTitle` |
| Handover | Bàn giao | Handover | — | Implemented | Verified | `aiHandoverTitle`, D-103 |
| AI summaries (consent) | Tóm tắt bằng AI | AI summaries | — | Implemented | Verified | `aiConsentTitle` |
| Smart suggestions | Gợi ý thông minh | Smart suggestions | "Smart Engagement" is the internal name (`docs/notifications/04-smart-engagement.md`); never in UI | Implemented | Verified | `engTitle` |
| Daily suggestion | Gợi ý mỗi ngày | Daily suggestion | — | Implemented | Verified | `engLumi`, D-099 |
| Personalisation | Cá nhân hoá | Personalization (US) / Personalisation (UK) | Spelling follows the UK / US decision | Implemented | Recommended (spelling: Owner decision) | `rhPersonalize` |

## 6. Subscription

| Concept | vi | en | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| Free plan | Miễn phí | Free | Avoid "Gói cơ bản" as a plan name | Implemented | Verified | `pmPlanAlwaysFree`, D-101 |
| Premium | Premium | Premium | The app's single paid plan (Free \| Premium) | Implemented (Premium v2: IAP later) | Verified | D-101, `pmBadgePremium` |
| **Plus / Pro** | — | — | Tiers appear **only** in the landing-site Lumi page design (Figma `650:4798`: "Free · Plus · Pro", 30 / 300 / 1,000 credits, prices; R-170). Q-039 records that they **conflict with the app's single Premium**. Pricing Q-071 is **Open**. The landing code deliberately doesn't ship them (`apps/landing/src/content/vi.ts`: "the plans … are not the app's single Premium plan"). D-101 (newest) keeps Free \| Premium. **Never use in app copy** | **Verify** (designed for the landing, not approved for the app; D-101 points the other way) | **Owner decision** | R-170, Q-039, Q-071, D-101 |
| Plan | gói | plan | — | Implemented | Verified | `pmPlanTitle` |
| Household / owner | hộ · chủ hộ | household · family owner | vi "hộ" sits next to "gia đình"; en mixes household and family | Implemented | **Owner decision** | `pmPlanTitle`, `pmPlanOwnerOnly` |
| Video exports | Lượt xuất video | Video exports | — | Implemented | Verified | `pmQuotaTitle`, D-101 |
| Storage | Dung lượng | Storage | — | Implemented | Verified | `meStorage` |
| Expired | Hết hạn · "Premium đã hết hạn" | Ended · Expired | — | Implemented | Verified | `pmPlanExpired` |

## 7. Family and roles

| Concept | vi | en | Preferred / avoid | Impl. | Term | Source |
|---|---|---|---|---|---|---|
| Co-parent | Cùng nuôi | Co-parent | — | Implemented | Verified | `roleCoParent` |
| Caregiver | Người chăm sóc (11) · Người chăm (12) · người cùng chăm (5) | Caregiver | Recommended: "Người chăm sóc" as the role; "người cùng chăm" only in sentences about everyone who helps | Implemented | **Owner decision** (role name) | `roleCaregiver`, `familyInvite` |
| Relative | Người thân | **Family member** (role) · relatives (13) | Recommended: en "Family member" for the role label, "relatives" only in plain sentences | Implemented | **Owner decision** | `roleRelative`, `babyPrivacyNote` |
| Parents | ba mẹ (55) | the parents · parents | Avoid "cha mẹ" (spending only), "bố mẹ" | Implemented | Recommended | — |
| Invite | Mời · Lời mời | Invite · invitation | en "invite" in UI, "invitation" in mail and push | Implemented | Recommended | `joinExpiredTitle`, push templates |
| Access / permissions | Quyền | Access | Avoid "Permission" in UI | Implemented | Verified | `inviteRoleLabel` |

## 8. Common actions (shared keys; reuse them)

| Intent | vi | en | Reuse key |
|---|---|---|---|
| Save | Lưu | Save | `actionSave` |
| Done | Xong | Done | `actionDone` |
| Try again | Thử lại | Try again | `actionRetry` |
| Continue / Next | Tiếp tục / Tiếp | Continue / Next | `actionContinue` (a flow step) / `actionNext` (a pager) |
| Later | Để sau | Later | `actionLater` |
| Skip | Bỏ qua | Skip | `actionSkip` |
| Undo | Hoàn tác | Undo | `undo` |

Duplicates exist (`rhDone`, `fbDone`, `pmDone`, `glanceDone`, `sryUndo`, `glanceUndo` …). New
code reuses the shared key; widget (glance) keys stay separate because native code reads them by
id.

## 9. Technical terms (context-dependent, not banned)

See `ui-copy-patterns.md` §4. Terms such as đồng bộ / sync, ngoại tuyến · offline, sao lưu /
backup, quyền / access, dữ liệu / data, mã hoá / encryption are **Verified** where the technology
*is* the subject:

- sync status details;
- offline storage;
- backups;
- privacy and consent;
- permissions;
- account security;
- troubleshooting and diagnostics.

On everyday surfaces the default is plain wording, but only when the plain wording is equally
accurate.
