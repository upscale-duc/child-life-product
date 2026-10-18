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

## Applied on 2026-10-18

`pack.seed.json` is now this pack, with the 22 pictures that passed review in `../images/`. Two
pictures failed review and their steps show no picture until they are redrawn
(`docs/product/content-review-2026-10/first-aid-image-prompts.md`): `an-nguc-hai-ngon-cai`
(choking under-1, step 2) and `mo-duong-tho-so-sinh` (CPR under-1, step 2). When they arrive,
set those two `image` fields back. The decisions in `REVIEW.md` §5 are recorded in D-078 #5.
