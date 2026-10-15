# One-off reminders: date-only (all day) and an assignee (D-075 #5)

Owner decision D-075 #5 (2026-10-15, resolves Q-078): one-off reminders ("Một lần", S7) get a
**date-only (all day)** form and an **assignee**. This plan records the engineering choices. It
extends R-090 (which said "no repeat, no assignee"), R-091, R-093, D-029 … D-032. Rule
reminders (D-051) are unchanged.

## Data (`babies/{b}/reminders/{rm}`, `packages/contracts/src/reminders.ts`)

| Key           | Shape                          | Meaning                                                                             |
| ------------- | ------------------------------ | ----------------------------------------------------------------------------------- |
| `allDay`      | `true`, or absent / `false`    | Absent = timed. Old documents and old clients are therefore unchanged.              |
| `dueDate`     | `YYYY-MM-DD`, or absent / null | The date in the baby's zone. Required when `allDay`; absent or null otherwise.      |
| `dueAt`       | timestamp (always present)     | Timed: the instant (D-032). All day: **23:59 on `dueDate` in the baby's zone**.     |
| `assigneeUid` | uid, or absent / null          | An active Cùng nuôi or Người chăm sóc of the baby. Null or absent means unassigned. |
| `leadMinutes` | as before                      | All day: only `0` ("Đúng ngày") or `1440` ("1 ngày"). Default `0`.                  |

`dueAt` stays on all-day reminders for three reasons. Older apps (which require `dueAt` and order
by it) still list the reminder, as "23:59" on the right day and overdue only once the day has
passed. Ordering stays one query. The Rules keep their "not in the past / ≤ 366 days" check.
New code never reads `dueAt` of an all-day reminder for the day itself. It uses `dueDate`, so a
change of the baby's zone moves nothing (P-014).

**Status (R-093) of an all-day reminder** is by date in the baby's zone. It is upcoming through
the whole of `dueDate` and overdue from the next day. A timed reminder is unchanged.

## All-day notification time

- Each person chooses one **"Giờ nhắc việc cả ngày"** (default **08:00**, in the baby's zone).
  It is kept per install (SharedPreferences `reminders.allDayMinutes`), like the 8c "asked" flag.
- The time is always visible: a "Giờ báo · 08:00" row in the form (under "Cả ngày" and the date)
  and in 8e. A tap on either row changes it; the picker says it applies to every all-day
  reminder on this device, in the baby's time.
  There is never a silent hard-coded 09:00.
- An all-day reminder fires once (D-032) at that time on `dueDate`, or on the day before
  (lead `1440`).

## Assignee

- **Who assigns:** Cùng nuôi, when creating or editing (D-031: Cùng nuôi edit). **Who may be
  assigned:** an active Cùng nuôi or Người chăm sóc (the people who see reminders, D-018).
  Relatives and removed members cannot be assigned. Caregivers still mark done (12f) and cannot
  assign.
- **Labels:** the assignee sees **"Giao cho bạn"**, highlighted (mint) in the 8a row and 8e.
  Everyone else sees **"Giao cho Cô Lan"** (muted). The care hub's caregiver line ("N nhắc giao
  cho bạn", P-127) counts the reminders assigned to them as well as those on their device.
- **Notifications (chosen: in addition to `notifyDevice`):** a device schedules a reminder when
  `notifyDevice` is this install (R-091, unchanged) **or** the signed-in person is the assignee.
  So every install of the assignee rings once it has synced, which happens when the app opens.
  This is still no server push (R-091), because each device schedules only its own local
  notification. The notification id comes from the reminder id, so one device never rings twice.
  - When the reminder is created for **someone else**, `notifyDevice` is left empty, so the
    creator's phone does not ring for a job that is not theirs. The creator, or anyone, can still
    take a copy with 8e "Thông báo → máy này" (D-029).
  - When it is assigned to oneself, or left unassigned, it behaves as before: the creating device
    holds it.
  - The limitation: an assignee who has not opened the app since the assignment gets no
    notification yet. 8e says "Trên máy của Cô Lan" so nobody is misled.
- An assignee who later leaves keeps the uid on the reminder, and it shows as unassigned. Edits
  that do not touch `assigneeUid` still pass the Rules.

## Rules (`validNewReminder` / `validReminderFields` / `validReminderUpdate`)

- The new keys are optional, so old clients' writes are unchanged. The checks:
  - `dueDate` is a real `YYYY-MM-DD` date (`timestamp.date`).
  - `allDay` and `dueDate` are consistent with each other.
  - `dueAt` falls within that date's 23:59 in some zone (UTC−12 … +14).
  - The lead is `0` or `1440` for all-day reminders.
  - `assigneeUid` names an active coParent / caregiver member of the baby. This is checked when it
    is set or changed.
- Only Cùng nuôi change `allDay`, `dueDate` or `assigneeUid`.
- Known old-client effect: an older app editing an all-day reminder to a lead other than 0 or
  1 ngày, or to another day, is refused, and shows its existing "Chưa lưu được" toast.

## Assistant (CH13)

- `reminderNeedsTime()` is now `false`, so a note line with a date and no time becomes an
  all-day draft. `reminderAssigneeSupported()` is now `true`.
- Note prepare: when a line carries a written name (`assigneeText`), the person is asked
  "Giao việc này cho ai?". The choices are the eligible members (up to 5) and "Không giao". A
  name read from the photo is never turned into a uid, and one round is used per line, within
  the existing cap. Lines with no name are unassigned.
- Writer: it writes `allDay` / `dueDate` (lead 0) for date-only drafts and `assigneeUid` after
  re-reading the member in the confirm transaction. If that member is not eligible, the result
  is `VALIDATION_FAILED` / `INVALID_ASSIGNEE`. As before, the writer sets no device. Unassigned
  reminders still need someone to take the notification with "Thông báo → máy này".

## Tests

- Contracts: shape, status by date, fire time.
- Rules: old and new documents, a bad date, a bad assignee, caregiver limits.
- Functions: assistant-images integration (date-only, assignee choice, bad assignee).
- App:
  - model tests;
  - widget tests: the form's all-day toggle, the assignee picker, list labels, the notification
    plan for all-day and assigned reminders;
  - goldens (Light / Night × vi / en) for 8a, 8b all day, and 8e assigned.
