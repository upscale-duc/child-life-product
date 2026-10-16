# Free / Plus / Pro: AI cost and credit proposal (PM analysis, 2026-10-16)

Status: **proposal for the owner**. The numbers are configuration (`config/entitlements`), never
hard-coded or published until the owner decides (see the Free / Plus / Pro decision: same features,
different usage levels; prices and credits not fixed).

## 1. Assumptions (check before launch)

| Item | Value | Source / note |
|---|---|---|
| Exchange rate | 1 USD = 26 000 VND | check at launch |
| Model | `gpt-4.1-mini`: $0.40 / M input, **$0.10 / M cached input**, $1.60 / M output | OpenAI list price used in the repo; check |
| Store fee | 15 % (Apple Small Business Program, Google Play subscriptions) | 30 % for Apple above $1 M/year |
| Tax | price includes ~10 % VAT, collected/withheld by the stores | **check with an accountant** |
| Net per 1 000 VND of price | 1 000 / 1.10 × 0.85 ≈ **773 VND** | |

## 2. Cost per action (measured)

| Action | Tokens (in / out) | Cost | Credits today |
|---|---|---|---|
| Text task (log / correction / reminder / expense) | ~4 100 / 165 (measured, prompt v4–v6) | $0.0019 ≈ **49 VND** | 1 |
| Question about data (extraction + wording call) | + ~600 / 80 | $0.0023 ≈ **59 VND** | 1 |
| Photo task, 1 photo (receipt / note) | ~6 000 / 300 (image ≈ 1 500–2 500 tokens) | $0.0029 ≈ **75 VND** | 3 |
| AI summary (handover / explain / moment) | ~3 000 / 400 | $0.0018 ≈ **48 VND** | 1 |
| Care guidance / recipes | ~4 000 / 300 | $0.0021 ≈ **55 VND** | 1 |
| Health support, clarifying question, small talk, help | 0 model call (or cached reading) | ~0 | 0 |
| Failed AI call (timeout, provider error) | real cost, credit released | ~5 % overhead | 0 |
| **Video kỷ niệm** render | Cloud Run 4 vCPU / 8 GiB × ~90 s + MP4 storage / download | ≈ $0.02 ≈ **520 VND** | video credit |

**Planning figure: 60 VND per assistant credit** (blend of the above + 10 % overhead + safety margin).
**With prompt caching** (the ~3 000-token system prompt is identical on every call → billed at the cached
price): ≈ **30 VND per credit**. This is the single biggest lever on margin (engineering task, see §6).

## 3. How families use it (monthly, whole household: Ba + Mẹ + Người chăm sóc share one pool)

| Persona | Usage | Credits / month | AI cost (60 VND) | With caching |
|---|---|---|---|---|
| Light | ~2 messages/day, 4 photos, 4 summaries | ~80 | ~4 800 VND | ~2 400 |
| Regular | ~5 messages/day, 10 photos, 12 summaries, 10 care questions | ~200 | ~12 000 VND | ~6 000 |
| Heavy (Lumi is the main logger) | ~12 messages/day, 30 photos, 30 summaries, 20 questions | ~500 | ~30 000 VND | ~15 000 |

Subscriptions are rarely used in full: assume **50–60 % average use** of the allowance.

## 4. Proposed plans

| | **Free** | **Plus** | **Pro** |
|---|---|---|---|
| Price / month | 0 | **59 000 VND** | **129 000 VND** |
| Price / year | — | **499 000 VND** (≈ 41 600/month, −30 %) | **1 099 000 VND** (≈ 91 600/month, −29 %) |
| Assistant credits / month | **30** | **300** | **800** |
| Video credits / month | **1** | **5** | **15** |
| Who it is for | try Lumi, light use | regular family | Lumi as the main log, several carers |

Features are the same on every plan; only the allowances differ. Credits reset on the household's
calendar month; rollover, top-ups and family sharing of the subscription are still open (owner list).

### Margin per paying household (per month, before infrastructure)

| | Net revenue | Max AI + video cost (all credits used) | Worst-case margin | Expected cost (55 % use) | Expected margin |
|---|---|---|---|---|---|
| Plus monthly | 45 600 | 18 000 + 3 000 = 21 000 | **54 %** | ~11 500 | **75 %** |
| Plus yearly | 32 200 | 21 000 | **35 %** | ~11 500 | **64 %** |
| Pro monthly | 99 700 | 48 000 + 9 000 = 57 000 | **43 %** | ~31 000 | **69 %** |
| Pro yearly | 70 800 | 57 000 | **19 %** | ~31 000 | **56 %** |
| Free (cost only) | 0 | 1 800 + 520 ≈ 2 300 | — | ~1 400 | — |

With prompt caching every AI cost above halves (Pro yearly worst case → ~52 %).

### Free tier economics

Each active Free household costs ~1 400 VND/month (expected). One Plus subscriber leaves ~34 000 VND
expected profit, so **break-even conversion ≈ 4 %** of active free households (≈ 2 % with caching).
That is why Free gets 30 credits (≈ 1 message a day — enough to feel the value, then upgrade), not more.

## 5. Credit prices per action (proposed changes)

| Action | Today | Proposed | Why |
|---|---|---|---|
| Text task / question / summary / care guidance | 1 | **1** | ~50–60 VND real cost |
| Photo task | 3 | **2** for 1 photo, **+1 per extra photo** | real cost ≈ 1.4 text calls; 3 felt expensive for the most useful feature |
| Health support, questions Lumi asks back, small talk, help, failures, unreadable photo | 0 | **0** | owner rule |
| Video kỷ niệm | video credit | **1 video credit** per render (retries of the same job free) | ~520 VND real cost |

## 6. Risks and levers

1. **Prompt caching** (engineering): keep the static system prompt first and identical so OpenAI bills it
   at the cached price → ~50 % lower AI cost. Do before launch.
2. **Model price / model change**: re-measure cost per credit whenever the prompt or model changes
   (test plan §5a); the credit values stay config.
3. **Abuse**: a household cannot exceed its pool; failures cost us but not the user (~5 %): watch the
   portal "Trợ lý AI" usage screen.
4. **Storage is the largest non-AI cost** (photos and videos accumulate: a busy family can add 1 GB/month
   ≈ 600 VND/month per GB kept, growing every month). Not part of AI credits; needs its own analysis
   (per-plan storage allowance fits the "different usage levels" principle).
5. **Store / tax**: confirm VAT handling and the 15 % programme eligibility.

## 7. Owner decisions needed

1. Prices: Plus 59 000 / 499 000, Pro 129 000 / 1 099 000 (or alternatives).
2. Allowances: Free 30 / Plus 300 / Pro 800 assistant credits; videos 1 / 5 / 15.
3. Photo task 2 credits (+1 per extra photo) instead of 3.
4. Prompt caching before launch (engineering, no product change).
5. Open from earlier: rollover, top-up packs, sharing a subscription across a family.
