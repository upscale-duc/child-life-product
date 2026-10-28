// Isolated design proposal. No Firebase writes, production routes or permission changes.
// Run from apps/mobile: test/design_explorations/care_coordination/run_web_preview.sh
import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/core/widgets/cl_button.dart';
import 'package:child_life/core/widgets/cl_icon.dart';
import 'package:child_life/core/widgets/cl_inputs.dart';
import 'package:child_life/core/widgets/cl_pressable.dart';
import 'package:child_life/core/widgets/cl_rows.dart';
import 'package:child_life/core/widgets/cl_sheet.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'preview_copy.g.dart';

void main() => runApp(const CoordinationApp());

enum CareView {
  overview,
  assignment,
  outgoing,
  incoming,
  simple,
  routine,
  family,
  notifications,
  gratitude,
  quickAction,
}

enum PreviewState { ready, offline, empty, loading, error, relative }

class CoordinationApp extends StatefulWidget {
  const CoordinationApp({super.key});
  @override
  State<CoordinationApp> createState() => _CoordinationAppState();
}

class _CoordinationAppState extends State<CoordinationApp> {
  var palette = ClPalette.light;
  var language = 'vi';
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildClTheme(palette),
    locale: Locale(language),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(ClSpace.s4),
            children: [
              Text(
                previewCopy[language]!['preview']!,
                style: context.cl.text.title2,
              ),
              const SizedBox(height: ClSpace.s4),
              Wrap(
                spacing: ClSpace.s2,
                children: [
                  ClButton(
                    label: 'VI / EN',
                    style: ClButtonStyle.secondary,
                    onPressed: () => setState(
                      () => language = language == 'vi' ? 'en' : 'vi',
                    ),
                  ),
                  ClButton(
                    label: 'Light / Night care',
                    style: ClButtonStyle.secondary,
                    onPressed: () => setState(
                      () => palette = palette == ClPalette.light
                          ? ClPalette.nightCare
                          : ClPalette.light,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClSpace.s4),
              for (final view in CareView.values)
                ClListRow(
                  title: previewCopy[language]![viewTitle(view)]!,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CoordinationPreview(initialView: view),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

String viewTitle(CareView v) => switch (v) {
  CareView.overview => 'overview',
  CareView.assignment => 'assignTitle',
  CareView.outgoing => 'outgoing',
  CareView.incoming => 'receiveTitle',
  CareView.simple => 'mine',
  CareView.routine => 'routineTitle',
  CareView.family => 'family',
  CareView.notifications => 'notificationTitle',
  CareView.gratitude => 'gratitude',
  CareView.quickAction => 'quickActionTitle',
};

/// Fixed mock data. Proposed features stay outside lib/ until Q-085 and the spec are approved.
class CoordinationPreview extends StatefulWidget {
  const CoordinationPreview({
    this.initialView = CareView.overview,
    this.state = PreviewState.ready,
    this.carerName,
    super.key,
  });
  final CareView initialView;
  final PreviewState state;
  final String? carerName;
  @override
  State<CoordinationPreview> createState() => _CoordinationPreviewState();
}

class _CoordinationPreviewState extends State<CoordinationPreview> {
  late CareView view = widget.initialView;
  late PreviewState scenario = widget.state;
  var assignee = 'dad';
  var storyAssignee = 'unassigned';
  var due = '18:30';
  var selectedTask = 'bath';
  var assigned = false;
  var sent = false;
  var received = false;
  var completed = false;
  var acceptedTask = false;
  var thanksSent = false;
  var taskNotices = true;
  var handoverNotices = true;
  var thanksNotices = false;
  var preferencesSaved = false;
  var unlocked = false;
  var pendingQuick = false;
  var applied = false;
  var logged = false;
  var declined = false;
  late final bool caregiver = widget.initialView == CareView.simple;
  bool get readOnly => scenario == PreviewState.relative;
  final note = TextEditingController();
  final amount = TextEditingController();
  String? amountError;
  String t(String key) => key == 'carer' && widget.carerName != null
      ? widget.carerName!
      : previewCopy[Localizations.localeOf(context).languageCode]![key]!;
  bool get vi => Localizations.localeOf(context).languageCode == 'vi';
  bool get offline => scenario == PreviewState.offline;
  @override
  void dispose() {
    note.dispose();
    amount.dispose();
    super.dispose();
  }

  void go(CareView next) => setState(() {
    view = next;
    declined = false;
  });

  Widget text(String key, {bool muted = false}) => Text(
    t(key),
    style: context.cl.text.label.copyWith(
      color: muted ? context.cl.colors.inkMuted : context.cl.colors.ink,
    ),
  );
  Widget section(String key, {String? link, VoidCallback? onLink}) => Padding(
    padding: const EdgeInsets.only(top: ClSpace.s6, bottom: ClSpace.s3),
    child: ClSectionHeader(
      title: t(key),
      linkLabel: link == null ? null : t(link),
      onLink: onLink,
    ),
  );
  Widget group(List<Widget> children, {Color? color}) =>
      ClCardGroup(color: color, children: children);
  Widget row(
    String title,
    String? subtitle, {
    ClIcons? icon,
    VoidCallback? onTap,
  }) => ClListRow(
    title: t(title),
    subtitle: subtitle == null ? null : t(subtitle),
    leading: icon == null
        ? null
        : ClIcon(icon, color: context.cl.colors.mintText),
    onTap: onTap,
  );
  Widget action(
    String key,
    VoidCallback? onPressed, {
    ClButtonStyle style = ClButtonStyle.primary,
  }) => ClButton(
    label: t(key),
    onPressed: onPressed,
    style: style,
    expand: true,
    wrapLabel: true,
  );
  Widget notice(String key) => group([
    Padding(padding: const EdgeInsets.all(ClSpace.s4), child: text(key)),
  ], color: context.cl.colors.sunshineSoft);
  Widget status() => group([
    Padding(
      padding: const EdgeInsets.all(ClSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClIcon(ClIcons.family, color: context.cl.colors.mintText),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text('current', muted: true),
                const SizedBox(height: ClSpace.s1),
                Text(
                  received ? t('dad') : t('carer'),
                  style: context.cl.text.title2,
                ),
                text(received ? 'receivedMeta' : 'shift', muted: true),
              ],
            ),
          ),
        ],
      ),
    ),
    row('awake', null, icon: ClIcons.sunrise),
  ]);
  Widget taskRow(String key) {
    final isBath = key == 'bath';
    final owner = isBath ? assignee : storyAssignee;
    return ClListRow(
      title: t(key),
      subtitle: completed && isBath
          ? t('done')
          : '${isBath ? due : '19:30'} · ${t(owner)} · ${t('pending')}',
      leading: ClIcon(
        completed && isBath
            ? ClIcons.check
            : isBath
            ? ClIcons.drop
            : ClIcons.journal,
        color: context.cl.colors.mintText,
      ),
      onTap: caregiver || readOnly || view == CareView.incoming
          ? null
          : () {
              selectedTask = key;
              go(CareView.assignment);
            },
    );
  }

  Widget facts() => group([
    row('feedFact', 'feedValue', icon: ClIcons.feed),
    row('diaperFact', 'diaperValue', icon: ClIcons.diaper),
  ]);
  Widget nextTasks() => group([taskRow('bath'), taskRow('story')]);

  List<Widget> overview() => [
    text('child', muted: true),
    const SizedBox(height: ClSpace.s4),
    if (scenario == PreviewState.relative) ...[
      notice('noAccess'),
      section('current'),
      status(),
      section('now'),
      facts(),
    ] else ...[
      status(),
      const SizedBox(height: ClSpace.s3),
      text('nextShift', muted: true),
      if (scenario == PreviewState.loading) ...[
        section('next'),
        text('loading'),
      ] else if (scenario == PreviewState.error) ...[
        section('next'),
        notice('loadError'),
        action(
          'retry',
          () => setState(() => scenario = PreviewState.ready),
          style: ClButtonStyle.secondary,
        ),
      ] else ...[
        section(
          'next',
          link: caregiver ? null : 'assign',
          onLink: () => go(CareView.assignment),
        ),
        if (scenario == PreviewState.empty)
          group([row('empty', 'emptyBody')])
        else
          nextTasks(),
        section('now'),
        facts(),
        const SizedBox(height: ClSpace.s4),
        if (!caregiver)
          row(
            'routine',
            'routineMeta',
            icon: ClIcons.calendar,
            onTap: () => go(CareView.routine),
          ),
      ],
    ],
  ];

  Future<void> choosePerson({bool story = false}) => showClSheet<void>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: t('who')),
        for (final p in ['dad', 'mom', 'carer', 'unassigned'])
          ClListRow(
            title: t(p),
            leading: ClIcon(
              (story ? storyAssignee : assignee) == p
                  ? ClIcons.check
                  : ClIcons.profile,
            ),
            onTap: () {
              setState(() {
                if (story) {
                  storyAssignee = p;
                } else {
                  assignee = p;
                }
                assigned = false;
              });
              Navigator.of(sheet).pop();
            },
          ),
      ],
    ),
  );
  Future<void> chooseTime() => showClSheet<void>(
    context: context,
    builder: (sheet) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClSheetHeader(title: t('editTime')),
        for (final time in ['18:00', '18:30', '19:00', '19:30'])
          ClListRow(
            title: time,
            onTap: () {
              setState(() {
                due = time;
                assigned = false;
              });
              Navigator.of(sheet).pop();
            },
          ),
      ],
    ),
  );
  List<Widget> assignment() => [
    section('what'),
    group([row(selectedTask, null, icon: ClIcons.bell)]),
    section('who'),
    group([
      ClListRow(
        title: t(selectedTask == 'story' ? storyAssignee : assignee),
        leading: const ClIcon(ClIcons.profile),
        onTap: () => choosePerson(story: selectedTask == 'story'),
      ),
    ]),
    section('when'),
    group([
      ClListRow(
        title: due,
        subtitle: t('child'),
        leading: const ClIcon(ClIcons.clock),
        onTap: chooseTime,
      ),
    ]),
    section('notify'),
    text('notifyInfo', muted: true),
    if (assigned) ...[const SizedBox(height: ClSpace.s4), notice('assigned')],
  ];
  List<Widget> handover({required bool incoming}) => [
    text(incoming ? 'receiveMeta' : 'outMeta', muted: true),
    const SizedBox(height: ClSpace.s4),
    if (received) ...[
      notice('receivedMeta'),
      const SizedBox(height: ClSpace.s3),
    ],
    status(),
    section('facts'),
    text('period', muted: true),
    const SizedBox(height: ClSpace.s3),
    group([
      row('feeds', null, icon: ClIcons.feed),
      row('sleep', null, icon: ClIcons.sleep),
      row('feedFact', 'feedValue', icon: ClIcons.clock),
    ]),
    section('pending'),
    nextTasks(),
    section('note'),
    if (incoming)
      text('noteValue')
    else
      ClTextField(
        controller: note,
        placeholder: t('noteValue'),
        maxLength: 300,
        maxLines: 3,
        standalone: true,
      ),
    if (incoming && !received) ...[
      const SizedBox(height: ClSpace.s4),
      text('receiveEffect', muted: true),
    ],
    if (declined) ...[const SizedBox(height: ClSpace.s3), notice('declined')],
    if (sent) ...[section('sent'), text('sentBody')],
  ];
  Future<void> logFeed() async {
    amount.clear();
    amountError = null;
    await showClSheet<void>(
      context: context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: t('formBottle')),
            ClTextField(
              label: t('amount'),
              controller: amount,
              keyboardType: TextInputType.number,
              onChanged: (_) => update(() => amountError = null),
              standalone: true,
            ),
            if (amountError != null)
              Text(
                amountError!,
                style: context.cl.text.label.copyWith(
                  color: context.cl.colors.error,
                ),
              ),
            const SizedBox(height: ClSpace.s3),
            action('logSave', () {
              final value = int.tryParse(amount.text);
              if (value == null || value <= 0) {
                update(() => amountError = t('invalidAmount'));
                return;
              }
              setState(() => logged = true);
              Navigator.of(sheet).pop();
            }),
          ],
        ),
      ),
    );
  }

  void actOnTask() => setState(() {
    if (completed) {
      completed = false;
      acceptedTask = false;
    } else if (acceptedTask) {
      completed = true;
    } else {
      acceptedTask = true;
    }
  });
  List<Widget> simple() => [
    text(received ? 'receivedMeta' : 'dayTime', muted: true),
    section('next'),
    group([
      row(
        received ? 'bath' : 'wash',
        completed
            ? 'done'
            : acceptedTask
            ? 'acceptedTask'
            : received
            ? 'bathMeta'
            : 'washMeta',
        icon: completed ? ClIcons.check : ClIcons.drop,
      ),
    ]),
    if (acceptedTask && !completed)
      action(
        'releaseTask',
        () => setState(() => acceptedTask = false),
        style: ClButtonStyle.plain,
      ),
    section('quickLog'),
    group([
      row('logBottle', 'logBottleMeta', icon: ClIcons.feed, onTap: logFeed),
      row(
        'logDiaper',
        'logDiaperMeta',
        icon: ClIcons.diaper,
        onTap: () => showClSheet<void>(
          context: context,
          builder: (sheet) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClSheetHeader(title: t('logDiaper')),
              ClListRow(
                title: t('diaperValue'),
                onTap: () {
                  setState(() => logged = true);
                  Navigator.of(sheet).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ]),
    if (logged) ...[const SizedBox(height: ClSpace.s3), notice('logged')],
    section('now'),
    facts(),
    const SizedBox(height: ClSpace.s4),
    row(
      'checkHandover',
      null,
      icon: ClIcons.family,
      onTap: () => go(CareView.incoming),
    ),
  ];
  List<Widget> routine() => [
    notice(applied ? 'routineApplied' : 'routineInfo'),
    section('evening'),
    group([
      ClListRow(
        title: t('routineBath'),
        subtitle: t(assignee),
        onTap: choosePerson,
      ),
      ClListRow(
        title: t('routineStory'),
        subtitle: t(storyAssignee),
        onTap: () => choosePerson(story: true),
      ),
    ]),
    const SizedBox(height: ClSpace.s4),
    text('notifyInfo', muted: true),
  ];
  List<Widget> family() => [
    text('familyTitle', muted: true),
    const SizedBox(height: ClSpace.s4),
    group([
      row('mai', 'owner', icon: ClIcons.profile),
      row('minh', 'parentRole', icon: ClIcons.profile),
      row('carer', 'careRole', icon: ClIcons.profile),
      row('grandma', 'relativeRole', icon: ClIcons.eye),
    ]),
    const SizedBox(height: ClSpace.s3),

    group([
      row(
        'overview',
        null,
        icon: ClIcons.care,
        onTap: () => go(CareView.overview),
      ),
    ]),
    if (!readOnly)
      row(
        'notificationTitle',
        null,
        icon: ClIcons.bell,
        onTap: () => go(CareView.notifications),
      ),
    const SizedBox(height: ClSpace.s4),
  ];

  List<Widget> notifications() => [
    ClSettingRow(
      icon: ClIcons.bell,
      title: t('onlyMine'),
      value: taskNotices,
      onChanged: (v) => setState(() {
        taskNotices = v;
        preferencesSaved = false;
      }),
    ),
    const SizedBox(height: ClSpace.s3),
    ClSettingRow(
      icon: ClIcons.family,
      title: t('handoverMine'),
      value: handoverNotices,
      onChanged: (v) => setState(() {
        handoverNotices = v;
        preferencesSaved = false;
      }),
    ),
    const SizedBox(height: ClSpace.s3),
    ClSettingRow(
      icon: ClIcons.heart,
      title: t('appreciationPush'),
      value: thanksNotices,
      subtitle: thanksNotices ? null : t('appreciationOff'),
      onChanged: (v) => setState(() {
        thanksNotices = v;
        preferencesSaved = false;
      }),
    ),
    section('quiet'),
    group([row('quietRange', null, icon: ClIcons.sleep)]),
    const SizedBox(height: ClSpace.s3),
    text('quietNote', muted: true),
    section('notificationExample'),
    group([
      row(
        'quickActionTitle',
        null,
        icon: ClIcons.bell,
        onTap: () => go(CareView.quickAction),
      ),
    ]),
    if (preferencesSaved) ...[
      const SizedBox(height: ClSpace.s3),
      notice('notificationSaved'),
    ],
  ];
  List<Widget> gratitude() => [
    text('noComparison', muted: true),
    const SizedBox(height: ClSpace.s4),
    group([row('completedCare', 'completedAt', icon: ClIcons.check)]),
    const SizedBox(height: ClSpace.s6),
    Text(t('gratitudeText'), style: context.cl.text.title2),
    if (thanksSent) ...[
      const SizedBox(height: ClSpace.s4),
      notice('sentThanks'),
    ],
  ];
  List<Widget> quickAction() => [
    ClSettingRow(
      icon: ClIcons.lock,
      title: t('lockPreview'),
      subtitle: t('lockHelp'),
      value: unlocked,
      onChanged: (v) => setState(() => unlocked = v),
    ),
    const SizedBox(height: ClSpace.s6),
    group([
      row('appName', unlocked ? 'acceptedTask' : null, icon: ClIcons.bell),
      row(unlocked ? 'wash' : 'genericNotice', null),
    ]),
    if (pendingQuick) ...[
      const SizedBox(height: ClSpace.s4),
      notice('pendingSync'),
    ],
  ];
  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final children = switch (view) {
      CareView.overview => overview(),
      CareView.assignment => assignment(),
      CareView.outgoing => handover(incoming: false),
      CareView.incoming => handover(incoming: true),
      CareView.simple => simple(),
      CareView.routine => routine(),
      CareView.family => family(),
      CareView.notifications => notifications(),
      CareView.gratitude => gratitude(),
      CareView.quickAction => quickAction(),
    };
    final footer = switch (view) {
      CareView.overview =>
        scenario == PreviewState.relative ||
                scenario == PreviewState.loading ||
                scenario == PreviewState.error
            ? null
            : action('prepare', () => go(CareView.outgoing)),
      CareView.assignment => action(assigned ? 'overview' : 'save', () {
        if (assigned) {
          go(CareView.overview);
        } else {
          setState(() => assigned = true);
        }
      }),
      CareView.outgoing =>
        sent
            ? action(
                'overview',
                () => go(CareView.overview),
                style: ClButtonStyle.secondary,
              )
            : action(
                'send',
                offline ? null : () => setState(() => sent = true),
              ),
      CareView.incoming =>
        received
            ? action('receivedAction', () => go(CareView.simple))
            : action(
                'receive',
                offline ? null : () => setState(() => received = true),
              ),
      CareView.simple => action(
        completed
            ? 'undo'
            : acceptedTask
            ? 'bathDo'
            : 'acceptTask',
        actOnTask,
      ),
      CareView.routine => action(applied ? 'overview' : 'reviewApply', () {
        if (applied) {
          go(CareView.overview);
        } else {
          setState(() => applied = true);
        }
      }),
      CareView.notifications => action(
        'savePreferences',
        () => setState(() => preferencesSaved = true),
      ),
      CareView.gratitude =>
        thanksSent
            ? action(
                'overview',
                () => go(CareView.overview),
                style: ClButtonStyle.secondary,
              )
            : action('sendThanks', () => setState(() => thanksSent = true)),
      CareView.quickAction =>
        unlocked
            ? action(
                'bathDo',
                pendingQuick ? null : () => setState(() => pendingQuick = true),
              )
            : action('openTask', () => go(CareView.simple)),
      CareView.family =>
        caregiver || readOnly
            ? null
            : action(
                'invite',
                () => showClSheet<void>(
                  context: context,
                  builder: (sheet) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClSheetHeader(title: t('invite')),
                      text('inviteInfo'),
                      action(
                        'close',
                        () => Navigator.of(sheet).pop(),
                        style: ClButtonStyle.secondary,
                      ),
                    ],
                  ),
                ),
              ),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ClSpace.s4,
                vertical: ClSpace.s2,
              ),
              child: Row(
                children: [
                  ClPressable(
                    onPressed: () =>
                        view == widget.initialView &&
                            Navigator.of(context).canPop()
                        ? Navigator.of(context).pop()
                        : go(CareView.overview),
                    semanticLabel: t('back'),
                    child: const ClIcon(ClIcons.back),
                  ),
                  const Spacer(),
                  if (view != CareView.family)
                    ClButton(
                      label: t('family'),
                      onPressed: () => go(CareView.family),
                      style: ClButtonStyle.plain,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s2,
                  ClSpace.s4,
                  ClSpace.s6,
                ),
                children: [
                  Text(
                    received && view == CareView.incoming
                        ? t('received')
                        : t(viewTitle(view)),
                    style: cl.text.title2,
                  ),
                  const SizedBox(height: ClSpace.s2),
                  if (offline) ...[
                    notice('offline'),
                    const SizedBox(height: ClSpace.s3),
                    text('offlineHelp'),
                    const SizedBox(height: ClSpace.s3),
                  ],
                  ...children,
                  if (view == CareView.incoming && !received)
                    action(
                      'notNow',
                      () => setState(() => declined = true),
                      style: ClButtonStyle.plain,
                    ),
                ],
              ),
            ),
            if (footer != null)
              Padding(padding: const EdgeInsets.all(ClSpace.s4), child: footer),
          ],
        ),
      ),
    );
  }
}
