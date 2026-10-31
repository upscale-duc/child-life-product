# Premium v2: review and plan (2026-10-25)

**Sources:**
- Figma page **"Premium v2"** `958:13863`, extracted in `docs/discovery/figma-extract/41-premium-v2.md` with screenshots in `img/pv/`. It covers PV00 / PV00B / PV00C, E01–E14, PW01–PW10, PV30–PV33, PV40–PV45 and PT01–PT04.
- A survey of the code as it stands (see §3).

**Owner, 2026-10-25:** "in app purchase sẽ làm sau". The store payment (PV30–PV33, the App Store / Play SDKs and receipt verification) is out of scope. Everything else is in.

**Superseded:** PV00B names this page as the current design, replacing the earlier Premium page (P/L/M/F/B), v2.0 PR01–PR04 and the website V8 plans. Where it disagrees with D-0xx decisions, §5 lists each conflict for the owner.

---

## 1. What the design asks for (PM / PO view)

**Goal (PV00B):** a Free family makes its first video, tries Lumi on its own child's data, buys Premium, continues exactly what it was doing, and gets the next memory draft. Success is measured by the family coming back to make the next thing, not by sign-ups.

### 1.1 Plans and limits (PV00, the "one source" for app, backend, website and portal)

| | Free | Premium |
|---|---|---|
| Lumi credit | 30, **one time** | 200 / month (refilled on the subscription day, no carry-over) |
| Video exports | 2, **one time** | 4 / month |
| Templates | basic; premium ones can be previewed | all |
| Storage | **1 GB** | 10 GB, plus a +20 GB or +50 GB add-on (Premium only) |
| Caregiver seats (members who can write) | 3 | 6 |
| Relatives (view Kỷ niệm) | unlimited, no seat | unlimited, no seat |
| Care, growth, health | full, never blocked | full |
| Price | 0 | 59.000đ / month · 599.000đ / year ($5,99 / $49,99) |
| Add-ons | — | +20 GB 39.000đ / 399.000đ · +50 GB 79.000đ / 799.000đ |
| Credits for sale | never | never ("credit đi theo gói") |

Every value has a config key: `lumiCredits`, `videoExports`, `premiumTemplates`, `storageGB`, `storageAddOns`, `caregiverSeats`, `price.*` and `creditTopUps`. The config is **versioned** ("2.0-launch") and a change needs **two approvers** (PT03).

### 1.2 Rules that shape every screen

- **One plan per family.** The buyer is the **manager**, the only person who sees price, payment, change and cancel. Members see the shared limits and their own history (PV45). A member who is not the manager gets "Nhờ {người quản lý} nâng cấp" (PW07).
- **Shared pools.** Lumi credit and video exports are shared by the family. Lumi works as hold → debit on success → refund on error, with an idempotency key. One video export unit is used per *successful* export; preview and re-exporting the same version are free.
- **Premium lives inside the job, not in a separate area** (PV00B).
  - A suggestion appears only when the user touches a Premium thing. It is never shown on app open, during onboarding or on Hôm nay.
  - There are no crowns or locks; the existing "Cao cấp" badge is the only marker.
  - Every suggestion offers a **free alternative**: the free template, direct logging, cleaning up storage, or inviting someone as a relative.
- **One paywall for everything**, opened on the card the entry needs and tagged "Bạn đang cần". After purchase the user **returns to the same screen with the choices kept**.
- **Downgrade deletes nothing** (PV42–PV44).
  - Over the storage limit, new uploads are blocked and queued; viewing, download and export always work.
  - Over the seat limit, the **manager chooses who keeps write access**; the others become view-only and are never removed, and there is no silent default.
  - Premium drafts are kept, and exported videos are always kept.
- **Commercial views carry no content:** no chat, no health data, anonymous ids (PV00 footer, PT01–PT04).

### 1.3 Entry points (PV00C)

