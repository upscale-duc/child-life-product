import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_repository.dart' show babyDateBounds;
import '../care_plan/care_plan_log.dart' show carePlanLogType;
import '../care_plan/care_plan_models.dart';
import '../care_plan/care_plan_widgets.dart'
    show carePlanCapitalized, carePlanTaskLabel, carePlanTaskName;
import '../reminders/reminder_screens.dart' show assigneeName;

/// Cùng Chăm Con widgets (Figma 1356:23340): today's plan as the widgets need it. Parents get
/// "Việc của Ba" (the next task of theirs, with Xong) and the family's progress; a helper with
/// tasks gets "Việc của Cô Lan", their list. Tasks that write a log or start the sleep timer
/// (D-138) open the app for "Xong"; the others are ticked from the widget. Only catalogue names,
/// a custom task's own title, times and family relations; never a photo or a care value.
///
/// Null without a plan the person can tick today (none, a draft, or a relative).
Map<String, Object?>? glancePlanJson({
  required AppLocalizations l10n,
  required Membership me,
  required String zone,
  required String date,
  required CarePlanDay? day,
  required List<CarePlanItem>? items,
  required List<Membership> members,
}) {
  if (day == null || day.draft || items == null || !carePlanCanComplete(me)) {
    return null;
  }
  final start = babyDateBounds(zone, DateTime.parse(date)).start;
  int dueAt(String time) {
    final p = time.split(':');
    return start
        .add(
          Duration(
            hours: int.tryParse(p.first) ?? 0,
            minutes: int.tryParse(p.last) ?? 0,
          ),
        )
        .millisecondsSinceEpoch;
  }

  final active = sortedPlan(items.where((i) => !i.skipped));
  // The family's faces on "Cả nhà 2/10": everyone who has a task today, Ba and Mẹ first.
  final faces = <String>[];
  for (final m in members) {
    if (active.any((i) => i.assignees.contains(m.uid)) &&
        !faces.contains(glancePersonArt(m))) {
      faces.add(glancePersonArt(m));
    }
  }
  return {
    'date': date,
    'helper': me.role == MemberRole.caregiver,
    // "Việc của Ba" / "Việc của Cô Lan": what the family calls this person.
    'me': carePlanCapitalized(
      assigneeName(l10n, me, '').trim().isEmpty
          ? l10n.glanceYou
          : assigneeName(l10n, me, ''),
    ),
    'faces': faces.take(4).toList(),
    'names': {
      for (final t in CarePlanTask.values) t.name: carePlanTaskLabel(l10n, t),
    },
    'items': [
      for (final i in active)
        {
          'id': i.id,
          'time': i.time,
          'dueAt': dueAt(i.time),
          'task': i.task.name,
          'name': carePlanTaskName(l10n, i),
          'mine': i.assignees.contains(me.uid),
          'done': i.done,
          'opensApp':
              carePlanLogType(i.task) != null || i.task == CarePlanTask.sleep,
        },
    ],
  };
}

/// The widget picture of a member (Figma CCC/Person), as the app's `carePlanPersonArt`.
String glancePersonArt(Membership m) => switch (m.relation) {
  Relation.father => 'PersonBa',
  Relation.mother => 'PersonMe',
  Relation.grandmother => 'PersonBaNoi',
  Relation.grandfather => 'PersonOng',
  Relation.nanny => 'PersonHelper',
  _ => m.role == MemberRole.caregiver ? 'PersonHelper' : 'PersonBa',
};
