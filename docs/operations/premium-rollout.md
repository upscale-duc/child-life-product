# Premium & Cá nhân hoá — rollout, rollback and release gates (2026-10-15)

Plan: `docs/product/premium-personalization-plan.md`. Decisions D-072, D-073; proposals P-151–P-154; open
Q-069–Q-073. Everything ships dark: flags off, no region open, no product ids, Kỷ niệm catalog on `everyone`.
Deploys go through `scripts/deploy.sh dev <targets>` only; prod deploys, prod IAM, billing and store releases
need explicit owner approval (`CHILD_LIFE_PROD_APPROVED=yes`, CLAUDE.md).

## 1. Switches and where they live

| Switch | Where | Effect when off / empty |
|---|---|---|
| `rhythm` flag | `config/flags` (portal Tính năng) | No Nhịp lớn lên, no Home section, no check-in; saved data stays readable |
| `personalization` flag | `config/flags` | No group A suggestions or advanced rhythm (even when paid); free content stays |
| `ai_assist` flag | `config/flags` | Template summaries only, no model call; saved summaries stay |
| `premium_billing` flag | `config/flags` | No buy button; existing paid grants keep working; restore works |
| Regions | `config/entitlements.regions.advanced` (portal Premium) | Group A and the paid plan answer `REGION_UNAVAILABLE`; free works |
| Beta A campaigns | `config/entitlements.betaCampaigns` | No beta grants; a campaign can never include templates |
| Quotas | `config/entitlements.quotas` | Fixture defaults (video 1 / 5, AI 1 per baby per day, 10 per family per month) |
| Product ids | `config/billing` | No products → paywall shows "Mua trong app chưa mở" |
| Cao cấp mode | `publicConfig/keepsakes.premium.access` (portal Mẫu kỷ niệm) | `everyone` keeps today's free beta (D-068 #3); `subscribers` gates on `templates.premium` |
| Content | `publicConfig/rhythm_reference`, `publicConfig/content_rhythm` (portal Nhịp lớn lên) | No calendar / no suggestions / no age cards; check-in still saves |
| Rules | `config/rhythm` (portal Nhịp lớn lên › Quy tắc) | `defaultRhythmRules` |

## 2. Rollout order (dev first, then prod after the gates in §4)

1. Deploy rules, indexes and functions (callables, triggers, staff callables), then the portal. After every
   functions deploy, POST `{"data":{}}` to each new / updated callable: JSON 401 is healthy, an HTML 403 needs
   `gcloud run services add-iam-policy-binding <name> --member=allUsers --role=roles/run.invoker` (dev only
   without approval).
2. Publish content through the portal (draft → second person approves; on prod a qualified reviewer's review
   is required). On dev, `pnpm --filter child-life-scripts run seed:rhythm` publishes the engineering draft.
3. Set regions and quotas (portal Premium), with a reason.
4. Turn on `rhythm` for `internal` families, then a percent, then all. Watch `appEventsDaily` (`checkinSaved`,
   `nextActionShown__*`, `capabilityGateSeen__*`) and error logs.
5. Beta A: a campaign for `internal` families, then a percent, with an end date and the notice policy (Q-071).
   Turn on `personalization` and, after the AI audit (§4), `ai_assist`.
6. Paid plan (after Q-071 and store setup): product ids in `config/billing`, store server notification URLs,
   RTDN topic, credentials as secrets; `premium_billing` for internal testers (sandbox → `test` grants), then
   prod.
7. Cao cấp switch (Q-072, P-154): announce in-app ≥ 14 days, then set `subscribers` in the portal.

## 3. Rollback

| Problem | Do | Never |
|---|---|---|
| Wrong or unsafe content | Portal: "Dùng lại bản này" on the previous version (instant), or switch `rhythm` off | Edit `publicConfig/*` by hand |
| Bad suggestions | `personalization` off; free content and check-ins keep working | Delete feedback or check-ins |
| AI misbehaves / cost | `ai_assist` off (template summaries) or lower AI quotas | Revoke entitlements to stop AI |
| Billing verification bug | `premium_billing` off (no new purchases); existing grants keep their `validUntil` | Delete grants; rebind subscriptions by hand |
| Quota bug | Raise the limit in `config/entitlements` (new windows) — reserved units release on terminal jobs | Edit `families/{f}/quota*` documents |
| Functions regression | Redeploy the previous commit's functions (`git checkout <sha> -- firebase/functions` in a worktree, build, `scripts/deploy.sh dev functions:<names>`) | Deploy from a tree with other people's uncommitted changes |
| Rules regression | Redeploy the previous `firebase/firestore.rules` (check `git log` has every peer's rules first) | — |

Data is never lost by a rollback: records, summaries, exports and grants stay; only new advanced requests stop.

## 4. Gates before production (brief p.17, p.20)

- [ ] Approved design mapping for every row of `figma-coverage-checklist.md` §21, end to end on dev, iOS and
      Android, Light and Night care.
- [ ] Content reviewed by a qualified reviewer per region (Q-069); `content/rhythm/SEED-NOTES.md` §6 resolved;
      Wonder Weeks name / model rights checked (D-072 #7).
- [ ] SKU, prices, quotas, beta dates and notice policy decided (Q-071, Q-072, Q-073).
- [ ] Store sandbox lifecycle on real devices (purchase, renew, cancel, grace, expire, refund, restore) for iOS
      and Android (M05–M08, M17).
- [ ] Rules and API suites green (`pnpm test:rules`); concurrency (M10–M12) on dev with `test_` families.
- [ ] Human audit of AI outputs in vi and en (factual meaning, no reassurance, no causality, source relevance).
- [ ] Privacy: consent text, AI provider data processing and retention reviewed (Q-020, Q-070).
- [ ] 0 critical entitlement / privacy / safety failures in the report (`docs/development/premium-test-report.md`).
