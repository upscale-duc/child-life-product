# Sơ cứu: reviewed pack, proposed (2026-10-16)

`pack.proposed.json` is `../pack.seed.json` with the 2026-10-16 review applied (`REVIEW.md`): an
engineering draft in a paediatric-emergency role against AHA/AAP 2025, ERC 2025, ILCOR, WHO and
NICE. It is **not** a clinical sign-off; `review` stays `null`.

- 25 situations corrected, 10 added (drowning, unconscious-but-breathing, head injury, swallowed
  object / button battery / magnet, electric shock, chemical burn, mild allergy, asthma attack,
  breath-holding, dental injury): 35 of the 40 allowed. It validates against `firstAidPackSchema`.
- **P0 fixes:** infant CPR and infant chest thrusts no longer use two fingers (two thumbs encircling
  or the heel of one hand); choking from 1 year alternates 5 back blows and 5 abdominal thrusts and
  says to start CPR when the child goes limp; anaphylaxis leads with the adrenaline auto-injector
  (lie down, no standing, second dose, always hospital); snake bite splints the whole limb (no
  "light bandage at the bite").
- **No number in the text.** Every "115" is `{emergency}` (and `{poison}` on the poisoning page).
  The app fills them from the pack (`FirstAidPack.fillTokens`, apps/mobile); `{poison}` falls back
  to the emergency number until a per-country poison line exists. Old app builds would show the
  token literally: ship the app first.

## Why it is not `pack.seed.json` yet

1. **Pictures.** `images.json` lists 23 new pictures and 6 to redraw. Two are P0: `ep-tim-so-sinh`
   and `an-nguc` show the two-finger technique and must not ship next to the corrected text. The
   new situations need their icon and hero before the pack can be published.
2. **Decisions for the clinician / owner** (`REVIEW.md` §5): rescue breaths first (ERC, used here)
   or compressions first (AHA / ANZCOR) — per country if both; snake-bite wording per region;
   which poison lines to list.
3. `apps/mobile/test/helpers/first_aid_fixtures.dart` and the goldens read `pack.seed.json`; swap it
   in one change with the new pictures and refreshed goldens.

When the pictures exist: put them in `../images/`, replace `pack.seed.json` with this file, run
`flutter test` (refresh first-aid goldens), then publish on dev through the content-release tool
(`docs/operations/content-release.md`).
