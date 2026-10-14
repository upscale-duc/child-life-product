# Apple Watch — review and plan (2026-10-12)

Source: Figma page **"Apple Watch"** `464:18` (W01 – W14), extracted in
`docs/discovery/figma-extract/23-apple-watch.md`. Owner request: "Kế hoạch để làm một số tính năng thao tác
cho nhanh ở apple watch mà ko cần điện thoại … mẹ bỉm sữa rất bận và không phải khi nào cũng cầm điện thoại
được. Hãy phân tích những tính năng nào nên có và lên kế hoạch triển khai."

Status (2026-10-12): **first watch build runs in the simulator.** The `watch` target (`tool/ios_flavors.rb`,
scheme `watch-dev`, sources `apps/mobile/ios/watch/`) has W01 – W06, W11 – W13 and the not-linked screen on
the shared glance kit, checked on Apple Watch Series 11 46 mm / watchOS 26.5 with the debug-only sample data
("Xem thử", launch arguments `-watchDemo`, `-watchRoute`, `-watchAction`, `-watchNight`, `-watchLocale`).
**Not verified yet:** linking with the phone app over WatchConnectivity and real writes to dev Firebase (the
watch app is not embedded in Runner yet), and a real device. Still open: steps 0, 1 and 4 – 8 below.
Engineering defaults below are P-142 (owner to confirm); open questions are Q-047 … Q-053, design gaps
G-092 … G-101 (business map).

## 1. Review: what the design asks for

Two rows, 14 frames at 46 mm (208 × 248 pt), all on black:

| Row | Frames | What it is |
|---|---|---|
| **1 · Ghi nhanh trên cổ tay** (quick logging on the wrist) | W01 Hôm nay · W02 Bú bình · W03 Bú mẹ đang bấm giờ · W04 Ngủ đang ngủ · W05 Thay tã · W06 Đã lưu | A 6-tile home (time since the last bottle / breast / diaper / pump, the running sleep, the next reminder); bottle by Digital Crown + quick picks; breast timer per side with "Đổi bên"; sleep ring with "Bé đã dậy"; diaper in one tap; a saved screen with "Mẹ ghi" and "Hoàn tác". |
| **2 · Không cần mở app** (no need to open the app) | W07 Nhắc bú (notification) · W08 Giọng nói · W09 Complication · W10 Smart Stack · W11 Ban đêm · W12 Chọn bé · W13 Chưa có mạng · W14 Hút sữa (Double Tap) | A feed reminder you answer with "Ghi bú bình 120 ml" or "Nhắc lại sau 15 phút"; "Ghi bú bình 120 ml cho Teddy" by voice with a confirm card; watch-face complications and a Smart Stack card; a dim red night mode; a baby picker; saved-on-watch offline state; a pump timer stopped by pinching twice. |

Not drawn (G-092 … G-101): linking the watch to the account, empty / no-permission states, the start
screens for breast / sleep / pump, the ml entry after pumping, timers started on another device, failures
and sleep overlaps, what the Nhắc tile opens, smaller watches, Always-On, other complication shapes, night
palette tokens, English copy.

## 2. Analysis: which features, in which order

The person we design for has one free hand at best (feeding, rocking, carrying), is often in the dark, and
the phone is charging in another room or buried in a bag. So a watch feature earns its place when it is
**frequent**, takes **≤ 2 taps or no tap at all**, and **works with the phone away**. Everything that needs
reading, typing or deciding stays on the phone.

