# Tính năng, Premium, beta và cá nhân hoá: one hub (analysis, 2026-10-21)

**Owner request:** "làm gọn /features và /premium: ai đã đăng ký premium thì tự động được bật toàn
bộ tính năng premium trên app; cần chức năng bật premium cho mỗi tính năng tới mỗi user mà admin
muốn; option bật toàn bộ tính năng premium cho bất kỳ user nào mà không cần ghi lý do hay duyệt (chỉ
có 1 người vận hành); tương tự tính năng beta. Phân tích xem nên gộp tính năng + phát hành + premium
+ cá nhân hoá lại 1 không (cá nhân hoá như 1 tính năng). Phân tích có cần config tính năng nào là
premium hay free." Proposed as **D-089**; the choices below are **P-173** (owner answered 2026-10-21, D-089).

## 1. How it works today, and why it feels heavy

Two mechanisms decide whether a family sees a feature, and they live on two pages.

| | /features (flags, `config/flags`) | /premium (entitlements, `families/{f}/grants`, `config/entitlements`) |
|---|---|---|
| What | 36 flags. They mix three different things: (a) **engineering kill switches**, e.g. `media_upload`, `assistant_live` and the 11 new `engagement*` switches; (b) **beta features rolled out per family**: `auto_save`, `milestone_cards`, `memory_story`; (c) **kill switches of premium capabilities**: `personalization`, `ai_assist`, `rhythm`. | 13 capabilities: 8 free, Group A (cross-module personalization, advanced rhythm, AI), Group B (premium templates), and the AI credit budget. Grants come from `paid`, `beta` (campaigns) or `promo` (staff, with a reason and an end date). Tabs: Cấu hình (regions, billing), Chính sách AI (budgets), Chiến dịch (beta campaigns), Gia đình. |
| Rollout | Off · internal families + a picked list · % of families · everyone. | Campaigns roll out like flags, plus a country. |

**Effective rule today** (`resolveCapability`): a premium capability needs (1) its flag on *for that
family* (rollout), (2) a supported region (`regions.advanced`), then (3) a grant. A family in an
unsupported country is refused even with a grant (this is why dn@goupscale.com's US family saw no
Premium on 2026-10-18). So a **paying family can miss a premium feature** while its
flag is still "internal". Turning one feature on for one family means adding it to that flag's
family list. That only works while the flag's scope is "internal", and it is a different place from
the family's Premium. A promo grant always asks for a reason and an end date.

## 2. Recommendation

**Merge /features, /premium and the personalization switches into one "Tính năng & Premium" hub.**
Keep "Cập nhật ứng dụng" (minimum app version, forced update) separate: it is about app builds, not
about who gets a feature. Personalization becomes features in the catalogue, and its metrics stay
in Phân tích.

### 2.1 A feature catalogue (the product view)

