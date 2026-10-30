# 00 — Product understanding (Phase 0)

Audit date 2026-10-29. Snapshot: branch `s2-onboarding`, HEAD `8e53ea55` (another session committed
`ebcdcf49 → 8e53ea55` during the audit; the automated runs below were made against these two commits,
see [07](07-qa-test-coverage.md)). Tags: **[V]** verified in code or docs; **[A]** assumption or inference.

## 1. What problem it solves

A private family space for **co-caring for a baby** and **keeping the baby's memories** [V `README.md:3`].
Parents, carers and relatives log care such as feeds, sleep, diapers and growth. They hand over between
carers, share photos and videos with chosen relatives, and receive AI help ("Lumi") and age-based
guidance [V `docs/product/business-map.md` §1].

## 2. Target users

| Actor                      | Role in product                                                         | Source                        |
| -------------------------- | ----------------------------------------------------------------------- | ----------------------------- |
| Cùng nuôi (co-parent)      | Full rights per baby; owner of the profile ("chủ hồ sơ") is one of them | business-map §2.1 [V]         |
| Người chăm sóc (caregiver) | Logs and views care; no Memories; no invites                            | business-map §2.1 [V]         |
| Người thân (relative)      | Sees "Gia đình" memories; optional extra rights (D-018, D-019)          | business-map §2.1 [V]         |
| Temporary identity         | Joined from an invite without an account ("Vào ngay")                   | business-map §2 [V]           |
| External recipient         | Opens a private story link on the web                                   | business-map §2 [V]           |
| Child Life staff           | Portal "Child Life · Vận hành"                                          | D-007, D-008, D-043/D-053 [V] |

Market: Vietnam first (Vietnamese is the source language, English drafted by engineering, D-012) [V].
Data region asia-southeast1 (D-009) [V].

## 3. Primary user journeys

1. Install → welcome/tour → sign in (Apple / Google / email) → "Bạn là ai với bé?" → baby profile → Today
   (S2) [V slice report S2].
2. Log care from Today (quick log, timers, sleep overlap, history, stats) — offline-first (S4–S6) [V].
3. Invite family by QR / link / email + 6-digit code; accept / join as a temporary identity (S3) [V].
4. Add photos and videos to Kỷ niệm (Memories) with audience "Gia đình" / "Chỉ ba mẹ" and quota (S9–S10) [V].
5. Hand over between carers (Bàn giao), reminders, Cùng Chăm Con shared care plan (D-135…D-138) [V].
6. Me: storage, profiles, ownership transfer, export, account/baby deletion (S11) [V].
7. Stories, cards, keepsake videos, external share links (S12, S13, Kỷ niệm 2.0) [V].
8. Lumi assistant, Premium paywall and plans (D-101, D-124) [V].

## 4. Core business capabilities (as built)

About 40 feature modules exist under `apps/mobile/lib/features` [V]. They cover adaptive Today, AI,
assistant, auto-save, baby, care, care plan, engagement, family, feedback, first aid, glance, keepsakes,
library, memories, milestones, notifications, nutrition, onboarding, premium, print studio, reminders,
rhythm, solids, spending, stories, vaccines and others. The backend has about 120 TypeScript modules: 24 direct `onCall` sites plus
wrapper factories, 13 `onRequest`, 38 scheduled, about 43 Firestore triggers, 2 Storage triggers
(`firebase/functions/src`) [V]. Size: about 220k lines of Dart in `lib/` without l10n, 6,596 ARB keys per language [V].

## 5. Intended experience

Calm, few words, no guilt (no streaks or scores), "latest state first", one tap to start and three taps or
fewer to save. Sharing is intentional and the audience is always visible (business-map §1, Figma cover
`17:492`) [V]. The Flutter app is the current UI and copy authority (D-104), except features
designed in Figma afterwards (D-137) [V].

## 6. Business goals

Documented: family activation, retention (D1/D7/D30), creator's first ready memory, weekly meaningful
families (`docs/product-analytics/02-metric-dictionary.md`, `08-foundation-implementation.md`) [V].
Monetization: Free and Premium (monthly / yearly) with storage add-ons (D-101). Store billing is
postponed (D-074); SKUs, price and trial are still open (Q-058, Q-071) [V].
**No documented launch success targets** (numbers to hit) were found [V, absence within repo].

## 7. Current development status

| Signal                   | Value                                                                                                                  |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| Slices with reports      | S0–S7, S9–S15b; **S8** (widgets / Live Activity) waiting on the Apple team; **S16** (verify & release) not started [V] |
| Figma coverage checklist | Screens: **0 ☑**, 85 ◐; business flows 0 ☑; admin portal 0 ☑ (`figma-coverage-checklist.md:15-23`) [V]                 |
| Environments             | `dev` deployed; **`prod` (`child-life-ecosystem`) not provisioned for the app** (no Firebase options) [V]              |
| Feature flags            | 37 keys; every default is **off** (`packages/contracts/src/config.ts:97-134`) [V]                                      |
| Store billing            | Not implemented (`billing.ts:31-34`, "billing-not-configured") [V]                                                     |
| Legal text               | Privacy and Terms pages are placeholders (`apps/landing/src/content/vi.ts:1407-1424`) [V]                              |
| Version                  | `1.0.0+1` (`apps/mobile/pubspec.yaml:19`) [V]                                                                          |

## 8. Completeness by area

| Area                                  | Status       | Evidence / gap                                                                                   |
| ------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------ |
| Onboarding & identity                 | Built        | S2; Apple sign-in on interim team bundle `dev.hsba.app` (`environment.dart:8-10`)                |
| Family, invites, roles                | Built        | S3; invite email via Resend (D-054)                                                              |
| Care logging, timers, history, stats  | Built        | S4–S6; offline outbox (`care_repository.dart:278-305`)                                           |
| Reminders                             | Built        | S7 + rule reminders                                                                              |
| Widgets / Live Activity / lock screen | **Partial**  | S8 blocked on Apple team (implementation-plan §S8); Android Glance partly done                   |
| Memories, upload, albums, quota       | Built        | S9–S10; prior P0s FAM-01 / MEM-01 / CON-01 fixed per `product-audit/11-implementation-report.md` |
| Me, storage, deletion, export         | Built        | S11; resumable deletion jobs with verify step (`account.ts:525-600`)                             |
| Stories, cards, share links           | Built        | S12–S13; universal links need the Apple team                                                     |
| Premium / paywall                     | **Partial**  | Plans, gates, paywall built; **no purchase** (D-074)                                             |
| Lumi / AI                             | Built, gated | Flags `assistant*` internal; AI consent text open (Q-070)                                        |
| Product analytics                     | Built, off   | `product_analytics` off; privacy review PA-05 pending (`product-analytics/08`)                   |
| Landing / portal                      | Built (dev)  | Landing "not ready for prod" (S14 report); portal on dev                                         |
| Legal, store listing, prod infra      | **Missing**  | See [08](08-production-readiness.md)                                                             |

## 9. Critical context gaps (not invented here)

- No **launch scope**: which of the ~40 modules and 37 flags are on for the first real users.
- No **launch success metrics** with targets.
- Open owner and legal questions that block a public release: **Q-020** (child-data consent, privacy
  policy), **Q-055** (lawyer review, Law 91/2025), **Q-070** (AI consent and retention), **Q-071**
  (SKUs and prices), **Q-073** (subscription when the buyer leaves).
- No prod operations documents (backup / restore / incident / rollback runbooks).