| Entry | Existing screen | Trigger | Paywall | Returns to |
|---|---|---|---|---|
| E01 | MM04 video templates | Free family taps a Cao cấp template | PW01 Video | MM07 with the template and photos kept |
| E02 | MM10 card templates | Cao cấp card template | PW02 Thiệp | MM11 editor |
| E03 | MM07 "Tạo video" | Free trial exports used (Premium out of its 4: information only) | PW01 | MM08 |
| E04 | MM15 "Làm tiếp" | Draft on a premium template after downgrade | PW01 | MM07 with the draft |
| E05 / E06 | CH20 / CH21 Lumi | Not enough / no credit (Free) | PW03 Lumi | CH23, the question continues |
| E07 | CH24 Lumi (Premium) | 200 used | **no paywall**, information sheet | CH24 |
| E08 / E09 | 13c / 13d storage (Premium) | ≥ 80 % / full | PW10 add-on | 13b; the queue resumes |
| E10 / E11 | 13f Kỷ niệm upload, AS18 Tự lưu (Free) | 1 GB full | PW04 Dung lượng | 13f / AS12; resumes |
| E12 | 14a Gia đình invite | Seats full | PW05 Người chăm sóc | 14a; the invite continues |
| E13 | 13a Tôi | always (proactive card) | PW06 Khám phá | 13a / Gói của gia đình |
| E14 | any of the above | viewer is not the manager | PW07 Nhờ người quản lý | origin |

### 1.4 Success measures (PV00B "Chỉ số")

These are the existing MET-01 measures plus the new ones, with no content in any of them:
- task completion, time to complete and abandonment;
- upgrades by entry;
- **coming back to make the next keepsake**;
- serving cost per family (AI, render and storage, with p95);
- how often families run out of quota (PT01 "Hạn mức & mua thêm").

---

## 2. UX analysis: gaps and conflicts found

The extraction lists 33 open questions (§ Open questions). The ones that change behaviour are below, each with a recommendation; they are mirrored as Q-095 … Q-104.

| # | Issue | Recommendation |
|---|---|---|
| 1 | **Free storage drops from 10 GB (R-040, today) to 1 GB.** Existing Free families above 1 GB would be over the limit on day one | **Grandfather:** families created before the v2.0 launch keep their current Free storage; new families get 1 GB. Ask the owner (Q-095) |
| 2 | Free Lumi changes from 20 / month (P-159, live) to 30 one-time; video from 1 / month to 2 one-time; Premium video from 5 to 4 | Apply PV00 from launch; every existing Free family starts with a fresh 30 / 2, and past use is not counted (Q-096) |
| 3 | **Seat limits are new**, and some families may already have more than 3 writers | Existing families keep every current member; the limit applies to new invites only, and the picker (PV44) appears only after a downgrade (Q-097) |
| 4 | PV00 shows the cost on the button ("Nhìn lại 7 ngày · 5 credit") and the balance in the Lumi header, but D-081 keeps credit numbers off main screens | Follow PV00: it is newer and supersedes D-081 for Lumi only (Q-098) |
| 5 | E05 / E06 copy still says "20 lượt · làm mới 01/11" and mixes "lượt" with "credit" | Use **"credit"** for Lumi and **"lượt"** for video. Free says "trải nghiệm một lần", never "làm mới" (Q-099) |
| 6 | E08 / E09: PV00C sends a Premium family to PW10, but the notes say PW04 | **PW10** for Premium (it sells the add-on), PW04 for Free |
| 7 | PV40B offers "Mua thêm dung lượng" to a Free family, although add-ons are Premium-only | A Free family's row opens **PW04** (Premium first); the add-on is Premium-only as PV00 says |
| 8 | Mid-cycle upgrade "⚑ cần chốt" | Free → Premium grants the full 200 / 4 at once; unused Free trial is not carried over (Q-100) |
| 9 | When the seat picker runs, and what happens before the manager chooses | Offered at the downgrade (PV43). Until the manager chooses, **everyone keeps write access**, so nobody is cut off silently; a reminder is sent once (Q-101) |
| 10 | PT02 compensates a failed video with Lumi credit; PT04 shows a job failed 3 / 3 that still holds its unit | Compensation uses the **same unit**. Auto-release after 3 failed attempts (today the unit is already released on failure) |
| 11 | No PW09 / E14 screen; E14 is the PW07 rule | PW07 is the non-manager variant of *every* paywall |
| 12 | "Không có khu Premium riêng" (PV00B) vs D-089's hub | No conflict: D-089 is the portal hub; the app gets no Premium tab, only PW06 from Tôi |
| 13 | Missing states: offline, Night care for E05–E13 / PV40–PV45 / PW, English, the relative and view-only caregiver views, a Premium family at 4 / 4 videos or 6 / 6 seats | Engineering supplies them with the same components (G-111) |
| 14 | Portal version labels clash (v1.3 running, v2.0-draft / 2.0-launch) | Keep versions as an immutable `config/entitlements/versions/{id}` plus a running pointer (§4.4) |

