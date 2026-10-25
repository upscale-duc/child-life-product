# Storyboard: Product Introduction V2 (rev 2)

All timings are estimates and have not been checked against a recorded voice-over. Times are in seconds; frame numbers are at 30fps and count from 0 within each scene. Coordinates and layer states are in `timeline.json`. Full motion notes are in the `Notes · PIxx` frame next to each scene in Figma.

**Arc:**
1. Vision (PI01)
2. A moderately busy everyday life (PI02–03)
3. The moment that slips by (PI04)
4. Things come together as Child Life appears (PI05)
5. An open, coordinated life where the whole family takes part (PI06–09)
6. A gentle ending that returns to the vision (PI10)

**What changed in rev 2:**
- New vision opening (PI01).
- Two new benefit scenes: logging in a tap, plus handoff (PI06); Lumi, plus age-based ideas and reminders (PI07).
- Photos audited and replaced (see `assets.md`).
- Scenes renumbered: PI01–PI08 from rev 1 became PI02–PI05 and PI08–PI10, and the old InSync scene was folded into PI06.

---

## PI01 · Vision (0–8s): new

**Figma frames:** START `852:81632` · HERO `852:81653` · END `852:81674`

**Voice-over (proposed):** "Every child grows up one moment at a time. Child Life is here to walk alongside your family — starting with the very first year."

**On-screen text:**
- Headline: "Growing up,"
- Headline/2: "one moment at a time."
- SupportingText: "Child Life walks alongside your family — starting with the very first year."

**Stage chips:**

| Chip | Label |
|---|---|
| 0–12 months | In the app now |
| 1–3 years | Coming next |
| 3–6 years | In the future |
| 6–12 years | In the future |

**Action:**
- The sun rises.
- The thread draws a path from the newborn photo up toward the sun, passing four photo stations: newborn, toddler at the beach, preschooler drawing, school-age child reading.
- Future stations use a dashed ring at 0.88 opacity.
- At END, the camera pushes into the 0–12 months circle.

**Transition:** the newborn photo becomes the starting point for PI02.

## PI02 · Firsts (8–14s)

**Figma frames:** `844:10487` / `844:10493` / `844:10500`

**Voice-over:** "Life with a little one is full of firsts. And a lot to keep track of."

**On-screen text:** "Full of firsts." / "And a lot to keep track of."

**Action:** Photo/motherbaby (a mother holding her baby) slides to the right, then three Card/Note pop up around it.

**Transition:** the photo shrinks into a polaroid.

## PI03 · Juggle (14–23s)

**Figma frames:** `844:10513` / `844:10522` / `844:10548`

**Voice-over:** "The last feed. The next nap. The little updates you share so everyone knows how the day is going."

**On-screen text:** "The last feed. The next nap." / "The little updates, so everyone knows how the day is going."

**Action:**
- Notes, two generic message bubbles (not Child Life UI) and family avatars appear in step with the voice-over.
- The thread tangles.
- The pace is moderate: no red, no shaking, no stacked notifications.

**Transition:** hold 6f.

## PI04 · Moment (23–30s)

**Figma frames:** `844:10575` / `844:10590` / `844:10607`

**Voice-over:** "And somewhere between it all, another first happens. A smile. A sound. A moment you want to remember."

**On-screen text:** "A smile. A sound." / "A moment you want to remember."

**Action:**
- The notes fade.
- Photo/smile (a smiling baby next to mum) grows.
- At END, the photo drifts to a corner: the moment slips by.

**Transition:** the thread pulls taut, then about 0.5s of silence.

## PI05 · Meet (30–37s): the turning point

**Figma frames:** `844:10623` / `844:10635` / `844:10651`

**Voice-over:** "Meet Child Life. A shared space for caring for your child, and keeping their story close."

**On-screen text:** Logo · "A shared space for caring for your child," / "and keeping their story close."

