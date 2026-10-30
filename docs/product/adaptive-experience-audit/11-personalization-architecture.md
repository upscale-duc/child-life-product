# 11 · Personalization architecture

## 1. Assessment

The existing architecture (adaptive plan §4) is **sufficient in shape**: a pure engine in contracts mirrored in Dart, a static registry versioned with the binary, a per person × child experience doc, availability ≠ eligibility, flags as switches only. It needs **completion, not replacement**. No machine learning is warranted: the inputs are few, explicit and explainable.

| Concern | State | Gap |
|---|---|---|
| Child profile schema | DOB date-only, zone, trackers, ≤ 18 y | None |
| Age calculation | Correct per function | Five implementations, no shared vectors (AXA-04) |
| Time zone | Child's zone with device fallback | None |
| Family goals | Experience doc | Overlaps EN01 interests (AXA-02) |
| User preferences | `users/{uid}/settings/personalization` (person) + experience (person × child) | Two stores, two vocabularies |
| Feature metadata | `widgetRegistry` (goals, product) | No coverage, no band relevance outside `bandDefaults`, no slot entries (AXA-03) |
| Adaptive ranking | Built, tested | `product` weight unused (fine) |
| Feature flags | Built | Off by default (AXA-01) |
| Content eligibility | Per module (stageFor, solidsAgeState, ageCardFor) | No shared "coverage" query |
| Notification targeting | Engagement engine with windows | Year-scale triggers missing |
| AI context | Module reads | No coverage/band in context |
| Cross-device | Doc synced; usage local | AXA-08 |
| Offline | Firestore persistence + local mirror (D-091) | None |
| Analytics | `adaptive_*`, `stageBand` | Readout built; baseline not reported |
| Tests | Shared fixtures for ranking; rules tests; goldens per band | No golden at 5 y / 9 y for non-adaptive screens (Mốc, Thư viện) |

## 2. Layers (recommended, mapping onto what exists)

```
L1 Eligibility    registry entry ∧ flag ∧ role ∧ capability ∧ coverage(child) ∧ data
                  → availableWidgetsProvider (exists) + coverage (new) + slots (new)
L2 Explicit       pinned, order, shown, hidden, goals        → experience doc (exists)
L3 Context        band default (bandApplied), goals, events  → rankToday (exists)
L4 Behaviour      usage 28 d, recency 48 h, frozen per run   → UsageStore (exists)
L5 Presentation   slot order, widget ids → Flutter widgets   → today_screen.dart (exists)
```

## 3. Slots (AXA-03)

Fixed blocks become registry entries of kind `slot`: they keep a fixed position and are not scored, but go through L1 eligibility and L2 visibility where the person can hide them.

```ts
type SlotId = 'living_header' | 'status' | 'auto_save_banner' | 'care_plan_tasks'
            | 'stage_card' | 'customize_link' | 'appearance_row';

interface SlotEntry {
  id: SlotId;
  position: 'top' | 'afterRanked' | 'bottom';
  priority: number;            // order within the position
  hideable: boolean;           // care_plan_tasks: yes (D-135); living_header: no
  eligible(ctx: ChildContext): boolean;
}
```

## 4. ChildContext and coverage

```ts
interface ChildContext {
  babyId: string;
  months: number | null;           // null: DOB unreadable for this role
  band: AgeBand | null;
  correctedMonths?: number;        // D-141, < 24 m only
  role: 'coParent' | 'caregiver' | 'relative';
  features: Capabilities['features'];
  coverage: Record<ContentType, boolean>;  // derived
}

const contentCoverage: Record<ContentType, { from: number; to: number }> = {
  milestones:  { from: 0, to: 36 },
  ageCards:    { from: 0, to: 24 },
  library:     { from: 0, to: 36 },
  solids:      { from: 6, to: 36 },
  nutrition:   { from: 0, to: 36 },
  whoGrowth:   { from: 0, to: 60 },
  vaccines:    { from: 0, to: 72 },   // per country
  keepsakeOccasions: { from: 0, to: 12 },
};
// The numbers are today's facts; they live in contracts next to the content schemas
// and are checked by a test against the seed files.
```

Every surface asks `covered(ctx, type)` instead of re-deriving it. When false, it shows the shared end state ([08 §3](08-content-ux-writing-strategy.md)).

## 5. Ranking rules and conflicts

```
for each widget w in registry:
  if !eligible(w, ctx): skip
  if w in hidden: visible = false
  else if w in shown: visible = true
  else visible = defaultVisible(w, bandApplied, addedGoals)

ranked = pinned (pin order)
       ++ (order.isNotEmpty ? manual order, then new eligible by score
                            : by score(w) desc, tie → band default index → registry order)
```

| Conflict | Winner |
|---|---|
| Pin vs score | Pin |
| Manual order vs usage | Manual order |
| Hidden vs new goal | Hidden (the person said so); the goals screen may offer "Hiện lại {widget}?" |
| Band changed vs bandApplied | bandApplied until Áp dụng |
| Role vs goal | Role (eligibility) |
| Product priority vs anything | Lowest weight, decays: `product × max(0, 1 − daysSinceRelease / 30)` (**proposal**) |

## 6. Cold start, fallback, overrides

- **Cold start:** goals skipped → band default exactly (AX10–AX13).
- **DOB unreadable:** band null → care-first order without age labels; no stage card (exists).
- **Doc missing offline:** local mirror; then the old layout migration (P-177).
- **Override:** "Khôi phục gợi ý theo tuổi" (exists) resets order, pins, shown, hidden to band defaults.

## 7. Preferences unification (AXA-02)

```
interests (person, all children)   →  kept only as content topics for personalization v2
goals     (person × child)          →  the only layout input
mapping for migration: sleep|feeding → track_care; moments → memories;
                       vaccines → growth_vaccines; milestones|nutrition → topic only
EN01 invite: hidden when experience.goalsSource == 'chosen'
```

No schema removal; a read-time mapping plus a UI change. L3 (preference surface).

## 8. Privacy

- Band and months only in analytics and AI context; no DOB, names, photos (CLAUDE.md).
- `stageBand` slices are published only above the privacy threshold (exists).
- Usage counts stay on the phone (keep; AXA-08 sync is optional and coarse).
- "Báo tôi khi có" interest: fixed-list terms only (exists).

## 9. Observability

- A debug panel (internal builds): ChildContext, eligibility result per widget/slot with the reason it was excluded, scores. **Proposal**, read-only.
- Analytics: existing `adaptive_*` + a `today_slot_shown` sample (closed event, contract change).

## 10. Testing strategy

| Test | Where |
|---|---|
| Shared age vectors (JSON) run by Dart and TS | `packages/contracts/test/fixtures/age-vectors.json` (new) |
| Coverage table vs seed content | contracts test reading `content/*` |
| Ranking fixtures per band (exist) + slots | `adaptive.test.ts`, `adaptive_engine_test.dart` |
| Golden Today at 3 w, 8 m, 2 y, 5 y, 9 y × Light/Night × vi/en | `test/golden/adaptive_golden_test.dart` (extend; give setup a clock, plan §10 note) |
| Transition 11→12 m, 35→36 m, 71→72 m with pins kept | engine tests |
| Role × band matrix (caregiver of 5 y, relative) | widget tests |

## 11. Migration

- Slots: code-only, no data.
- Coverage: contracts constant; no data.
- Interests → goals: read-time mapping; no write until the person edits.
- Flags: removing the flag-off path only after rollout and a D30 read (plan phase F).
