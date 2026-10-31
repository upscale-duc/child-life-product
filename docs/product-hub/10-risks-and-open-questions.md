# 10 · Risks, trade-offs and open questions

## 1. Risks

| # | Risk | Likelihood · Impact | Mitigation |
|---|---|---|---|
| R1 | **Knowledge rots**: narrative approved once, never revisited as code moves fast (365 commits in ~3 weeks) | High · High | Stale marking on every source change; coverage penalty; Overview shows stale count; sync is cheap to run |
| R2 | **Second source of truth** for entitlements or decisions | Medium · High | Read-only Plans; business-map stays the decision source; contracts read at sync and request time |
| R3 | **Review fatigue**: change sets too big to review → rubber-stamping | High · Medium | Unchanged files produce nothing; change sets grouped by feature; link suggestions batched; first run reviewed by feature, not by file |
| R4 | **False authority**: a dated audit shown as current truth | Medium · High | Doc date + revision shown on every citation; snapshot docs default to `research` |
| R5 | **Copilot over-claims** ("verified") | Medium · High | Server-side citation validation; `verified` only from code facts/approved records; eval fixtures |
| R6 | Keyword search misses paraphrased questions (vi ↔ en) | Medium · Medium | Aliases in registry (vi + en); id boosts; measured recall gate before adding embeddings |
| R7 | Parallel sessions edit shared files (`staff.ts`, `Shell.tsx`, `context.ts`, messages, rules, indexes) | High · Low | Product Hub owns new files; shared edits are a few lines, made in their own commit, checked in a HEAD worktree |
| R8 | Registry seed globs drift from code | Medium · Medium | Sync reports dead globs; test "every glob matches at HEAD" |
| R9 | Product Insights pressure before launch leads to fake numbers | Low · High | Insights tab not built until Phase 4; "unavailable" states only |
| R10 | Cost creep from Copilot | Low · Low | One call per question, caps in config, telemetry |

## 2. Trade-offs taken

| Choice | Alternative | Why |
|---|---|---|
| Manual sync from a developer machine, review in portal | Portal reads GitHub | No repo credentials in the cloud; same pattern as `content-release.ts`; no CI exists yet |
| BM25 index artifact in Storage | Vector DB / Firestore vector search | ~5 k chunks; ids and terms carry most signal; measurable gate for later |
| business-map.md remains the decision source | Decisions authored in the Hub | Owner already works in the business map; avoids two logs |
| Narrative stored in Firestore, facts from repo | Everything as Markdown in repo | PO edits in the portal without git; facts stay reproducible from a revision |
| 5 tabs on the feature page grouping the 12 sections | 12 flat sections | Progressive disclosure; scan in under a minute |
| New `product` staff function | Reuse `features` | `features` can change live tiers; knowledge access should not imply that |
| One registry JSON maintained by engineers | Auto-discover features from code | Feature boundaries are product judgement; auto-discovery would invent features |

## 3. Open questions and decisions needed (owner)

| Id | Question | Proposed default | Blocks |
|---|---|---|---|
| **Q-PH-01** | Add a portal function `product` with the role defaults in [08 §1](08-security.md#1-access-model)? (permission-model change) | Yes: owner/admin full, eng edit, analyst/ops view, others none | PH1.0 |
| **Q-PH-02** | Name in the portal: "Sản phẩm" / "Product" (avoids clashing with "Tính năng & Premium" hub)? | "Sản phẩm" · "Product" | PH1.0 |
| **Q-PH-03** | Does business-map.md stay the only decision source, with Hub drafts exported for you to add? Or should the Hub become the decision source later? | Stay in business-map through Phase 3; revisit after | PH2.3, Phase 3 |
| **Q-PH-04** | Who approves knowledge? Two-person rule (author ≠ approver) as in content (D-058), or owner alone may self-approve? | Two-person, with owner allowed to self-approve | PH1.3 |
| **Q-PH-05** | Copilot budget: OpenAI `gpt-4.1-mini`, 20 q/hour/staff, 200/day, ~$5–10/month? | Yes | PH2.1 |
| **Q-PH-06** | Keep Copilot conversations 180 days? | 180 days, owner-deletable | PH2.1 |
| **Q-PH-07** | Product knowledge text bilingual per field, Vietnamese required and English optional (shown as "EN chưa có")? | Yes | PH1.4 |
| **Q-PH-08** | Pilot features for the first narrative pass: Feeding, Tự lưu kỷ niệm, Lumi? | Yes | PH1.7 |
| **Q-PH-09** | Include `.claude/skills/cl-ux-writing` glossary as a reference source? | Glossary only | PH1.2 |
| **Q-PH-10** | Should chapters (CH01–CH04) and age ranges be filled per feature in Phase 1 review, knowing they never gate access? | Yes, as metadata only | PH1.4 |

## 4. Facts Phase 0 could not establish

- Live tiers in `config/features` and limits in `config/entitlements` on dev/prod (not read).
- Device behaviour of any feature (no device runs in Phase 0).
- Whether "Thư của con" (D-149) exists under another name — name search found no module.
- Whether `care.visit_report`, `care.utilities` and `platform.watch` are user-reachable today.
- Test pass status at HEAD (tests were listed, not re-run).
