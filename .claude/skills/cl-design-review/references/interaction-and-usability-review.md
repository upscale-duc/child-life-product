# Interaction and usability review

Component rules live in `cl-components` (`actions-and-navigation.md`, `forms-and-feedback.md`); flow
patterns live in `cl-screen-patterns` (`forms-and-multistep-flows.md`, `galleries-and-memories.md`).
This file is what to **check**.

## 1. Who is holding the phone

Review with these people in mind; never assume the mother, and never assume edit rights:

| Person | Context |
|---|---|
| A parent holding a baby | One hand, thumb only, interrupted mid-task |
| A tired parent at 3 a.m. | Night care, low attention, low tolerance for questions |
| A caregiver | Care-only rights; edits only their own entries (History note) |
| A relative | Read-only on most surfaces; may have daily-care access (D-018) |
| A parent of several children | Switching babies; must never log for the wrong one |
| Someone correcting yesterday's entry | History → edit, back-logging |

## 2. Checklist

| Area | Check | Evidence that settles it |
|---|---|---|
| Primary action | Visible in the thumb zone; label names the result; one dominant (D-105) | R |
| Tap targets | ≥ 44 pt (`ClPressable`) and spaced; no tiny overlay icons on photos | C (widget) + R (spacing) |
| Whole-card interaction | One destination per card; no competing inner button with the same destination | R + C |
| Gesture ambiguity | Long-press, swipe and drag are discoverable through a visible alternative | C + H (needs a device) |
| Selection vs creation | Selection uses checks or circles; "+" means add; one mode at a time, visibly | R |
| Forms | Defaults are sensible and their source shown; optional fields secondary; errors near the field; input kept after errors | R + C |
| Keyboard | The primary stays visible above the keyboard; next / done actions; dismiss on tap outside (`ClKeyboardDismiss`) | C + H |
| Back navigation | Back does what users expect; destructive back effects announced (setup's first Back signs out) | C |
| Undo and confirmation | Undo for reversible saves (toast); confirm only irreversible or other-people-affecting actions | C + R |
| Multi-step progress | Progress shown; step count honest; resume after interruption (setup draft is in-memory only) | C |
| Error recovery | Retry exists where the failure is transient; the message says what to do | C + R |
| Disabled actions | The reason is visible when not obvious ("Xong" disabled at 0 trackers) | R |
| One-handed use | Frequent actions bottom-half; no top-corner-only critical actions | R |
| Night interaction | No celebratory motion; big targets; minimal reading | R (Night care goldens) |
| Multi-child | The baby is identified where an action applies to one baby; the switcher is reachable | R + C |
| Success timing | Success feedback only after the real success condition (a local save toast is fine; "shared with family" isn't, until synced) | C |

## 3. Example findings: the shape to aim for

- "In selection mode the floating bar '5 mục đã chọn' covers row 2 of the grid
  (`s9/10b2_select_light_vi`, R). Items under it can't be seen or tapped. Medium."
- "The baby chip on History is a label without `onTap` (`history_screen.dart:358`, C), while the
  same chip opens the picker on tabs. A multi-child parent's tap does nothing. Medium; navigation
  change → owner."
- "The tracker step mixes check tiles and radio-like rows for one multi-select (`s2/12_trackers`,
  R). Parents may think the rows are exclusive. Low; confusion is H until tested."

## 4. Limits

Goldens can't show gestures, timing, haptics or real one-handed reach. Mark such claims **H**
unless tested on a device or with an interaction test.
