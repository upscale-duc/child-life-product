# 05 · Notification templates

**P-174.** Code:

- contract `notificationTemplates`, `notificationPlaceholders`, `validateTemplateCopy`, `renderTemplate`
- `firebase/functions/src/notification-templates.ts` (staff workflow)
- `notification-runtime.ts` (what a send reads)
- Portal `apps/portal/src/screens/notifications/Templates.tsx`, `TemplateEditor.tsx`

## 1. Model

There are 21 templates, one per message variant (for example `care.vaccine_eve`, `spending.import_failed`, `eng.weekly_recap`). Each declares its kind, a vi/en name, its allowed placeholders, the required ones, sample values, and **version 0, the built-in copy**.

Version 0 is exactly what the producer sent before the Portal existed. `firebase/functions/test/notification-templates.test.ts` renders every built-in with the producer's values and compares the result with the producer's own copy function for every variant: plural and singular, with and without a last log, one dose and several, every ENG kind.

| Status | Meaning at send time |
| --- | --- |
| builtin | Never published: version 0. |
| draft / ready_for_review | A draft waits on top of the live copy. Sending uses the live copy. |
| published | `live.version` (≥ 1) is rendered with the producer's values. |
| paused | Version 0 is used. **Sending never stops because of a template**; stopping pushes is the job of the kill switches. |
| archived | Like paused, and hidden by default in the list. |

Sending reads `notificationTemplates/{id}`, cached for 60 s per instance. The ops switch `templatesEnabled: false` forces version 0 everywhere.

If a published copy cannot be rendered, the send uses version 0 and counts `render_error`. That happens when a required value is missing and has no fallback, or when the copy no longer validates against the registry.

Every inbox row and ledger entry records `templateId` and `templateVersion` (0 = code), so history keeps the exact version used.

## 2. Workflow and permissions

| Step | Action | Permission | Server check |
| --- | --- | --- | --- |
| Save draft | `staffSaveNotificationTemplate` | `notifications.edit` (ops, expert, admin, owner) | Full validation; refused with `template-invalid` + issues |
| Submit for review | `staffNotificationTemplateAction {submit}` | edit | A draft exists |
| Discard draft | `{discard}` | edit | A draft exists |
| Publish | `{publish, note}` | `notifications.publish` (expert, admin, owner) | The draft was submitted and validates; creates immutable `versions/{n}` and points `live` at it. Self-approval is allowed but recorded (`selfApproved`). |
| Pause / resume / archive | `{pause}` `{resume}` `{archive}` | publish | Status preconditions |
| Rollback | `{rollback, version}` | publish | Version ≤ latest; 0 = back to code. Versions are never edited. |

Every mutation writes `staffAudit` with category `notifications` and action `notifications.template.<step>`.

## 3. Placeholders

Staff can place approved placeholders but never define them. Values are computed by the producer: numbers, or per-language strings.

| Placeholder | Type | Sensitivity | Fallback | Max |
| --- | --- | --- | --- | --- |
| count, pending_count, percent, gb | number | safe | 1 / — / 80 / — | 3–6 |
| actor_name | text | member name (the family member's own display name, as R-120's drawn copy) | "Người thân" / "A family member" | 40 |
| baby_name | text | child name (D-094: the baby's nickname, so a parent of several babies can tell pushes apart; filled per recipient, and a recipient with "Hiện tên bé trong thông báo" off gets the fallback; never written to the ledger, logs or analytics) | "bé" / "your baby" | 30 |
| activity_name, last_logged_line, dose_list, age_label, import_summary, milestone_label, activity_title | per-language text | safe | per registry | 30–120 |

Syntax: `{{name}}`, plus `{{plural:count|one|other}}` (the other branch may contain `{{count}}`). The rendered title and body start with a capital letter (so "bé sắp tròn…" reads "Bé sắp tròn…").

The validator rejects:

- unknown or disallowed placeholders
- `plural` on a non-number
- a dropped required placeholder
- empty text
- rendered length over the maximum (title 65, body 178; recommended 40 and 110)
- URLs, markup and `${`

There is no child name, DOB, caption, care value or free text in the registry, so none can ever be rendered (R-120).

## 4. Editor (Portal)

- **Copy:** VI/EN title and body; a placeholder picker that inserts at the cursor; inline issues; character counts on the rendered sample.
- **Preview:** editable sample values; iOS and Android lock-screen previews in either language; a destination preview (screen, permission, fallback chain, completion).
- **Actions:** save, submit, discard, publish with a note, pause, resume, archive, and rollback from the version history ("Phiên bản 0 (trong mã)" included).
- **Safety:** a leave guard for unsaved edits.

Routine copy changes need no app release: copy is server-rendered into the push and the row.