| # | Feature | Frames | Why it matters | Cost | Wave |
|---|---|---|---|---|---|
| 1 | Link the watch once, then it works on its own | — (G-092) | Prerequisite. Without it nothing below works with the phone away. | M | 1 |
| 2 | **Diaper in one tap** + saved / undo | W05, W06 | The most frequent log (8 – 12 a day for a newborn), and it happens with both hands busy. One tap, a haptic, done. | S | 1 |
| 3 | **Bottle** with the crown and quick picks, prefilled from the last bottle | W02, W06 | Night bottles: one tap on the tile, the usual amount is already there, "Lưu". | S | 1 |
| 4 | **Sleep timer** start / "Bé đã dậy" | W01, W04 | The baby falls asleep on you: you cannot reach the phone without waking them. | S | 1 |
| 5 | **Breast timer** per side, "Đổi bên", "Dừng" | W03 | The one feed that is always hands-busy; per-side minutes are hard to remember afterwards. | M | 1 |
| 6 | **Home with "time since"** for every type, baby picker | W01, W12 | Answers the question parents ask most ("bé bú lúc mấy giờ?") without logging anything. | S | 1 |
| 7 | **Offline on the watch** | W13 | At night the watch is often out of Bluetooth range of the phone and not on Wi-Fi. A lost log is worse than no watch app. | M | 1 |
| 8 | **Night mode** (dim red list) | W11 | Night feeds are the main watch moment; a bright screen wakes the baby and the parent. | S | 1 |
| 9 | **Complication** "time since the last feed" | W09 (circular) | Zero taps: raise the wrist and read it. The highest value per second of any feature here. | M | 1 |
| 10 | Reminder answered on the wrist | W07 | The reminder already reaches the watch (mirrored); adding "Ghi bú bình 120 ml" turns it into a one-tap log. | M | 2 |
| 11 | Rectangular complication + Smart Stack | W09, W10 | Sleep running and the three "time since" values without opening anything. | S | 2 |
| 12 | Pump timer + Double Tap | W14 | Pumping occupies both hands; Double Tap (Series 9+ / Ultra 2) stops it without touching the screen. | S | 2 |
| 13 | Voice log with confirmation | W08 | Hands fully busy. Riskier: Vietnamese speech quality and baby-name matching need a spike first. | M | 3 |

Deliberately **not** on the watch: growth (weight / height), editing or back-dating records, history and
charts, memories and photos, creating reminders, family and roles, spending, vaccination, first aid.

**Proposal beyond the drawn design (owner to confirm, P-142 §8):** use Double Tap as the primary action on
the running breast and sleep timers too ("Dừng" / "Bé đã dậy"), since those are the moments when neither
hand is free. W14 only draws it for pumping.

## 3. What already exists (reuse, not rebuild)

The iPhone widgets already have a **native, Flutter-free care stack** in `apps/mobile/ios/Shared/` (S8):

| Piece | File | What it does | On watchOS |
|---|---|---|---|
| Session | `GlanceAuth.swift` | Keeps the Firebase refresh token in the keychain, exchanges it at `securetoken.googleapis.com` for an ID token | Works (Foundation + Security); needs its own keychain on the watch |
| Writes | `GlanceFirestore.swift` | Firestore REST `:commit` with `REQUEST_TIME` transforms, so the **same Rules** pass (`validNewRecord`, `canLog`, D-022 / D-024); 409 / `FAILED_PRECONDITION` = already done | Works (URLSession only) |
| Actions | `GlanceActions.swift` | `logBottle`, `logDiaper`, `undo` (5 s, soft delete), timer `start` / `end` / `switchSide`; ending uses the ender's uid and author; sleep capped at 24 h | Works once `GlanceLive.sync()` is behind `#if canImport(ActivityKit)` |
| Offline queue | `GlanceStore.swift` | Pending commit bodies in App Group defaults, flushed on the next action / resume; record ids `r_<32 hex>` made on the device so retries never duplicate | Works |
| Snapshot | `GlanceStore.swift` + `lib/features/glance/glance_bridge.dart` | Today for **the selected baby only**, built by Flutter and written to the App Group, with a `copy` dictionary of ARB strings | **Gap:** no Flutter on the watch, and W12 needs every baby |
| Intents | `widget/LogIntents.swift`, `Shared/GlanceIntents.swift` | Log / undo / start / end / switch side; all `isDiscoverable = false` | App Intents run on watchOS 9+; `LiveActivityIntent` is iOS-only |
| Reminder actions | `Runner/RuleNotifications.swift` | `CL_RULE_<TYPE>` categories, `CL_SNOOZE15` / `CL_SKIP` call `answerRuleReminder` over HTTPS natively | Reusable from the watch |