---

## 3. What exists today (code survey, 2026-10-25)

**Already in place:**
- **Entitlements** (`packages/contracts/src/entitlements.ts`): capabilities, `resolveCapability` with the gate order and the only paywall reason (PREMIUM_REQUIRED), and server-written family grants (`paid | beta | promo`; `billingOwnerUid`).
- **Household plans:** free / beta / premium / pending / expired.
- **Config:** `config/entitlements` with video quota (Free 1 / month, Premium 5 / period), assistant credits (Free 20 / Premium 200) and beta campaigns.
- **Ledgers** (`packages/contracts/src/quota.ts`, `functions/quota.ts`): reserve / commit / release, multi-unit and idempotent. The assistant pool comes from P-159; video units are reserved at job creation, committed when filed and released on failure.
- **Storage:**
  - `families/{f}.quotaBytes`, default 10 GB.
  - +10 / +20 GB **requests** reviewed by staff, with P-120 for large ones.
  - 13b / 13c / 13d, plus the AS18 notice.
- **App:** PR01 `PaywallScreen` with a resume after purchase (`openPaywall`, `PurchaseResume`), PR03 / PR04 `HouseholdPlanScreen` with owner and member views, `showGateSheet`, the Cao cấp template gate, and the assistant upsell on CH21 / CH24. There is no store SDK: `UnavailableStoreGateway`, and the `premium_billing` flag is off.
- **Portal:**
  - Tính năng & Premium hub: features, families, plan config with a before/after diff, campaigns, family grants and revokes.
  - PremiumOps: AI policy, family quota, render ops (read-only).
  - Storage approvals.

**Missing (all new work):**
- **Plans and quotas:** one-time Free allowances, seat limits and their enforcement, a buyable storage add-on.
- **Family plan screens:** the manager / member family plan screen as drawn (PV40 / PV40B / PV45), the usage history (PV41), the cancel consequences (PV42), the downgraded state (PV43) and the seat picker (PV44).
- **Paywall and entry points:** the dark single paywall with its carousel and the entry wiring E01–E14, PW07 "Nhờ … nâng cấp", and the PW10 add-on screen.
- **Portal:** the commercial overview (PT01), family ledger with manual adjustment and second approval (PT02), versioned config with two approvers (PT03), and the video-job refund queue (PT04).

---

## 4. Architecture

### 4.1 One policy object, versioned

`packages/contracts/src/premium-v2.ts` defines the policy:

```ts
policy = {
  version: '2.0-launch',
  plans: {
    free:    { lumiCreditsOneTime: 30, videoExportsTrial: 2, storageGB: 1,
               caregiverSeats: 3, premiumTemplates: false },
    premium: { lumiCreditsPerCycle: 200, videoExportsPerCycle: 4, storageGB: 10,
               caregiverSeats: 6, premiumTemplates: true,
               price: { vn: { month, year }, intl: { month, year } } },
  },
  storageAddOns: [{ id: 'storage_20', gb: 20, … }, { id: 'storage_50', gb: 50, … }],
  creditTopUps: false,
  taskCosts: { 'lumi.quickAnswer': 1, 'lumi.voiceLog': 1, 'lumi.writeCaption': 2,
               'lumi.review7d': 5, 'lumi.photo': 3 },
  grandfather: { createdBefore: ISODate | null, freeStorageGB: 10 },   // Q-095
}
```