**Action:**
- Everything converges into the logo, and the thread becomes the band under it.
- At END, each note fades out exactly where its real UI appears:
  - "Last feed" → the Bú bình tile (feeding) on Hôm nay (Today).
  - "Vaccine · Sat" → the reminder for the 6-in-1 vaccine on Saturday.

## PI06 · QuickCare (37–47s): new

**Figma frames:** START `853:11464` · HERO `853:11470` · END `853:11558`

**Voice-over (proposed):** "Log a feed in a tap — from a home-screen widget, your Apple Watch, or just by asking Siri. So whoever looks after your little one next can pick up where you left off."

**On-screen text:**
- "Log it in a tap." · "Phone widget · Apple Watch · Siri"
- Then: "Pick up where they left off."

**Action:**
1. Photo/feeding (bottle feeding).
2. UICrop/Widget, with a tap on "+".
3. AppScreen/AppleWatch.
4. Card/Siri: the command, then "Saved…".
5. END:
   - Photo/father (dad holding the newborn).
   - Card/BanGiao, the "Bàn giao cho người chăm tiếp" (handoff to the next carer) card.
   - Member cards for Mai and Cô Lan.
   - The Bú bình tile.

**Transition:** the thread loops up toward Lumi.

## PI07 · Lumi (47–58s): new

**Figma frames:** START `853:11612` · HERO `853:11630` · END `853:11762`

**Voice-over (proposed):** "Or just tell Lumi what happened — it drafts the log for you to check. And each day brings ideas that fit your child's age, with reminders right when they matter."

**On-screen text:**
- "Tell Lumi." / "It drafts the log for you." · "You check it, then save."
- Then: "Ideas that fit their age." / "Reminders when they matter."

**Action:**
1. The Lumi button pops in.
2. UICrop/Lumi_Drafts opens from it. This is the real CH04 screen: one message becomes two drafts, with the button "Lưu 2 mục đã chọn" (save 2 selected). The usage-quota line is hidden.
3. END:
   - Card/GoiYHomNay: the "Đi dạo ngoài trời" (walk outdoors) suggestion.
   - List/NhacViec: the reminders list.

**Not shown:** no typing animation; nothing implies Lumi saves on its own.

## PI08 · Grow (58–66s)

**Figma frames:** `845:80828` / `845:80888` / `845:81011`

**Voice-over:** "Follow the little changes. Celebrate the firsts. And bring your family along as your child grows."

**On-screen text:** "Celebrate the firsts." / "And bring your family along as your child grows."

**Action:**
- The growth line draws in. It has no assessment.
- Card/Milestone "Mỉm cười đáp lại" (smiling back), with a photo of the baby smiling and one of the family.
- UICrop/Album_CaNha: the album is renamed "Cả nhà mình" (our family), with a family photo on the cover. Family avatars below.

**Transition:** the album photos → PI09.

## PI09 · Keepsakes (66–78s): emotional peak

**Figma frames:** `846:10940` / `846:10953` / `846:11006`

**Voice-over:** "Turn everyday photos into keepsakes you can return to—because the days you're living now are the memories you'll treasure later."

**On-screen text:**
- "Everyday photos," / "turned into keepsakes."
- Then: "The days you're living now" / "are the memories you'll treasure later."

**Action:**
- Four photos sit on the thread: newborn in a basket, tiny feet, sleeping, feet in a parent's hands.
- The "1 tháng" (1 month) card flips, then the video "Tháng đầu tiên của Teddy" (Teddy's first month) opens and grows.

## PI10 · Hold (78–90s)

**Figma frames:** `846:11051` / `846:11060` / `846:11073`

**Voice-over:** "Less to keep track of. More to hold on to. Child Life. Growing together, every step of the way."

**On-screen text:**
- "Less to keep track of." / "More to hold on to."
- Logo · "Growing together, every step of the way." · "childlife.app · Coming soon to iPhone & Android"

**Action:**
- The thread climbs to the sun with three photos on it: newborn → toddler → child. This returns to the vision from PI01.
- The thread then becomes the band under the logo.
- Hold for at least 4s. Do not fade to black.
