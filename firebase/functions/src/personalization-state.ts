import type { Firestore } from 'firebase-admin/firestore';
import {
  activeAt,
  responseSuppresses,
  type NotebookNote,
  type PersonalizationState,
} from '@child-life/contracts';

/** P-172: call only after authorizing the member; personal state belongs to this caller. */
export async function personalFilters(
  db: Firestore,
  babyId: string,
  uid: string,
  now: Date,
  includePersonal = true,
) {
  const [personal, notes, excluded] = await Promise.all([
    db.doc(`users/${uid}/personalization/${babyId}`).get(),
    db.collection(`babies/${babyId}/notebook`).limit(200).get(),
    db.collection(`babies/${babyId}/personalizationExclusions`).get(),
  ]);
  const state = (personal.data() ?? {}) as PersonalizationState;
  const hidden = new Set(excluded.docs.filter((d) => d.get('active') === true).map((d) => d.id));
  const visibleNotes = notes.docs
    .map((d) => d.data() as NotebookNote)
    .filter((n) => activeAt(n.expiresAt, now) && (n.scope === 'baby' || n.authorUid === uid));
  for (const note of visibleNotes)
    if (note.scope === 'baby' && note.avoidActivityId) hidden.add(note.avoidActivityId);
  for (const [id, response] of Object.entries(includePersonal ? (state.responses ?? {}) : {}))
    if (responseSuppresses(response, now)) hidden.add(id);
  const context =
    includePersonal && state.context && activeAt(state.context.expiresAt, now)
      ? state.context.value
      : 'usual';
  return {
    hidden,
    maxMinutes: ['busy', 'few_minutes'].includes(context) ? 5 : null,
    notes: visibleNotes,
  };
}