- **Storage:** `config/entitlementPolicies/{version}` holds immutable versions; `config/entitlementPolicy` = `{ running, draft, approvals[] }`; `publicConfig/entitlementPolicy` is the mirror without approvals.
- **Fallback:** until a v2 version is approved and set running, the **current v1.3 behaviour stays exactly as it is.** The existing `config/entitlements` keeps feeding the resolver.
- **Effect:** no family sees a new limit until two staff approve "2.0-launch" in the portal (PT03).

### 4.2 Plan limits resolver (pure, shared)

`planLimits(policy, plan, family)` returns `{ lumi, video, storageBytes, seats, premiumTemplates }`.
- **Free:** one-time pools.
- **Premium:** per-cycle pools anchored on the subscription day (monthly even on yearly plans, PV40).
- **Storage:** the base, plus the add-on while it is active, plus grandfathering.

It is used by:
- the assistant pool (`assistant-usage.ts`);
- the video quota (`video-quota.ts`);
- storage enforcement (`memories.ts` and the keepsake reservation);
- the seat check (the invite / role-change callables);
- `getCapabilities`, which answers the app with limits and balances for PV40 / PV45.

### 4.3 Ledger history (PV41)

The quota ops already record every hold, commit and release. A `familyUsageHistory` callable projects them into rows of **person · task label · amount · time**, never content:
- the manager sees every row;
- a member sees only their own;
- the filter chips are Tất cả / Lumi / Video / Cấp & hoàn.

### 4.4 Seats

- A seat = an active member with write access (`coParent` or `caregiver`); relatives never take one.
- `inviteMember` / `acceptInvite` / `changeRole` refuse a write role once the seats are full. They return `SEATS_FULL`, which the app maps to E12 → PW05.
- When a downgrade leaves the family over the limit, nothing changes until the manager chooses (Q-101).
- `chooseWriteSeats` (manager only) sets `writeSuspended: true` on the members left out. **Firestore Rules** treat a suspended writer as read-only, and the suspended member gets one gentle notice.

### 4.5 Storage add-on

- Policy entries plus a family field, `storageAddOn { id, until }`. The limit is the base plus the add-on while `until` is in the future.
- **Purchase is IAP, so it comes later.** Until then PW10 shows the plans and a disabled "Sắp có" state (or a staff grant from PT02), with honest copy.

### 4.6 App

- **`PremiumPaywall`** (PW01–PW08): one screen, `entry: PremiumEntry`, carousel of the 6 feature cards (Video · Thiệp · Lumi · Dung lượng · Người chăm sóc · Khám phá), the Free vs Premium table from the policy, and the Năm / Tháng footer.
  - The CTA calls the existing purchase controller. With `premium_billing` off it reads "Sắp mở đăng ký" and does not pretend to charge.
  - A member who is not the manager gets the PW07 variant.
