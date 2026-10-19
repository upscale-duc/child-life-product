import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/format/age.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_segmented.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../care/care_repository.dart' show onlineProvider;
import '../library/content_models.dart';
import '../library/content_repository.dart';
import '../library/library_routes.dart';
import '../library/library_screens.dart' show lbToggleSaved;
import '../library/library_widgets.dart';
import '../nutrition/nutrition_format.dart' show nuDate;
import '../nutrition/nutrition_reminders.dart';
import '../nutrition/nutrition_state.dart';
import '../nutrition/nutrition_widgets.dart';
import '../reminders/reminder_repository.dart';
import '../reminders/reminder_screens.dart' show maybeAskForNotifications;
import 'solids_calc.dart';
import 'solids_family.dart' show SdPick;
import 'solids_family_screens.dart' show SdFamilyLibrarySection;
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_personal.dart';
import 'solids_recipes.dart' show SdRecipeRow, sdPickRow;
import 'solids_repository.dart';
import 'solids_routes.dart';
import 'solids_sheet.dart';
import 'solids_state.dart';
import 'solids_widgets.dart';

/// Ăn dặm (D-085; Figma 5a `313:1681`, 5b `313:1746`, 5f `314:1987`; plan §5): the entry from
/// the Care tile. Before tracking is on it shows 5a (or "Chưa đến lúc ăn dặm" under 6 months,
/// P-164 #2); once on, 5b "Nhật ký" with the "Thư viện ăn dặm" segment. Members who do not read
/// daily care get the library only.
class SolidsScreen extends ConsumerStatefulWidget {
  const SolidsScreen({this.library = false, super.key});

  /// Open on the "Thư viện ăn dặm" segment.
  final bool library;

  @override
  ConsumerState<SolidsScreen> createState() => _SolidsScreenState();
}