One row per **user-facing feature**, grouped (Ghi chép · Kỷ niệm · Cá nhân hoá · Trợ lý AI · Nội
dung). Each row has:
- **Gói** (tier): **Miễn phí · Premium · Beta**, editable (2.4);
- **Phát hành**: Tắt · Thử nội bộ · % gia đình · Mọi người (today's rollout);
- **Công tắc khẩn**: the kill switch (off for everyone at once, with the optional in-app notice).

Catalogue v1, mapped onto today's flags and capabilities:

| Feature | Tier (default) | Today |
|---|---|---|
| Nhịp lớn lên (lịch tham khảo, check-in) | Miễn phí | flag `rhythm` |
| Gợi ý cá nhân hoá liên mục, Nhịp lớn lên nâng cao | Premium | `personalization` + Group A |
| AI tóm tắt và giải thích | Premium | `ai_assist` + `ai.assistance` |
| Trợ lý (chat, ảnh, hướng dẫn chăm sóc) | Premium (credits) | `assistant*` + budget |
| Mẫu kỷ niệm Premium | Premium | `templates.premium` |
| Thiệp cột mốc | Beta | `milestone_cards` |
| Video kỷ niệm | Beta | `memory_story` |
| Tự lưu kỷ niệm | Beta | `auto_save` |
| Nháp câu chuyện AI | Beta | `ai_story_drafts` |

The engineering switches (uploads, invites, widgets, `assistant_live`, `assistant_writes`, the
`engagement*` family) move to a **"Công tắc hệ thống"** tab. They are on/off levers, not products,
and have no tier.

### 2.2 Who gets a feature (one rule, shown on every row)

1. Kill switch off → nobody.
2. **Admin override for this family** (on or off) → that.
3. **Premium** feature → every family with Premium (paid, or granted by admin) gets it, **whatever
   the rollout**. Others see the paywall when billing is on.
4. **Beta** feature → the families in its beta: picked families, plus a share of families or
   everyone. Free while in beta, labelled "Beta" in the app.
5. **Miễn phí** feature → its rollout.

This is the owner's "premium thì tự động được bật toàn bộ tính năng premium". The rollout of a
premium feature only says when it launches for everyone else's paywall.

### 2.3 Families and users ("Gia đình" tab)

Search by family code, email or baby nickname, then:
- **"Bật toàn bộ Premium"**: one switch, with no reason, no approval and no end date by default
  ("đến khi tắt"); an optional end date. It replaces today's promo grant form.
- **Every catalogue feature with its effective state and why** ("Có · Premium", "Có · Beta",
  "Không · chưa phát hành"), plus a per-feature **Bật / Tắt / Theo quy tắc** switch (the override
  of 2.2 #2). This is the owner's "bật premium cho mỗi tính năng tới mỗi user".
- **"Thêm vào beta"** for any Beta feature, which adds the family to that feature's beta list.

Overrides are per **family** (the household shares Premium). The portal finds the family from a
user's email.

### 2.4 Should the tier (Premium vs free) be configurable? Yes, with limits

Why yes:
- a feature can launch free or in beta, then move to Premium, without an app release;
- promotions ("Mẫu kỷ niệm Premium miễn phí tuần này") become a temporary tier change;
- the server already decides access in `getCapabilities` / `featureAccess`, so the app follows
  without an update.

Limits:
- only catalogue features are tierable; engineering switches are not;
- moving a feature from Miễn phí or Beta to **Premium** asks for a confirmation that names how many
  families currently use it, and it keeps them on it for 30 days (a grace override) so nobody loses
  work mid-way;
- every change lands in "Lịch sử" automatically (who, what, when). There is no reason field.

### 2.5 Reasons and approvals

With one operator, every portal action stops asking for a reason (D-090, across the portal). The
server keeps an automatic audit line: actor, action, before and after. The two-person rules stay
in the code behind the existing policy switch (D-079), off by default.

### 2.6 What changes underneath

- **Contracts:** a feature catalogue (key, group, flag, capabilities, default tier, tierable),
  `config/features` (the tier per feature), `families/{f}/featureOverrides/{feature}`, and
  "Premium toàn bộ" as a staff grant with no reason and an optional end.
- **Server:** `resolveCapability` and `featureAccess` apply the rule of 2.2, so a Premium grant
  skips the rollout for Premium features. One callable sets an override; one sets the tier.
- **App:** no change in v1; it already obeys `getCapabilities` and `featureAccess`.
- **Migration:** beta campaigns become Beta features with the same rollout, and active promo grants
  stay.

## 3. Questions for the owner

1. Merge into one hub, keeping "Cập nhật ứng dụng" separate? (Recommended.)
2. Make the tier editable for catalogue features, with the 30-day grace? (Recommended.)
3. Should "Bật toàn bộ Premium" default to no end date? (Recommended for one operator.)
4. Should Premium (paid or granted) skip the country check too, or should features keep their
   advanced-region list? Recommended: an admin grant skips it; a paid subscription follows the
   store's own country availability.