- **`PremiumSuggestion`** (component "Gợi ý Premium" Sheet / Inline): reason, free alternative, "Xem Premium". It replaces today's gate sheet at each E-entry; the return target goes through the existing `PurchaseResume`.
- **Gói của gia đình** (PV40 / PV40B / PV45) replaces PR03; plus PV41, PV42 (consequences first, then "Tiếp tục huỷ trong App Store" opens the store's subscription page), PV43 and PV44.
- **E13** Premium card on Tôi / Hồ sơ.

### 4.7 Portal

| Screen | Plan |
|---|---|
| PT01 Tổng quan thương mại | From MET-01 facts, entitlement grants and quota ops; revenue cells stay `—` until IAP |
| PT02 Gia đình | The existing family lookup plus the ledger (30 days), a manual adjustment (reason required; a second approver above 50 credit or for a plan change), audit |
| PT03 Cấu hình quyền lợi | Versions, diff against the running one, "Gửi duyệt", a second approver publishes |
| PT04 Job video & hoàn lượt | Failed / held / running jobs, retry with the same idempotency key, manual refund with reason and audit |

---

## 5. Owner decisions (D-101, 2026-10-25)

| # | Question | Owner | What it means |
|---|---|---|---|
| Q-095 | Free storage 1 GB: grandfather older families? | "áp dụng 1gb cho toàn bộ trước. sau này khi vận hành tôi muốn đổi thì đổi value trên portal. free và premium giá trị khác nhau" | **1 GB for every Free family**, no grandfathering. Families over 1 GB see the over-limit state (uploads queued, nothing deleted, view / download / export kept). Every value is editable per plan in the portal |
| Q-096 | Fresh Free allowance? | "Cấp mới 30 credit + 2 video" | Each Free family starts with 30 credit / 2 exports when v2 turns on; earlier use does not count |
| Q-097 | Families already over the seat limit | "Giữ nguyên, chỉ chặn mời thêm" | Nobody loses write access; a new writer beyond the limit is refused (E12 → PW05). PV44 is used only after a downgrade |
| Q-098 | Show the credit cost on buttons and the balance in the Lumi header? | "Giữ D-081" | **No** cost on buttons, no balance in the header; credit numbers stay on the usage page (CH19), Gói của gia đình (PV40 / PV45) and the history (PV41) |
| Q-099 … Q-104 | | as recommended (not asked) | "credit" for Lumi, "lượt" for video; full Premium on upgrade, Free trial not carried over; everyone keeps write until the manager chooses; PW10 add-on shown "Sắp có" until IAP; any second admin approves a version; photo reading 3 credit |

**Consequence of Q-098 for the design:** PV00 §3 "show the cost on the button" and PV00B "số dư ở header" are not built. E05's estimate before a task ("cần khoảng 3 credit") stays inside the existing CH20 bubble only where it already is.

## 6. Implementation plan (all behind `premium_v2`; IAP stays out)

| Phase | Content | Exit |
|---|---|---|
| **A · Policy** | `premium-v2.ts` (policy, limits resolver, seat rule, history row shape); versioned config docs and the Rules mirror; `premium_v2` flag; tests | Contracts and Rules green, v1.3 behaviour unchanged |
| **B · Server** | Resolver wired into assistant / video / storage / invites; seat enforcement and `chooseWriteSeats` with Rules; `familyUsageHistory`; `getCapabilities` limits and balances; staff: versions + approvals, adjustment with second approver, job refund | Integration tests green; nothing changes while the policy is not running |
| **C · App** | Paywall PW01–PW08 / PW07 + suggestion component; E01–E14 wiring with return-after-purchase; PV40 / PV40B / PV45, PV41–PV44; PW10 (pre-IAP); E13; vi / en; Light + Night goldens | All E-entries open the right card; return lands on the origin |
| **D · Portal** | PT01–PT04 | Portal tests; deploy to dev |
| **E · Later** | IAP (PV30–PV33), store-driven grants, add-on purchase, refunds from the store | Separate plan |

## 7. Status (2026-10-25)

Everything below runs only for families with `premium_v2` on (dev: `internal`); with the flag off every screen and limit behaves as v1.3. In-app purchase is not built (owner).

| Phase | Done | Where |
|---|---|---|
| A · Policy | `plans` + `plansVersion` in `config/entitlements` (portal-editable per plan), `planLimits`, `monthlyCycle`, seat rule, usage-history and family-plan shapes, staff proposal / adjustment / refund schemas | `packages/contracts/src/premium-v2.ts`, `entitlements.ts`, `config.ts` |
| B · Server | Lumi: Free 30 credit in a never-resetting trial window (`assistant_trial_v2`, Q-096), Premium 200 per monthly cycle on the grant's start day. Video: Free 2 / Premium 4 the same way. *(Superseded by D-124 and D-158: video exports are unlimited for both plans; plan quality decides 720p / 1080p.)* Storage limit computed (`storageLimitBytes`: plan base + active add-on + staff-granted extra) in uploads, retries, video jobs, Dung lượng, storage requests and the 80 / 100 % notices. Seats: `createFamilyInvite`, `acceptFamilyInvite` and `updateFamilyMember` refuse a new writer with `seats-full` (pending write invites hold a seat; relatives never take one; a writer of another baby keeps one seat). `chooseFamilyWriteSeats` (manager only) sets `writeSuspended`; Rules (`canLog`, `babyOpen`) and the memory / video callables treat a suspended writer as view-only. `getFamilyPlan`, `familyUsageHistory` (manager everyone, member own; label ids, never content). Staff: `staffProposePlans` / `staffDecidePremiumProposal` (second approver, D-058 + D-079 switch), `staffAdjustUsage` (≤ 50 at once, more needs a second approver; video adjustments kept as `bonus` so a config change does not undo them), `staffRefundVideoJob` (once per job) | `firebase/functions/src/premium-v2.ts`, `premium-plans-staff.ts`, `family.ts`, `quota.ts`, `video-quota.ts`, `assistant-usage.ts`; tests `firebase/tests/premium-v2.integration.test.ts`, `care.rules.test.ts` |
| C · App | Paywall PW01–PW08 by entry (reason line only from an entry, "Bạn đang cần", carousel opened at the entry's card, promises, footer by role: period tiles + "Sắp mở đăng ký trong app" until IAP, PW07 "Nhờ … nâng cấp" shares a short message, a Premium family is sent to its plan). Gợi ý Premium sheet / inline. Entries: E01 / E02 / E04 (Premium templates), E03 (video exports used; Premium: refill date), E05 / E06 (Lumi → PW03), E08 / E09 (Dung lượng inline replaces "Liên hệ quản trị"), E11 (Tự lưu), E12 (seats full → PW05 or "Mời làm người thân"), E13 (Tôi). Gói của gia đình PV40 / PV40B / PV43 / PV45, PV41 history with filters, PV44 seat picker (only the manager pre-checked), PV42 cancel consequences, PW10 extra storage ("Sắp có", Q-102) | `apps/mobile/lib/features/premium/{premium_v2,premium_style,paywall_v2,family_plan_v2,premium_entries}.dart`; tests `test/features/premium_v2_test.dart`, goldens `test/golden/goldens/pv2/` |
| D · Portal | PT02 manual adjustment on the family's Lượt dùng; PT03 "Gói & hạn mức (v2)" with the running version, a draft editor and the proposals waiting (Duyệt / Từ chối); PT04 "Hoàn lượt" on a used video job in Render ops; `premium_v2` switch under Gia đình & tiện ích. No reason fields (D-090) | `apps/portal/src/screens/PremiumPlans.tsx`, `messages-premium-v2.ts`; test `apps/portal/test/premium-v2.test.tsx` |

**Not built yet, by design or for later:**

- PT01 Tổng quan thương mại: built as Tính năng & Premium › **Tổng quan** (Free / Premium families, conversion, add-ons, new families and new Premium per day / week / month, allowances run out, renewals, needs a hand). Gross revenue, net revenue and the cost to serve show "—" until in-app purchase and per-family cost metering.
- E07 inside the chat (CH24 card): the sheet exists (`showLumiCreditsUsed`) but the chat keeps its own "hết lượt" card until the assistant copy moves to credits (Figma's CH20 / CH21 still say "20 lượt · làm mới", see §2).
- E10 (Kỷ niệm upload pill): the Kỷ niệm screen is being changed by another session; the suggestion (`showStorageFullSuggestion`) is ready to wire.
- Nhờ người quản lý nâng cấp sends nothing to the server: it opens the share sheet with a short message (no draft, no question), so the manager is never notified without the member choosing to.
- Auto-restore of write access when the family upgrades again: the manager opens PV44 and saves; the server already allows anyone back when there is room.

**Owner, 2026-10-25 (after the first device test):**

- The paywall has two kinds of entry: chosen by the user (Tôi, Gói của gia đình › Xem các gói) shows the general page (PW06); a feature that needs Premium shows its headline, the small line saying what is kept, its card first and "Bạn đang cần" (PW01–PW05, plus Nhịp lớn lên with engineering copy).
- The paywall shows the plans and the CTA as drawn; until the store account is ready the CTA says the payment step is coming.
- The portal runs a family with one switch, **Gói: Free | Premium** (`staffSetFamilyPlan`): Premium = every Premium capability (optional last day); Free = every staff grant taken back and the per-feature "on" overrides cleared; a store subscription stays. Per-feature settings moved under "Nâng cao".
- The old beta campaigns are gone from the portal, and dev's `config/entitlements.betaCampaigns` was emptied (it held one, `duckie_beta`). Prod still needs the same before v2 runs there.