class _SolidsScreenState extends ConsumerState<SolidsScreen> {
  late bool _library = widget.library;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final s = ref.watch(sdStateProvider);
    if (s == null) return ColoredBox(color: cl.colors.cloud);
    if (!s.me.sdReads) return const SolidsLibraryScreen();
    if (s.loading) {
      return SdPage(
        children: [NuTitle(l10n.careSolids), const SizedBox(height: 120)],
      );
    }
    if (!s.tracking) return _StartPage(state: s);
    return SdPage(
      fab: !_library && s.me.sdLogs
          ? SdFab(onPressed: () => unawaited(openMealSheet(context)))
          : null,
      children: [
        Row(
          children: [
            Expanded(child: NuTitle(l10n.careSolids)),
            if (s.me.sdManages)
              LbPillButton(
                key: const Key('sdSettings'),
                icon: ClIcons.sliders,
                label: l10n.sdSettings,
                onPressed: () => unawaited(showSolidsSettings(context)),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        ClSegmented<bool>(
          key: const Key('sdSegments'),
          options: const [false, true],
          selected: _library,
          labelOf: (lib) => lib ? l10n.sdLibraryTitle : l10n.sdDiary,
          onChanged: (lib) => setState(() => _library = lib),
        ),
        const SizedBox(height: ClSpace.s3),
        if (_library) const SdLibraryBody() else const _DiaryBody(),
      ],
    );
  }
}

// ---------- 5a Bật theo dõi / Chưa đến lúc ----------

class _StartPage extends ConsumerStatefulWidget {
  const _StartPage({required this.state});
  final SdState state;

  @override
  ConsumerState<_StartPage> createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<_StartPage> {
  late SdMethod _method = widget.state.settings.method;
  late bool _show = widget.state.settings.showOnToday;

  void _start() {
    final s = widget.state;
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref
        .read(solidsStoreProvider)
        .saveSettings(
          s.baby.babyId,
          s.settings.copyWith(
            enabled: true,
            method: _method,
            showOnToday: _show,
          ),
          s.me.uid,
          onError: (_) =>
              toaster.show(message: l10n.careSaveFailed, error: true),
        );
    toaster.show(message: l10n.sdStartedToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.state;
    final ready = s.age == SdAgeState.ready;
    final manages = s.me.sdManages;
    return SdPage(
      bottom: ready && manages
          ? ClButton(
              key: const Key('sdStart'),
              label: l10n.sdStart,
              expand: true,
              onPressed: _start,
            )
          : null,
      children: [
        const _Hero(),
        const SizedBox(height: ClSpace.s4),
        if (s.age == null)
          ..._noDob(context, s)
        else if (!ready)
          ..._notYet(context, s)
        else
          ..._ready(context, s),
      ],
    );
  }

  List<Widget> _ready(BuildContext context, SdState s) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final manages = s.me.sdManages;
    Widget benefit(ClIcons icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          NuIconChip(
            icon: icon,
            fill: cl.care.bottle.soft,
            ink: cl.care.bottle.ink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: cl.text.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
    return [
      NuTitle(l10n.sdStartTitle),
      const SizedBox(height: 8),
      Text(
        l10n.sdStartBody,
        style: cl.text.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: cl.colors.inkMuted,
        ),
      ),
      const SizedBox(height: ClSpace.s4),
      benefit(ClIcons.plus, l10n.sdBenefitLog),
      benefit(ClIcons.journal, l10n.sdBenefitHistory),
      benefit(ClIcons.bookmark, l10n.sdBenefitLibrary),
      if (manages) ...[
        SdLabel(l10n.sdMethodTitle),
        Row(
          children: [
            for (final (i, m) in SdMethod.values.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SdPill(
                  sdMethodLabel(l10n, m),
                  key: Key('sdMethod_${m.name}'),
                  selected: _method == m,
                  expand: true,
                  onTap: () => setState(() => _method = m),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          sdMethodHelp(l10n, _method),
          style: cl.text.caption.copyWith(
            fontSize: 12,
            color: cl.colors.inkMuted,
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        _ToggleRow(
          key: const Key('sdShowOnToday'),
          title: l10n.sdShowOnToday,
          value: _show,
          onChanged: (v) => setState(() => _show = v),
        ),
      ] else
        NuCard(
          key: const Key('sdAskParents'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NuIconChip(
                icon: ClIcons.lock,
                fill: cl.colors.surface2,
                ink: cl.colors.inkMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sdAskParents,
                      style: cl.text.bodyStrong.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.sdAskParentsBody,
                      style: cl.text.label.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: cl.colors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: ClSpace.s3),
      NuBanner(text: l10n.sdDoctorNote, warm: false),
      const SizedBox(height: ClSpace.s3),
      _LibraryLink(onTap: () => context.push(SdRoutes.library)),
    ];
  }

  /// P-164 #2: under 6 months the diary waits; the readiness guide, the library and one reminder.
  List<Widget> _notYet(BuildContext context, SdState s) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final b = s.baby;
    final dob = b.dob!;
    final six = sdSixMonthDay(dob);
    final articles =
        ref.watch(lbArticlesProvider).value?.items ?? const <LbArticle>[];
    final readiness = articles
        .where((a) => a.id == 'art_solids_readiness')
        .firstOrNull;
    final day = sdReminderDay(dob, b.today);
    final title = l10n.sdReminderTitle(b.name);
    final open = nuOpenReminder(
      ref.watch(remindersProvider(b.babyId)).value ?? const [],
      title,
      b.now,
      b.zone,
    );
    final canRemind = s.me.role != MemberRole.relative && day != null;
    return [
      NuTitle(l10n.sdNotYetTitle),
      const SizedBox(height: 8),
      Text(
        s.age == SdAgeState.soon
            ? l10n.sdNotYetSoon(
                b.name,
                ageShort(l10n, dob, b.today),
                nuDate(six),
              )
            : l10n.sdNotYetYoung(
                b.name,
                ageShort(l10n, dob, b.today),
                nuDate(six),
              ),
        key: const Key('sdNotYet'),
        style: cl.text.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: cl.colors.inkMuted,
        ),
      ),
      const SizedBox(height: ClSpace.s4),
      if (readiness != null) ...[
        LbGroup(
          children: [
            LbArticleRow(
              key: const Key('sdReadiness'),
              article: readiness,
              thumb: 56,
              meta: [
                l10n.sdReadinessKicker,
                l10n.lbMinutes(readiness.readingMinutes),
              ].join(' · '),
              onTap: () => context.push(LbRoutes.articleOf(readiness.id)),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
      ],
      _LibraryLink(onTap: () => context.push(SdRoutes.library)),
      if (canRemind || open != null) ...[
        const SizedBox(height: ClSpace.s4),
        ClButton(
          key: const Key('sdRemind'),
          label: open == null
              ? l10n.sdRemindMe
              : l10n.sdRemindSet(
                  nuDate(
                    DateTime.tryParse(open.dueDate ?? '') ??
                        open.dueAt.toLocal(),
                  ),
                ),
          icon: open == null ? ClIcons.bell : ClIcons.check,
          style: ClButtonStyle.tinted,
          expand: true,
          onPressed: open != null || day == null
              ? null
              : () => unawaited(_remind(context, s, day, title)),
        ),
      ],
      const SizedBox(height: ClSpace.s4),
      NuBanner(text: l10n.sdEarlyNote, warm: false),
    ];
  }

  Future<void> _remind(
    BuildContext context,
    SdState s,
    DateTime day,
    String title,
  ) async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    await nuCreateReminder(
      ref,
      me: s.me,
      zone: s.baby.zone,
      title: title,
      day: day,
      onError: (_) => toaster.show(message: l10n.careSaveFailed, error: true),
    );
    if (!context.mounted) return;
    // 8c: the reminder is saved first, then this device may ask for notifications.
    await maybeAskForNotifications(context, ref);
    toaster.show(message: l10n.sdRemindToast(nuDate(day)));
  }

  List<Widget> _noDob(BuildContext context, SdState s) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final parent = s.me.sdManages;
    return [
      NuTitle(l10n.sdStartTitle),
      const SizedBox(height: ClSpace.s4),
      NuCard(
        key: const Key('sdNoDob'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NuIconChip(
                  icon: ClIcons.cake,
                  fill: cl.colors.sunshineSoft,
                  ink: cl.colors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.careNutritionNoDob,
                        style: cl.text.bodyStrong.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        parent
                            ? l10n.sdNoDobBody(s.baby.name)
                            : l10n.sdNoDobViewer(s.baby.name),
                        style: cl.text.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: cl.colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (parent) ...[
              const SizedBox(height: 12),
              ClButton(
                key: const Key('sdAddDob'),
                label: l10n.lbNoDobAction,
                style: ClButtonStyle.tinted,
                expand: true,
                onPressed: () =>
                    context.push('${Routes.babyEdit}/${s.baby.babyId}'),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: ClSpace.s3),
      _LibraryLink(onTap: () => context.push(SdRoutes.library)),
    ];
  }
}

/// 5a hero: a warm block with the feeding icon (no stock photo in the app).
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: cl.colors.sunshineSoft,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: cl.colors.surface,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: ClIcon(ClIcons.feed, size: 36, color: cl.care.bottle.ink),
      ),
    );
  }
}

/// A white row with a switch (5a "Hiện “Ăn dặm hôm nay” trên Hôm nay", the settings sheet).
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: cl.text.bodyStrong.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClToggle(value: value, semanticLabel: title, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// "Thư viện ăn dặm" row (5a, "Chưa đến lúc").
class _LibraryLink extends StatelessWidget {
  const _LibraryLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('sdOpenLibrary'),
      onPressed: onTap,
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: l10n.sdLibraryTitle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            NuIconChip(
              icon: ClIcons.bookmark,
              fill: cl.colors.mintSoft,
              ink: cl.colors.mintText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sdLibraryTitle,
                    style: cl.text.bodyStrong.copyWith(fontSize: 15),
                  ),
                  Text(
                    l10n.sdLibrarySub,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 16, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

// ---------- 5b Nhật ký ----------

class _DiaryBody extends ConsumerStatefulWidget {
  const _DiaryBody();

  @override
  ConsumerState<_DiaryBody> createState() => _DiaryBodyState();
}

class _DiaryBodyState extends ConsumerState<_DiaryBody> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    if (s == null) return const SizedBox.shrink();
    final b = s.baby;
    final today = b.today;
    final day = _day ?? today;
    final tried = ref.watch(sdTriedProvider);
    final meals = sdMealsOn(s.meals, b.zone, day);
    final firstMeal = s.meals.isEmpty
        ? null
        : sdDayOf(b.zone, s.meals.map((m) => m.occurredAt).reduce(_min));
    final six = b.dob == null ? null : sdSixMonthDay(b.dob!);
    final first = [
      ?six,
      ?firstMeal,
    ].fold<DateTime?>(null, (a, d) => a == null || d.isBefore(a) ? d : a);
    final stage = sdStageLine(
      l10n,
      ref.watch(nuContentProvider)?.stage,
      locale,
    );
    final firsts = {for (final m in meals) m.id: sdFirstTryIds(m, s.meals)};
    final anyFirst = firsts.values.any((f) => f.isNotEmpty);
    final empty = day == today ? l10n.sdEmptyToday : l10n.sdEmptyDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "Gợi ý cho {bé} hôm nay" (plan §7): hidden while there is nothing to say.
        const SdSuggestionsSection(),
        SdWeekStrip(
          today: today,
          selected: day,
          first: first,
          mealDays: sdMealDays(s.meals, b.zone),
          onSelect: (d) => setState(() => _day = d),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Semantics(
            header: true,
            child: Text(
              l10n.sdDayMeals(sdDayLabel(l10n, tag, day, today), meals.length),
              key: const Key('sdDayHeader'),
              style: cl.text.headline.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (stage != null)
          Text(
            stage,
            key: const Key('sdStageLine'),
            style: cl.text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cl.colors.inkMuted,
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        if (meals.isEmpty)
          NuCard(
            key: const Key('sdEmptyDay'),
            flat: true,
            child: Column(
              children: [
                Text(
                  empty,
                  textAlign: TextAlign.center,
                  style: cl.text.body.copyWith(color: cl.colors.inkMuted),
                ),
                if (s.me.sdLogs) ...[
                  const SizedBox(height: 10),
                  ClButton(
                    label: l10n.sdLogMeal,
                    icon: ClIcons.plus,
                    style: ClButtonStyle.tinted,
                    onPressed: () => unawaited(
                      openMealSheet(context, day: day == today ? null : day),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          for (final m in meals) ...[
            SdMealCard(
              meal: m,
              foods: s.foods,
              firstTries: firsts[m.id]!,
              myUid: s.me.uid,
              onTap: () => context.push(SdRoutes.meal(m.id)),
            ),
            const SizedBox(height: ClSpace.s3),
          ],
        if (anyFirst)
          Text(
            l10n.sdFirstTryLegend,
            style: cl.text.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cl.colors.inkMuted,
            ),
          ),
        LbSection(
          l10n.sdTriedTitle(tried.length),
          link: tried.isEmpty ? null : l10n.sdSeeAll,
          onLink: () => context.push(SdRoutes.foods),
        ),
        if (tried.isEmpty)
          Text(
            l10n.sdTriedEmpty,
            style: cl.text.label.copyWith(color: cl.colors.inkMuted),
          )
        else
          Wrap(
            key: const Key('sdTriedChips'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in tried.take(9))
                SdFoodChip(
                  t.name(locale),
                  look: SdChipLook.outline,
                  onTap: () => context.push(SdRoutes.food(t.key)),
                ),
              if (tried.length > 9)
                SdFoodChip(
                  '+${tried.length - 9}',
                  look: SdChipLook.outline,
                  semanticLabel: l10n.sdSeeAll,
                  onTap: () => context.push(SdRoutes.foods),
                ),
            ],
          ),
        const SizedBox(height: ClSpace.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: ClButton(
            key: const Key('sdHistory'),
            label: l10n.sdHistoryTitle,
            icon: ClIcons.journal,
            style: ClButtonStyle.plain,
            onPressed: () => context.push(SdRoutes.history),
          ),
        ),
      ],
    );
  }
}

DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

// ---------- Settings (Cùng nuôi) ----------

/// Cách cho ăn, "Hiện trên Hôm nay", the start date and "Dừng theo dõi" (P-164 #3). Cùng nuôi
/// only (Rules); the meals stay when tracking stops.
Future<void> showSolidsSettings(BuildContext context) =>
    showClSheet<void>(context: context, builder: (_) => const _SettingsSheet());

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  SdSettings? _draft;

  SdSettings _cur(SdState s) => _draft ?? s.settings;

  void _save(SdState s, SdSettings next) {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    ref
        .read(solidsStoreProvider)
        .saveSettings(
          s.baby.babyId,
          next,
          s.me.uid,
          onError: (_) =>
              toaster.show(message: l10n.careSaveFailed, error: true),
        );
  }

  Future<void> _pickStart(SdState s) async {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final today = s.baby.today;
    final earliest = s.baby.dob == null
        ? DateTime(today.year - 3, today.month, today.day)
        : sdSixMonthDay(s.baby.dob!);
    var picked =
        _cur(s).startedOn ??
        sdStartedOn(_cur(s), s.meals, s.baby.zone) ??
        today;
    if (picked.isBefore(earliest)) picked = earliest;
    if (picked.isAfter(today)) picked = today;
    final next = await showClSheet<DateTime>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sdStartedOn),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: cl.isNightCare ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: cl.text.title2.copyWith(
                    color: cl.colors.ink,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: earliest.isAfter(today) ? today : earliest,
                maximumDate: today,
                onDateTimeChanged: (d) => picked = d,
              ),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          ClButton(
            label: l10n.actionDone,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(picked),
          ),
        ],
      ),
    );
    if (next != null && mounted) {
      setState(
        () => _draft = _cur(
          s,
        ).copyWith(startedOn: DateTime(next.year, next.month, next.day)),
      );
    }
  }

  Future<void> _stop(SdState s) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showClSheet<bool>(
      context: context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(title: l10n.sdStopTitle),
          Text(
            l10n.sdStopBody,
            style: sheet.cl.text.body.copyWith(color: sheet.cl.colors.inkMuted),
          ),
          const SizedBox(height: ClSpace.s6),
          ClButton(
            key: const Key('sdStopConfirm'),
            label: l10n.sdStop,
            style: ClButtonStyle.destructive,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          ClButton(
            label: l10n.actionCancel,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _save(s, _cur(s).copyWith(enabled: false));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final tag = Localizations.localeOf(context).toLanguageTag();
    final s = ref.watch(sdStateProvider);
    if (s == null) return const SizedBox.shrink();
    final cur = _cur(s);
    final started = cur.startedOn;
    final derived = sdStartedOn(
      cur.copyWith(clearStartedOn: true),
      s.meals,
      s.baby.zone,
    );
    final startLabel = started != null
        ? sdShortDate(tag, started)
        : derived == null
        ? l10n.sdStartedOnAuto
        : l10n.sdStartedOnAutoDate(sdShortDate(tag, derived));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.sdSettings),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SdLabel(l10n.sdMethodTitle),
                Row(
                  children: [
                    for (final (i, m) in SdMethod.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: SdPill(
                          sdMethodLabel(l10n, m),
                          selected: cur.method == m,
                          expand: true,
                          onTap: () => setState(
                            () => _draft = _cur(s).copyWith(method: m),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sdMethodHelp(l10n, cur.method),
                  style: cl.text.caption.copyWith(
                    fontSize: 12,
                    color: cl.colors.inkMuted,
                  ),
                ),
                const SizedBox(height: ClSpace.s4),
                _ToggleRow(
                  title: l10n.sdShowOnToday,
                  value: cur.showOnToday,
                  onChanged: (v) =>
                      setState(() => _draft = _cur(s).copyWith(showOnToday: v)),
                ),
                const SizedBox(height: ClSpace.s3),
                ClTimeRow(
                  icon: ClIcons.cake,
                  label: l10n.sdStartedOn,
                  value: startLabel,
                  onTap: () => unawaited(_pickStart(s)),
                ),
                if (started != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ClButton(
                      label: l10n.sdStartedOnReset,
                      style: ClButtonStyle.plain,
                      onPressed: () => setState(
                        () => _draft = _cur(s).copyWith(clearStartedOn: true),
                      ),
                    ),
                  ),
                const SizedBox(height: ClSpace.s2),
                ClButton(
                  key: const Key('sdStop'),
                  label: l10n.sdStop,
                  style: ClButtonStyle.plain,
                  onPressed: () => unawaited(_stop(s)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          key: const Key('sdSettingsSave'),
          label: l10n.actionSave,
          expand: true,
          onPressed: () {
            _save(s, cur);
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }
}

// ---------- 5f Thư viện ăn dặm ----------

/// 5f on its own (from 5a, "Chưa đến lúc", or for members without the diary).
class SolidsLibraryScreen extends StatelessWidget {
  const SolidsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) => SdPage(
    children: [
      NuTitle(AppLocalizations.of(context).sdLibraryTitle),
      const SizedBox(height: ClSpace.s4),
      const SdLibraryBody(),
    ],
  );
}

/// 5f body (P-164 #11): search over titles, keywords and ingredient names; the age band preset
/// from the baby, the content type (Hướng dẫn · Công thức), the recipe method and the guide
/// format; "Nhà mình" first (the family's own recipes and "Thêm công thức nhà mình", D-086),
/// "Dành cho {bé}" (plan §7, while tracking is on, the family's recipes among them), the featured
/// guide (the newest for the filters), "Công thức · {band}" (3, then "Xem tất cả") and the
/// guides. Works without tracking. Guides open the article reader (4d), recipes 5g.
class SdLibraryBody extends ConsumerStatefulWidget {
  const SdLibraryBody({super.key});

  @override
  ConsumerState<SdLibraryBody> createState() => _SdLibraryBodyState();
}

class _SdLibraryBodyState extends ConsumerState<SdLibraryBody> {
  SdLibraryFilter _f = const SdLibraryFilter();

  /// Until the band is chosen here, it follows the baby's age (known once the profile loads).
  bool _bandChosen = false;
  final _query = TextEditingController();

  /// Recipes shown before "Xem tất cả".
  static const _recipePreview = 3;

  @override
  void initState() {
    super.initState();
    _query.addListener(() {
      if (_query.text != _f.query) {
        setState(() => _f = _f.copyWith(query: _query.text));
      }
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _toggleType(SdLibraryType t) => setState(
    () => _f = _f.type == t
        ? _f.copyWith(clearType: true)
        : _f.copyWith(
            type: t,
            clearFormat: t == SdLibraryType.recipes,
            clearMethod: t == SdLibraryType.guides,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final feed = ref.watch(lbArticlesProvider);
    final recipeFeed = ref.watch(sdRecipesProvider);
    final online = ref.watch(onlineProvider).value ?? true;
    final state = ref.watch(sdStateProvider);
    final solids = [
      for (final a in feed.value?.items ?? const <LbArticle>[])
        if (a.library == LbLibrary.solids) a,
    ];
    final recipes = recipeFeed.value?.items ?? const <SdRecipe>[];
    final foods = {
      for (final f
          in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
        f.id: f,
    };
    if (!_bandChosen) {
      final preset = sdBandFor(state?.months);
      _f = preset == null
          ? _f.copyWith(clearBand: true)
          : _f.copyWith(band: preset);
    }
    final results = _f.apply(solids);
    final recipeResults = _f.applyRecipes(recipes, foods: foods);
    final searching = _f.query.trim().isNotEmpty;
    final featured = !searching ? results.firstOrNull : null;
    final rest = [
      for (final a in results)
        if (a.id != featured?.id) a,
    ];
    final allRecipes = _f.type == SdLibraryType.recipes || searching;
    final shownRecipes = allRecipes
        ? recipeResults
        : recipeResults.take(_recipePreview).toList();
    // "Dành cho {bé}" heads the list while browsing (not while searching or on guides only).
    final forBaby =
        !searching &&
            _f.type != SdLibraryType.guides &&
            _f.format == null &&
            state != null
        ? ref.watch(sdForBabyPicksProvider).take(3).toList()
        : const <SdPick>[];
    // D-086: the family's own recipes first, for members who read care (recipes, any band).
    final showFamily =
        state != null &&
        state.me.sdReads &&
        _f.type != SdLibraryType.guides &&
        _f.format == null;
    final saved = {
      for (final s in ref.watch(lbSavedProvider).value ?? const <LbSaved>[])
        s.id,
    };
    final loading =
        (feed.isLoading && solids.isEmpty) &&
        (recipeFeed.isLoading && recipes.isEmpty);

    Widget pills<T>(
      List<T> values,
      String Function(T) label,
      String Function(T) key,
      bool Function(T) selected,
      void Function(T) onTap,
    ) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, v) in values.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          SdPill(
            label(v),
            key: Key(key(v)),
            selected: selected(v),
            soft: true,
            onTap: () => onTap(v),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: cl.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cl.colors.controlBorder),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  key: const Key('sdLibraryQuery'),
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  style: cl.text.body.copyWith(fontSize: 15),
                  decoration: InputDecoration.collapsed(
                    hintText: l10n.sdLibrarySearch,
                    hintStyle: cl.text.body.copyWith(
                      fontSize: 15,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
              if (_query.text.isNotEmpty)
                ClPressable(
                  onPressed: _query.clear,
                  semanticLabel: l10n.lbClearSearch,
                  child: ClIcon(ClIcons.close, size: 16, color: cl.colors.ink),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: pills<SdBand>(
            SdBand.values,
            (b) => sdBandLabel(l10n, b),
            (b) => 'sdBand_${b.name}',
            (b) => _f.band == b,
            (b) => setState(() {
              _bandChosen = true;
              _f = _f.band == b
                  ? _f.copyWith(clearBand: true)
                  : _f.copyWith(band: b);
            }),
          ),
        ),
        const SizedBox(height: ClSpace.s2),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              pills<SdLibraryType>(
                SdLibraryType.values,
                (t) =>
                    t == SdLibraryType.guides ? l10n.sdGuides : l10n.sdRecipes,
                (t) => 'sdType_${t.name}',
                (t) => _f.type == t,
                _toggleType,
              ),
              if (_f.type != SdLibraryType.guides) ...[
                const SizedBox(width: 8),
                pills<SdRecipeMethod>(
                  SdRecipeMethod.values,
                  (m) => sdRecipeMethodLabel(l10n, m),
                  (m) => 'sdRecipeMethod_${m.name}',
                  (m) => _f.method == m,
                  (m) => setState(
                    () => _f = _f.method == m
                        ? _f.copyWith(clearMethod: true)
                        : _f.copyWith(method: m),
                  ),
                ),
              ],
              if (_f.type != SdLibraryType.recipes) ...[
                const SizedBox(width: 8),
                pills<LbFormat>(
                  LbFormat.values,
                  (f) => sdFormatLabel(l10n, f),
                  (f) => 'sdFormat_${f.name}',
                  (f) => _f.format == f,
                  (f) => setState(
                    () => _f = _f.format == f
                        ? _f.copyWith(clearFormat: true)
                        : _f.copyWith(format: f),
                  ),
                ),
              ],
            ],
          ),
        ),
        LbOfflineNote(l10n.lbOfflineLibrary, top: ClSpace.s3),
        if (showFamily) SdFamilyLibrarySection(query: _f.query, foods: foods),
        if (loading)
          const SizedBox(height: 120)
        else if (solids.isEmpty && recipes.isEmpty)
          LbEmpty(
            icon: online ? ClIcons.journal : ClIcons.cloudOff,
            title: online ? l10n.lbEmptyTitle : l10n.lbEmptyOfflineTitle,
            body: online ? l10n.sdLibraryEmpty : l10n.lbEmptyOfflineBody,
          )
        else ...[
          if (forBaby.isNotEmpty) ...[
            LbSection(l10n.sdForBaby(state!.baby.name)),
            LbGroup(
              key: const Key('sdForBaby'),
              children: [
                for (final p in forBaby)
                  sdPickRow(context, p, keyPrefix: 'sdForBaby_'),
              ],
            ),
          ],
          if (featured != null && _f.type != SdLibraryType.recipes) ...[
            const SizedBox(height: ClSpace.s4),
            _FeaturedGuide(article: featured),
          ],
          if (shownRecipes.isNotEmpty) ...[
            LbSection(
              _f.band == null
                  ? l10n.sdRecipes
                  : l10n.sdRecipesFor(sdBandLabel(l10n, _f.band!)),
              link: !allRecipes && recipeResults.length > _recipePreview
                  ? l10n.sdSeeAll
                  : null,
              onLink: () => _toggleType(SdLibraryType.recipes),
            ),
            LbGroup(
              key: const Key('sdRecipes'),
              children: [
                for (final r in shownRecipes)
                  SdRecipeRow(
                    key: Key('sdRecipe_${r.id}'),
                    recipe: r,
                    onTap: () => context.push(SdRoutes.recipe(r.id)),
                  ),
              ],
            ),
          ] else if (_f.type == SdLibraryType.recipes)
            LbEmpty(
              icon: ClIcons.search,
              title: l10n.sdRecipesNone,
              body: l10n.sdLibraryNoResults,
            ),
          if (rest.isNotEmpty && _f.type != SdLibraryType.recipes) ...[
            LbSection(l10n.sdGuides),
            LbGroup(
              children: [
                for (final a in rest)
                  LbArticleRow(
                    key: Key('sdGuide_${a.id}'),
                    article: a,
                    meta: _guideMeta(l10n, a),
                    saved: saved.contains(a.id),
                    onBookmark: () => unawaited(lbToggleSaved(context, ref, a)),
                    onTap: () => context.push(LbRoutes.articleOf(a.id)),
                  ),
              ],
            ),
          ] else if (results.isEmpty &&
              recipeResults.isEmpty &&
              _f.type != SdLibraryType.recipes)
            LbEmpty(
              icon: ClIcons.search,
              title: l10n.lbNoResults,
              body: l10n.sdLibraryNoResults,
            ),
        ],
      ],
    );
  }
}

/// "Từng bước · 5–8 tháng · 4 phút".
String _guideMeta(AppLocalizations l10n, LbArticle a) => [
  sdFormatLabel(l10n, a.format),
  lbWeeksLabel(l10n, a.weeks),
  l10n.lbMinutesShort(a.readingMinutes),
].join(' · ');

/// 5f featured card: picture 150, "Hướng dẫn · {format}", the title, "6 phút đọc · cập nhật 09/2026".
class _FeaturedGuide extends StatelessWidget {
  const _FeaturedGuide({required this.article});
  final LbArticle article;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final title = article.title.of(context);
    final published = article.publishedAt;
    final meta = [
      l10n.lbMinutes(article.readingMinutes),
      if (published != null)
        l10n.sdUpdated(DateFormat('MM/yyyy').format(published.toLocal())),
    ].join(' · ');
    final kicker = l10n.sdGuideKicker(sdFormatLabel(l10n, article.format));
    return ClPressable(
      key: Key('sdFeatured_${article.id}'),
      onPressed: () => context.push(LbRoutes.articleOf(article.id)),
      pressedOpacity: ClPressable.surfaceOpacity,
      semanticLabel: '$kicker. $title. $meta',
      child: Container(
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: cl.shadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LbPicture(
              image: article.cover?.id,
              alt: article.cover?.alt?.of(context),
              width: double.infinity,
              height: 150,
              radius: 0,
              topic: article.topic,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kicker,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cl.colors.mintText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    style: cl.text.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
