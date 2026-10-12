# Sơ cứu trẻ em (v1.1): review and plan

**Sources**
- Figma page "v1.1": 7a–7i and TH01–TH24.
- Spec: `docs/discovery/figma-extract/20-v11-content-features.md`, Parts D–F.
- Screenshots: `img/v11/`.

**Owner decisions, 2026-10-12** (D-058):
- Only the first-aid cluster of v1.1 is built now.
- The Chăm sóc tab keeps its name and gains the 7a entry banner.
- Content is written in the portal and the app reads it.
- Content goes live on dev at once. Prod publishes only after a person with medical credentials approves it in the portal.

## What the design needs

**App screens**
- **7a:** a red entry banner on Chăm sóc.
- **7b:** the index: emergency card (Gọi 115 + Bắt đầu CPR), search, category chips, 25 situations in 4 groups sorted by the baby's age, and saved items.
- **7c:** search over titles, synonyms and body text, with quick chips.
- **Detail pages (7d / 7e, TH01–TH24):** one template —
  - tags, title, lead, hero;
  - optional banner and optional variant switch (age or condition);
  - numbered steps with optional image, chips and tap counter;
  - tone callouts (don't / go to hospital / positive);
  - the seizure-timer tool;
  - disclaimer;
  - bottom bar with "Làm theo từng bước" and, on emergency pages, Gọi 115.
- **7f / 7g:** step mode — one step per screen, large type, tap-to-count dots, screen kept on.
- **7i:** CPR mode — 110/min metronome with beep and haptic, 30:2 ring counter, cycles, pause, "Bé đã thở lại".
- **7h:** Gọi 115 sheet — baby context (age, latest weight, current situation), what to tell the operator, `tel:115`.

**Content (editorial, from the portal):**
- **Categories:** 4.
- **Situations:** 25 (TH01–TH24 plus choking), each holding:
  - code, category, order, emergency flag, monitoring tag, age relevance;
  - title, lead, keywords, icon, hero;
  - banner, variants, steps, callouts, tool;
  - review metadata.
- **CPR protocols:** infant and child.
- **Images:** 31 illustrations and 25 icons.
- **Other:** quick-search chips and the emergency number.

**Per user:** saved situations.

## Architecture
1. **Contracts** (`packages/contracts/src/first-aid.ts`):
   - zod schemas for the pack, with vi/en for every string;
   - limits;
   - status workflow draft → pending → published → retired, as for reference data (P-138).
2. **Server** (`firebase/functions/src/content.ts`):
   - **Storage:**
     - staff edits a draft (`contentDrafts/firstAid`);
     - submitting freezes a version (`contentVersions/{id}`);
     - a different staff member approves it, and on prod that person must hold the expert or admin role;
     - publishing writes the pack to `publicConfig/content_firstAid`, readable by anyone signed in.
   - **Images** are uploaded through a callable as WebP to public Storage at `content/first-aid/{imageId}.webp`. They are immutable, and every new image gets a new id.
   - **Dev seed:** a script loads the Figma text (vi, with an engineering draft in en) and the exported images, then publishes on dev directly.
3. **App** (`lib/features/first_aid/`):
   - **Offline:** it reads the pack through Firestore's offline cache and downloads every image to disk once online. After the first sync, everything works without a network.
   - **Entry banner:** shown only when a pack is available, so on prod it stays hidden until something is approved. Before the first sync, the banner says the guide must download once.
   - **Saved items:** stored in `users/{uid}/settings/firstAid`.
4. **Portal:**
   - "Sơ cứu" under content: a situation list and a structured editor (variants, steps, callouts, chips, images) with a phone preview;
   - an image library, submit and approve, version history.
5. **Tokens:** `danger`, `danger-soft` and `on-danger`, with Night values, for #db4a45 / #fcebe8.

## Decisions taken by engineering (P-141, for owner review)
- **Gọi 115:**
  - The red buttons open the 7h sheet; its "Gọi 115" dials `tel:115` through the OS. Calls are never made automatically.
  - The number is 115, set as `emergencyNumber` in the pack.
  - On emergency pages, the red pill is shown when the situation's `emergency` flag is set (TH01–TH07, TH19, TH20, choking).
- **"Báo cho cả nhà" (sending the user's location to the family):** not built. It needs location permission and a new kind of push, so it waits for an owner decision. The sheet shows the call checklist only.
- **Age:**
  - The age variant defaults from the selected baby's age (under 12 months → "Dưới 1 tuổi").
  - The index is sorted by situation age relevance: newborn-only items move down after 3 months.
- **Variants not drawn** ("Từ 1 tuổi" CPR, "Có dị vật", "Sưng, chảy máu"): drafted from standard first-aid guidance and marked for medical review.
- **Disclaimer:** "Nội dung tham khảo, không thay thế chẩn đoán của bác sĩ." It does not claim an expert review until one is recorded. After that it names the review month (P-133 precedent).
- **Seizure timer:** runs on the page only and is never logged.
- **CPR mode:** a 110/min metronome with an audible beep and a light haptic, the screen kept on, an automatic 30-count, then a prompt for 2 breaths.

## Build steps (each committed and pushed, dev deploys only)
1. Contracts, server (draft / approve / publish / image upload), Rules, Storage rules, tokens, dev seed with the Figma content and images.
2. App: banner, index, search, detail template, step mode, CPR mode, call sheet, saved items, offline sync; tests and goldens in Light and Night, vi and en.
3. Portal: list, editor, preview, images, review and publish.
4. Device run.