Backend facts the plan relies on: records at `babies/{b}/records/{id}`, shared timers at
`babies/{b}/timers/{sleep|breast|pump}`, rule reminders pushed by `ringRuleReminders` with
`apns-category CL_RULE_<TYPE>` and the title "Đến giờ nhắc bú bạn đã đặt" (exactly W07's title), and a day
summary rebuilt by `onCareRecordWrite`. **No backend change is needed to log from the watch.**

## 4. Architecture decisions

1. **A native SwiftUI watchOS app**, embedded in the iOS app (Flutter does not run on watchOS). Minimum
   **watchOS 10** (Series 4 and later; Smart Stack needs 10). Double Tap needs watchOS 11 on Series 9 / 10 /
   11 or Ultra 2; elsewhere the on-screen button does the same thing. Targets: `watch` (app),
   `watchWidgets` (complications + Smart Stack, WidgetKit), added by `tool/ios_flavors.rb` (never by hand in
   the pbxproj). Bundle ids `<app>.watchkitapp` / `<app>.watchkitapp.widgets`, App Group
   `group.<app>.watch` (the watch has its own container; it cannot read the phone's App Group).
2. **The watch talks to Firebase over HTTPS itself**, never through the phone app. watchOS sends URLSession
   traffic through the paired iPhone over Bluetooth when it is near, otherwise over known Wi-Fi or cellular,
   so one code path covers "phone in the bag", "phone charging in the bedroom" and "LTE watch at the park".
   The Firebase Firestore SDK is **not** used on the watch: watchOS is only community-supported and its gRPC
   transport needs the low-level networking watchOS restricts. The `Shared/Glance*` REST code is exactly the
   right shape and already proven by the widgets.
3. **A shared Swift package `CareKit`** (working name) made from `ios/Shared/Glance*`, used by the iPhone
   app, its widgets and the watch. One implementation of auth, REST, queue, undo, timers and formatting,
   so the watch cannot drift from the widgets.
4. **Reads on the watch go through Rules too**: the watch builds its own snapshot with Firestore REST
   (`runQuery` for the last record of each type per baby, using the existing (`type`, `deleted`,
   `occurredAt` desc) index; `get` of `babies/{b}/timers/*`; a collection-group query on `members` for the
   babies and roles; the `days/{date}` summary). No new server read path and no duplicated permission logic.
   When the phone app is running, it also pushes its fresher snapshot with WatchConnectivity
   (`updateApplicationContext`), which the watch takes if newer. A callable "watch snapshot" is the fallback
   only if the spike shows REST reads are too slow on the wrist (target: home visible < 1.5 s from cache,
   refreshed < 3 s).
5. **Linking (G-092):** the watch shows "Mở Child Life trên iPhone để kết nối" until the phone sends the
   session over WatchConnectivity (`transferUserInfo`: uid, refresh token, environment, locale, author,
   copy). The watch keeps the token in **its own keychain** (`AfterFirstUnlockThisDeviceOnly`, so background
   refresh works while it is locked on the wrist). Phone sign-out or account switch sends a wipe; the watch
   also wipes on any 400 / 401 / 403 from the token endpoint (as `GlanceAuth` does). The watch registers a
   `users/{uid}/devices/{d}` row (platform `watchOS`) so it appears in "Thiết bị đang đăng nhập" and gets a
   heartbeat. Losing access is handled by Rules and R-025 exactly as on the phone.
6. **Offline (W13):** every write goes through the existing pending queue first, the UI updates at once, and
   the queue flushes after each action, on app activation and from background refresh. Timers started
   offline show "Chỉ trên đồng hồ này" (as R-097). A sleep overlap found later is resolved on the phone
   (screen 27); the watch only says "Mở điện thoại để xử lý" (G-097).
7. **Complications and Smart Stack (W09, W10):** WidgetKit in `watchWidgets`, reading the watch App Group
   snapshot. Elapsed times are drawn from timestamps (minute timeline entries or `Text(_, style: .timer)`), so
   they tick without reloads. Reloads: after every watch action, after a background refresh (~30 min), and
   when the phone pushes `transferCurrentComplicationUserInfo`. Updates caused by **another family member**
   while the phone app is closed need WidgetKit push from `onCareRecordWrite` (spike SW-3); until then they
   arrive with the next refresh.
8. **Notifications (W07):** the rule reminder push already reaches the watch (iOS mirrors it when the phone
   is locked, including over Wi-Fi when the phone is in another room). The watch app registers the same
   `CL_RULE_FEED` category with a custom long-look that draws W07 from the cached snapshot ("Cữ trước 14:45 ·
   120 ml") and sets its actions dynamically: **"Ghi bú bình {ml} ml"** (logs the last amount through
   `CareKit`) and **"Nhắc lại sau 15 phút"** (the existing `CL_SNOOZE15` → `answerRuleReminder`). The amount
   stays out of the push payload (R-120 spirit; the server copy is unchanged). If iOS hands the action to the
   iPhone instead (SW-2), the same `CareKit` handler runs natively in `RuleNotifications.swift`, so either
   path logs without opening Flutter. A watch that is alone (phone switched off) gets no reminder in v1; a
   direct APNs token for the watch can follow with the SP-1 APNs work.
9. **Voice (W08):** App Intents in `CareKit` (`LogBottle(amount, baby)`, `LogDiaper(kind, baby)`,
   `StartSleep`, `EndSleep`, `StartBreast(side)`), exposed as **App Shortcuts** with vi and en phrases, and
   a mic button on W01 that uses system dictation with a small local parser ("bú bình 120", "một trăm hai
   mươi ml", "tã ướt", "bé dậy rồi", baby names). Every voice log shows the W08 confirm card; nothing is
   saved on a guess. Classic Siri has spoken Vietnamese since iOS 18.4; watchOS support and accuracy are
   checked in SW-4 before building.
10. **Strings (D-012):** a `tool/watch_strings.py` script adds the `watch*` ids to both ARB files (vi
    template, en engineering draft) and writes `ios/watch/Localizable.xcstrings`, as `s8_widget_strings.py`
    does for the widgets. vi / en parity tests then cover the watch.
11. **Night (W11):** the watch follows the same rule as the app (`resolvePalette`): inside the night
    schedule (default 21:00 – 06:00, sent from the phone) or while a sleep timer runs, it switches to the
    dim red list. W11's red is not a token yet: add `watch-night-*` to `packages/design-tokens/tokens.json`
    (G-100), and generate the Swift colours from that file.
12. **Privacy:** the watch logs nothing about the child and has no analytics SDK; crash reports carry
    environment and app version only (as the app). The circular complication never shows a name; the
    rectangular one and Smart Stack show the nickname as drawn, pending Q-049.

## 5. Engineering defaults (P-142, owner to confirm)

1. **Who:** Cùng nuôi and Người chăm sóc log from the watch with the same rights as the app (D-022). The
   watch lists only babies the user can log for; a user who can log for none sees "Đồng hồ dùng để ghi chăm
   sóc. Bạn chưa có bé nào để ghi." (G-093). Relatives do not use the watch app.
2. **Time:** every watch log is "now". Back-dating and editing stay on the phone.
3. **Saved / undo (W06):** shown for 5 s with "Hoàn tác" (the widget window, R-100w), then back to W01.
   Undo is the app's soft delete (30-day bin); undoing a timer end deletes the record and does not restart
   the timer (as the app).
4. **Bottle (W02):** opens prefilled with this baby's last bottle amount and milk type (default
   `breastMilk` like the app, not the widget's `formula` default); crown step 10 ml, 10 – 500 ml (contract
   limits 1 – 500); quick picks from the age table (`publicConfig/reference_bottle`, P-138), the middle one
   preselected when there is no last bottle.
5. **Breast (W03):** the tile opens a start screen with "Trái" / "Phải", the side opposite the last feed
   highlighted (G-094); while running, W03; "Dừng" saves at once. Pause stays on the phone (W03 draws none).
6. **Sleep (W04):** when no sleep runs, tapping Ngủ starts it at once and opens W04: the running clock is
   the confirmation (the green check is only for a finished log, owner 2026-10-12); for 5 s W04 also shows
   "Hoàn tác", which cancels the timer. Running timers (sleep, breast) show h:mm:ss ticking every second
   ("0:09:23", owner 2026-10-12), always with the hour so they never read like the h:mm "2:15" of the other
   tiles; h:mm on the Always-On screen.
7. **Pump (W14):** start with "Cả hai bên" preselected (W14), "Một bên" as the second choice; "Dừng · nhập
   ml" opens W02's layout in the pump colour; pumping stays out of intake (D-026).
8. **Double Tap:** the primary action on W03 ("Dừng"), W04 ("Bé đã dậy") and W14 ("Dừng · nhập ml"), with
   the hint pill on each. (Proposal: W14 only draws it for pumping.)
9. **Nhắc tile:** shows the next rule or one-off reminder for the baby; tapping it opens a read-only list of
   today's next reminders (G-099). Reminders are created on the phone.
10. **Timers started elsewhere:** the watch shows and can end any family timer (the shared
    `babies/{b}/timers` document). The record is written as the person who ends it.
11. **Rectangular complication "cữ bú tiếp ~ 17:00"** is the next feed reminder time, never a prediction
    (calm, no inference); the line is hidden when there is no reminder (Q-050).

## 6. Build steps (each one committed and pushed)

| Step | Content | Estimate |
|---|---|---|
| 0 · Spikes on the owner's iPhone + Watch | **SW-1** link over WatchConnectivity, token refresh and a REST `:commit` through Rules from the watch with the phone off (Wi-Fi) and in Bluetooth range; **SW-2** where a W07 action is delivered (watch app or iPhone) and dynamic action titles; **SW-3** complication refresh when another member logs (WidgetKit push vs background refresh, budgets); **SW-4** Vietnamese Siri App Shortcut on watchOS and dictation accuracy; **SW-5** signing of the watch targets under the interim team (D-045): App Group, keychain, push | 3 – 4 days |
| 1 · CareKit package | Move `ios/Shared/Glance*` into a Swift package used by Runner, `widgetExtension` and the watch; `#if` around ActivityKit; snapshot built natively from REST reads for **all** babies (also unblocks multi-baby widgets); XCTest for the REST codec, queue, undo, timers, parser, with fixtures shared with `packages/contracts` tests | 4 – 5 days |
| 2 · Targets and linking | `tool/ios_flavors.rb` adds `watch` + `watchWidgets` for dev / prod; Swift environment resolution that refuses mixed config (as `resolveEnvironment`); WatchConnectivity on both sides; link / wipe; device row; `tool/watch_strings.py` | 2 – 3 days |
| 3 · Wave 1 screens | W01, W12, W05 + W06, W02, W04, W03, W13, W11; haptics, crown, Always-On (minute updates, no ring motion), VoiceOver labels, largest text, 41 / 42 / 45 / 46 / 49 mm layouts | 6 – 8 days |
| 4 · Complications | W09 circular + rectangular, corner and inline engineering-supplied (G-098), W10 Smart Stack, relevance while a sleep runs | 3 – 4 days |
| 5 · Notifications | W07 long-look, dynamic actions, log and snooze from the wrist, the iPhone fallback in `RuleNotifications.swift` | 2 – 3 days |
| 6 · Pump + Double Tap | W14, pump ml entry, Double Tap on W03 / W04 / W14 | 2 days |
| 7 · Voice | App Shortcuts (vi / en), dictation + parser, W08 confirm | 3 – 4 days (after SW-4) |
| 8 · Device QA | watchOS 10 / 11 / 26; phone near / phone off on Wi-Fi / airplane mode then back; two members logging at once; timers across watch ↔ phone; night; vi / en; deploy nothing to prod | 3 days |

About **6 – 7 weeks for one engineer** end to end; Wave 1 alone (steps 0 – 4) about **4 weeks**. Wear OS is
not included (Q-048).

**Dependencies and risks.** Real devices: an Apple Watch paired with the owner's iPhone is required from
step 0 (Bluetooth proxy, Double Tap, complications and notification hand-off cannot be tested in the
simulator). Signing: until the Child Life Apple account exists, the watch targets sign under D-045; prod
stays unsigned. A sleep started on the watch shows as a Live Activity on family iPhones only once SP-1
push-to-start lands; the watch itself does not depend on it. While planning, a bug turned up in the app:
ending a timer someone else started is refused by Rules because the record keeps the starter as author
(`timer_models.dart` `toRecord`); it was flagged as a separate task and must be fixed before step 3.

## 7. Coverage checklist

When step 3 starts, add a "7 · Apple Watch" section to `figma-coverage-checklist.md` with rows W01 – W14.
A row is done only when it works end to end on dev Firebase on a real watch, in normal and night mode,
with code and test paths filled in. There is no Android column for these rows unless Q-048 asks for Wear OS.

## 8. Open questions for the owner

| ID | Question | Engineering default |
|---|---|---|
| Q-047 | Priority: build the watch now (Wave 1 first), or after the remaining S8 widget / Live Activity work? | Wave 1 now; it shares CareKit with S8, so both move forward |
| Q-048 | Wear OS: D-004 makes Android mirror iOS designs. Does that include a Wear OS app? | Not in V1; Android watches get the mirrored phone notifications |
| Q-049 | W09 / W10 show the baby's nickname on the watch face, which is always visible, unlike the generic lock screen (R-116, R-120). Keep it? | As drawn; circular and inline never show it |
| Q-050 | "cữ bú tiếp ~ 17:00" (W09): the next feed reminder, or an estimate from the usual interval? | Next reminder only; hidden without one |
| Q-051 | Should caregivers with an expiry date (accessUntilAt) be allowed to link a watch? | Yes, while their access lasts |
| Q-052 | Voice: Siri phrases, an in-app mic, or both? | Both, always with the W08 confirm card |
| Q-053 | Minimum watchOS 10 (Series 4 +) acceptable? | Yes |
