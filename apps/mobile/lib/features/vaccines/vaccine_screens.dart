import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_navigation.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../family/countries.dart';
import '../family/family_repository.dart';
import '../home/home_shell.dart';
import '../premium/premium_repository.dart';
import '../reminders/reminder_screens.dart' show reminderWho;
import 'vaccine_format.dart';
import 'vaccine_models.dart';
import 'vaccine_photos.dart';
import 'vaccine_repository.dart';
import 'vaccine_sheets.dart';

// ---------- Page chrome ----------

/// A pushed page: back (or close) · baby chip, then content (VX shared chrome).
class _VxPage extends ConsumerWidget {
  const _VxPage({required this.children, this.close = false, this.trailing});

  final List<Widget> children;
  final bool close;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClSpace.s4,
                ClSpace.s2,
                ClSpace.s4,
                0,
              ),
              child: ClTopBar(
                onBack: close ? null : () => context.pop(),
                brand: close
                    ? ClPressable(
                        onPressed: () => context.pop(),
                        semanticLabel: l10n.a11yClose,
                        child: Container(
                          width: ClSpace.tapMin,
                          height: ClSpace.tapMin,
                          decoration: BoxDecoration(
                            color: cl.colors.surface2,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: ClIcon(ClIcons.close, color: cl.colors.ink),
                        ),
                      )
                    : null,
                trailing:
                    trailing ??
                    (baby == null
                        ? null
                        : ClBabySwitcher(
                            label: baby.nickname,
                            avatar: SavedBabyAvatar(baby: baby, size: 32),
                          )),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s3,
                  ClSpace.s4,
                  media.padding.bottom + ClSpace.s8,
                ),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.cl.text.largeTitle),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children, this.radius = 16});
  final List<Widget> children;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: cl.shadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) Divider(height: 1, color: cl.colors.separator),
            c,
          ],
        ],
      ),
    );
  }
}

/// The book, or the reason it cannot show yet.
Widget _withBook(
  BuildContext context,
  WidgetRef ref,
  Widget Function(Membership me, VaccineBook book, DateTime dob) build,
) {
  final l10n = AppLocalizations.of(context);
  final cl = context.cl;
  final me = ref.watch(selectedMembershipProvider);
  if (me == null) return ColoredBox(color: cl.colors.cloud);
  return switch (ref.watch(vaccineBookProvider(me))) {
    VaccineBookLoading() => _VxPage(children: const []),
    VaccineBookNoDob() => _VxPage(
      children: [
        _Title(l10n.vxTitle),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.vxNoDob(
            ref.watch(babyProvider(me.babyId)).value?.nickname ?? '',
          ),
          style: cl.text.headline,
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.vxNoDobBody,
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    ),
    VaccineBookReady(:final book, :final dob) => build(me, book, dob),
  };
}

/// Opening a dose from a dot or a box: given / declined → its page, overdue → VX 9a,
/// otherwise the quick tick (VX 5). Relatives only look.
void openDose(
  BuildContext context,
  Membership me,
  VaccineBook book,
  DoseItem item,
) {
  if (item.record != null && item.record!.status != DoseRecordStatus.planned) {
    context.push('${Routes.vaccineDose}/${item.key}');
    return;
  }
  if (!vxCanLog(me)) {
    showClToast(context, message: AppLocalizations.of(context).vxViewOnly);
    return;
  }
  if (item.status == DoseStatus.overdue) {
    unawaited(showOverdueSheet(context, me: me, book: book, item: item));
  } else {
    unawaited(showQuickDoseSheet(context, me: me, book: book, item: item));
  }
}

// ---------- VX 1 / VX 1b / VX 9 ----------

/// Tiêm chủng: the next shot, the view switch and the counter, then the matrix by vaccine
/// (VX 1) or the timeline by month of age (VX 1b); overdue doses turn red (VX 9).
class VaccineBookScreen extends ConsumerStatefulWidget {
  const VaccineBookScreen({super.key});

  @override
  ConsumerState<VaccineBookScreen> createState() => _VaccineBookScreenState();
}

class _VaccineBookScreenState extends ConsumerState<VaccineBookScreen> {
  var _offeredSetup = false;

  /// Cùng nuôi keep the plan's date in step with the profile (for caregivers, P-133), and are
  /// offered the first-time list once (VX 0).
  void _maintain(Membership me, VaccineBook book, DateTime dob) {
    if (me.role != MemberRole.coParent) return;
    final plan = book.plan;
    if (plan.scheduleFrom != dob) {
      ref
          .read(vaccineRepositoryProvider)
          .savePlan(me.babyId, me, plan.copyWith(scheduleFrom: dob));
    }
    if (!plan.setupDone && !_offeredSetup && book.dueSoFar.isNotEmpty) {
      _offeredSetup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(Routes.vaccineSetup);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    final view = ref.watch(vaccineViewProvider);
    return _withBook(context, ref, (me, book, dob) {
      _maintain(me, book, dob);
      final next = book.nextGroup;
      final overdue = book.overdue;
      // D-084: the family's country has its own schedule here; D-078: it does not.
      final local = countryScheduleOf(book.country);
      final abroad = switch (ref.watch(selectedFamilyCountryProvider)) {
        final code? when code != 'VN' && local == null => code,
        _ => null,
      };
      return _VxPage(
        children: [
          _Title(l10n.vxTitle),
          const SizedBox(height: ClSpace.s3),
          if (local != null) ...[
            Text(
              l10n.vxCountryNotice(
                local.programmeName.of(locale),
                vxDate(DateTime.parse(local.checkedOn)),
              ),
              key: const Key('vxCountry'),
              style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s3),
          ],
          // D-078: the schedule is Việt Nam's; a family elsewhere follows its own clinic.
          if (abroad != null) ...[
            Container(
              key: const Key('vxAbroad'),
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cl.colors.separator),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClIcon(ClIcons.globe, size: 18, color: cl.colors.inkMuted),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.vxAbroadNotice(countryName(l10n, abroad)),
                      style: cl.text.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
          ],
          if (view == VaccineView.byVaccine && next != null) ...[
            _NextCard(group: next, book: book),
            const SizedBox(height: ClSpace.s3),
          ],
          if (overdue.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cl.colors.error),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClIcon(ClIcons.alert, size: 18, color: cl.colors.error),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.vxOverdueCard(overdue.length),
                      style: cl.text.label,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ClSpace.s3),
          ],
          Row(
            children: [
              ClPressable(
                key: const Key('vxView'),
                onPressed: () => showVaccineViewSheet(context, ref),
                semanticLabel: l10n.vxViewTitle,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    borderRadius: BorderRadius.circular(ClRadius.pill),
                    border: Border.all(color: cl.colors.separator),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        view == VaccineView.byVaccine
                            ? l10n.vxViewByVaccine
                            : l10n.vxViewByAge,
                        style: cl.text.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      ClIcon(
                        ClIcons.chevronDown,
                        size: 14,
                        color: cl.colors.ink,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                l10n.vxCount(book.given, book.total),
                style: cl.text.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cl.colors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          if (view == VaccineView.byVaccine) ...[
            _Matrix(me: me, book: book, locale: locale),
            const SizedBox(height: ClSpace.s3),
            const _Legend(),
          ] else
            _Timeline(me: me, book: book, locale: locale),
          const SizedBox(height: ClSpace.s3),
          VxBanner(
            view == VaccineView.byVaccine
                ? l10n.vxBannerMatrix
                : l10n.vxBannerTimeline,
          ),
          if (book.plan.bookPhotos.isNotEmpty ||
              me.role == MemberRole.coParent) ...[
            const SizedBox(height: ClSpace.s6),
            Text(l10n.vxBookPhotos, style: cl.text.headline),
            const SizedBox(height: ClSpace.s3),
            _BookPhotos(
              babyId: me.babyId,
              paths: book.plan.bookPhotos,
              // The plan is Cùng nuôi's (Rules); everyone who reads care sees the photos.
              onChanged: me.role == MemberRole.coParent
                  ? (paths) {
                      final toaster = ClToaster.of(context);
                      ref
                          .read(vaccineRepositoryProvider)
                          .savePlan(
                            me.babyId,
                            me,
                            book.plan.copyWith(bookPhotos: paths),
                            onError: (_) =>
                                toaster.show(message: l10n.vxSaveFailed),
                          );
                    }
                  : null,
            ),
          ],
        ],
      );
    });
  }
}

/// Photos of the whole book (VX 0 "Chụp sổ tiêm chủng để lưu lại"; kept on the plan, up to
/// [maxBookPhotos]). Without [onChanged] they are only viewed; [removeInline] puts the "×" on each
/// thumbnail (VX 0), otherwise the viewer offers "Xoá ảnh".
class _BookPhotos extends ConsumerStatefulWidget {
  const _BookPhotos({
    required this.babyId,
    required this.paths,
    this.onChanged,
    this.removeInline = false,
  });

  final String babyId;
  final List<String> paths;
  final ValueChanged<List<String>>? onChanged;
  final bool removeInline;

  @override
  ConsumerState<_BookPhotos> createState() => _BookPhotosState();
}

class _BookPhotosState extends ConsumerState<_BookPhotos> {
  bool _uploading = false;

  Future<void> _add() async {
    final path = await addVxPhoto(
      context,
      ref,
      widget.babyId,
      onBusy: (busy) {
        if (mounted) setState(() => _uploading = busy);
      },
    );
    if (path != null) widget.onChanged?.call([...widget.paths, path]);
  }

  Future<void> _remove(String path) async {
    widget.onChanged?.call([...widget.paths]..remove(path));
    await ref.read(vaccinePhotoStoreProvider).remove(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paths = widget.paths;
    final editable = widget.onChanged != null;
    final canAdd = editable && paths.length < maxBookPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paths.isNotEmpty)
          Wrap(
            spacing: ClSpace.s2,
            runSpacing: ClSpace.s2,
            children: [
              for (final (i, p) in paths.indexed)
                VxPhotoThumb(
                  path: p,
                  width: 72,
                  height: 88,
                  onPressed: () => showVxPhotoViewer(
                    context,
                    paths,
                    index: i,
                    onDelete: editable && !widget.removeInline
                        ? (p) async {
                            final toaster = ClToaster.of(context);
                            await _remove(p);
                            toaster.show(message: l10n.vxPhotoDeleted);
                          }
                        : null,
                  ),
                  onRemove: editable && widget.removeInline
                      ? () => unawaited(_remove(p))
                      : null,
                ),
            ],
          ),
        if (paths.isNotEmpty && canAdd) const SizedBox(height: ClSpace.s3),
        if (canAdd)
          VxPhotoButton(
            key: const Key('vxBookPhotoAdd'),
            label: paths.isEmpty ? l10n.vxPhotoBook : l10n.vxPhotoAdd,
            radius: 16,
            height: 56,
            busy: _uploading,
            onPressed: () => unawaited(_add()),
          ),
      ],
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.group, required this.book});
  final DoseGroup group;
  final VaccineBook book;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    final late = group.date.isBefore(book.today);
    final line = late
        ? l10n.vxOverdueLine(
            book.today.difference(group.date).inDays,
            vxDay(group.date),
          )
        : l10n.vxNextLine(
            vxDay(group.date),
            vxLeft(l10n, book.today, group.date),
          );
    return ClPressable(
      key: const Key('vxNext'),
      onPressed: () =>
          context.push('${Routes.vaccineAge}/${group.items.first.months}'),
      semanticLabel: line,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(
          color: late ? cl.colors.errorSoft : cl.colors.sunshineSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(
                late ? ClIcons.alert : ClIcons.clock,
                size: 18,
                color: late ? cl.colors.error : cl.colors.ink,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line,
                    style: cl.text.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: late ? cl.colors.error : cl.colors.inkMuted,
                    ),
                  ),
                  Text(
                    vxGroupLine(l10n, locale, group.items, book.plan),
                    style: cl.text.bodyStrong.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// A dose circle in the design's status colours, with its label under it.
class _Dot extends StatelessWidget {
  const _Dot({required this.item, required this.onTap});
  final DoseItem item;
  final VoidCallback onTap;
  static const size = 34.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final (fill, border, fg) = switch (item.status) {
      DoseStatus.given => (cl.colors.mintDeep, null, cl.colors.onMintDeep),
      DoseStatus.upcoming => (
        cl.colors.sunshineSoft,
        cl.colors.sunshine,
        cl.colors.ink,
      ),
      DoseStatus.overdue => (
        cl.colors.errorSoft,
        cl.colors.error,
        cl.colors.error,
      ),
      DoseStatus.later => (cl.colors.surface2, null, cl.colors.inkMuted),
      DoseStatus.declined => (cl.colors.surface2, null, cl.colors.inkMuted),
    };
    final label = switch (item.status) {
      DoseStatus.given =>
        item.record?.givenOn == null ? '—' : vxDay(item.record!.givenOn!),
      DoseStatus.upcoming || DoseStatus.overdue => vxDay(item.planned),
      DoseStatus.later =>
        item.months == 0
            ? vxDay(item.planned)
            : l10n.vxMonthsShort(item.months),
      DoseStatus.declined => '—',
    };
    final status = switch (item.status) {
      DoseStatus.given => l10n.vxLegendGiven,
      DoseStatus.upcoming => l10n.vxLegendUpcoming,
      DoseStatus.overdue => l10n.vxLegendOverdue,
      DoseStatus.later => l10n.vxLegendLater,
      DoseStatus.declined => l10n.vxLegendDeclined,
    };
    return ClPressable(
      onPressed: onTap,
      semanticLabel: '${l10n.vxDoseN(item.dose)}, $status, $label',
      child: SizedBox(
        width: size + 4,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: border == null
                    ? null
                    : Border.all(color: border, width: 2),
              ),
              alignment: Alignment.center,
              child: switch (item.status) {
                DoseStatus.given => ClIcon(ClIcons.check, size: 16, color: fg),
                DoseStatus.declined => ClIcon(
                  ClIcons.close,
                  size: 14,
                  color: fg,
                ),
                _ => Text(
                  '${item.dose}',
                  style: cl.text.label.copyWith(
                    fontWeight: item.status == DoseStatus.later
                        ? FontWeight.w600
                        : FontWeight.w700,
                    color: fg,
                  ),
                ),
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: cl.text.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: switch (item.status) {
                  DoseStatus.given => cl.colors.mintText,
                  DoseStatus.upcoming => cl.colors.ink,
                  DoseStatus.overdue => cl.colors.error,
                  _ => cl.colors.inkMuted,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Matrix extends StatelessWidget {
  const _Matrix({required this.me, required this.book, required this.locale});
  final Membership me;
  final VaccineBook book;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return _Group(
      radius: 18,
      children: [
        for (final def in book.vaccines)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s3,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: ClPressable(
                    onPressed: () =>
                        context.push('${Routes.vaccineInfo}/${def.id}'),
                    semanticLabel: vxName(locale, def, book.plan),
                    child: Column(
                      // Full width: ClPressable centres a narrower child.
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          vxName(locale, def, book.plan),
                          style: cl.text.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          vxHint(l10n, def),
                          style: cl.text.caption.copyWith(
                            fontSize: 11,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 6,
                    children: [
                      for (final item in book.rowOf(def.id))
                        _Dot(
                          item: item,
                          onTap: () => openDose(context, me, book, item),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget item(
      Color fill,
      Color? border,
      String label, {
      bool check = false,
    }) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border == null ? null : Border.all(color: border, width: 2),
          ),
          alignment: Alignment.center,
          child: check
              ? ClIcon(ClIcons.check, size: 10, color: cl.colors.onMintDeep)
              : null,
        ),
        const SizedBox(width: 6),
        Text(label, style: cl.text.caption.copyWith(color: cl.colors.inkMuted)),
      ],
    );
    return Wrap(
      spacing: ClSpace.s3,
      runSpacing: ClSpace.s2,
      children: [
        item(cl.colors.mintDeep, null, l10n.vxLegendGiven, check: true),
        item(cl.colors.sunshineSoft, cl.colors.sunshine, l10n.vxLegendUpcoming),
        item(cl.colors.errorSoft, cl.colors.error, l10n.vxLegendOverdue),
        item(cl.colors.surface2, null, l10n.vxLegendLater),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.me, required this.book, required this.locale});
  final Membership me;
  final VaccineBook book;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final current = book.nextGroup?.items.first.months;
    return _Group(
      radius: 18,
      children: [
        for (final g in book.milestones)
          Container(
            color: g.months == current ? cl.colors.sunshineSoft : null,
            padding: const EdgeInsets.all(ClSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: ClPressable(
                    onPressed: () =>
                        context.push('${Routes.vaccineAge}/${g.months}'),
                    semanticLabel: vxAge(l10n, g.months),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          vxAge(l10n, g.months),
                          style: cl.text.label.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          vxDate(g.date),
                          style: cl.text.caption.copyWith(
                            fontSize: 11,
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (final item in g.items)
                        _TimelineItem(
                          item: item,
                          plan: book.plan,
                          locale: locale,
                          onTap: () => openDose(context, me, book, item),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.item,
    required this.plan,
    required this.locale,
    required this.onTap,
  });

  final DoseItem item;
  final VaccinePlan plan;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final given = item.status == DoseStatus.given;
    final declined = item.status == DoseStatus.declined;
    final name = item.def.doses == 1
        ? vxName(locale, item.def, plan, short: true)
        : '${vxName(locale, item.def, plan, short: true)} · ${item.dose}';
    final (fill, border) = switch (item.status) {
      DoseStatus.given => (cl.colors.mintDeep, null),
      DoseStatus.upcoming => (cl.colors.surface, cl.colors.sunshine),
      DoseStatus.overdue => (cl.colors.errorSoft, cl.colors.error),
      _ => (cl.colors.surface, cl.colors.controlBorder),
    };
    return ClPressable(
      onPressed: onTap,
      semanticLabel: name,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(7),
                border: border == null
                    ? null
                    : Border.all(
                        color: border,
                        width: item.status == DoseStatus.later ? 1.5 : 2,
                      ),
              ),
              alignment: Alignment.center,
              child: given
                  ? ClIcon(ClIcons.check, size: 12, color: cl.colors.onMintDeep)
                  : declined
                  ? ClIcon(ClIcons.close, size: 12, color: cl.colors.inkMuted)
                  : null,
            ),
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: Text(
                name,
                style: cl.text.label.copyWith(
                  fontWeight: given || declined
                      ? FontWeight.w500
                      : FontWeight.w600,
                  color: given || declined ? cl.colors.inkMuted : cl.colors.ink,
                ),
              ),
            ),
            if (given || declined)
              Text(
                given ? l10n.vxLegendGiven : l10n.vxLegendDeclined,
                style: cl.text.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: given ? cl.colors.mintText : cl.colors.inkMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------- VX 0 ----------

/// "Teddy đã tiêm những mũi nào?": the doses due so far, ticked; "Lưu N mũi đã tiêm" records them
/// without a date, "Bỏ qua, làm sau" just closes the setup (Cùng nuôi only).
class VaccineSetupScreen extends ConsumerStatefulWidget {
  const VaccineSetupScreen({super.key});

  @override
  ConsumerState<VaccineSetupScreen> createState() => _VaccineSetupScreenState();
}

class _VaccineSetupScreenState extends ConsumerState<VaccineSetupScreen> {
  Set<String>? _ticked;
  List<String>? _photos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    return _withBook(context, ref, (me, book, dob) {
      final due = book.dueSoFar;
      final ticked = _ticked ??= {for (final i in due) i.key};
      final photos = _photos ??= [...book.plan.bookPhotos];
      final nickname = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
      void finish({required bool save}) {
        final toaster = ClToaster.of(context);
        ref
            .read(vaccineRepositoryProvider)
            .saveSetup(
              babyId: me.babyId,
              me: me,
              items: save
                  ? [
                      for (final i in due)
                        if (ticked.contains(i.key)) i,
                    ]
                  : const [],
              // The book photos are kept either way: they were taken on purpose.
              plan: book.plan.copyWith(scheduleFrom: dob, bookPhotos: photos),
              onError: (_) => toaster.show(message: l10n.vxSaveFailed),
            );
        if (context.canPop()) context.pop();
      }

      return _VxPage(
        close: true,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: cl.colors.peachSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(ClIcons.heart, size: 32, color: cl.colors.ink),
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          Text(
            l10n.vxSetupTitle(nickname),
            style: cl.text.title.copyWith(fontSize: 26),
          ),
          const SizedBox(height: ClSpace.s2),
          Text(
            l10n.vxSetupBody,
            style: cl.text.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          _Group(
            radius: 18,
            children: [
              for (final item in due)
                ClPressable(
                  onPressed: () => setState(
                    () => ticked.contains(item.key)
                        ? ticked.remove(item.key)
                        : ticked.add(item.key),
                  ),
                  selected: ticked.contains(item.key),
                  semanticLabel: vxDoseTitle(l10n, locale, item, book.plan),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: ticked.contains(item.key)
                                ? cl.colors.mintDeep
                                : null,
                            borderRadius: BorderRadius.circular(7),
                            border: ticked.contains(item.key)
                                ? null
                                : Border.all(
                                    color: cl.colors.controlBorder,
                                    width: 1.5,
                                  ),
                          ),
                          alignment: Alignment.center,
                          child: ticked.contains(item.key)
                              ? ClIcon(
                                  ClIcons.check,
                                  size: 14,
                                  color: cl.colors.onMintDeep,
                                )
                              : null,
                        ),
                        const SizedBox(width: ClSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.def.doses == 1
                                    ? vxName(locale, item.def, book.plan)
                                    : vxDoseTitle(
                                        l10n,
                                        locale,
                                        item,
                                        book.plan,
                                      ),
                                style: cl.text.bodyStrong.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                item.months == 0
                                    ? (item.def.id == 'hepb'
                                          ? l10n.vxSetupFirstDay
                                          : l10n.vxSetupAtHospital)
                                    : l10n.vxSetupDue(
                                        vxAge(l10n, item.months),
                                        vxDay(item.planned),
                                      ),
                                style: cl.text.caption.copyWith(
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          _BookPhotos(
            babyId: me.babyId,
            paths: photos,
            removeInline: true,
            onChanged: (paths) => setState(() => _photos = paths),
          ),
          const SizedBox(height: ClSpace.s8),
          ClButton(
            label: ticked.isEmpty
                ? l10n.vxSetupContinue
                : l10n.vxSetupSave(ticked.length),
            expand: true,
            onPressed: () => finish(save: true),
          ),
          ClButton(
            label: l10n.vxSetupSkip,
            style: ClButtonStyle.plain,
            expand: true,
            onPressed: () => finish(save: false),
          ),
        ],
      );
    });
  }
}

// ---------- VX 2 ----------

/// "2 tháng tuổi": the planned date, the 6in1 / 5in1 choice while it is open, the shots with "Ghi",
/// reminders and the appointment date.
class VaccineMilestoneScreen extends ConsumerWidget {
  const VaccineMilestoneScreen({required this.months, super.key});
  final int months;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return _withBook(context, ref, (me, book, dob) {
      final group = book.milestone(months);
      if (group == null) return const _VxPage(children: []);
      final members =
          ref.watch(familyMembersProvider(me.babyId)).value ?? const [];
      final parent = me.role == MemberRole.coParent;
      final open = [
        for (final i in group.items)
          if (!i.done) i,
      ];
      final date = open.isEmpty
          ? group.date
          : open.map((i) => i.planned).reduce((a, b) => a.isBefore(b) ? a : b);
      final late = date.isBefore(book.today) && open.isNotEmpty;
      final hasDtp = group.items.any((i) => i.def.dtpSeries);
      final choosing = hasDtp && book.dtpChoiceOpen && parent;
      final recipients = vxRecipients(book.plan, members);
      final names = [
        for (final m in members)
          if (recipients.contains(m.uid))
            m.uid == me.uid ? l10n.ruleYou : m.displayName,
      ];
      final rescheduled = open
          .where((i) => i.record?.status == DoseRecordStatus.planned)
          .firstOrNull;
      void choose(DtpChoice c) => ref
          .read(vaccineRepositoryProvider)
          .savePlan(me.babyId, me, book.plan.copyWith(dtp: c));

      Widget option(DtpChoice c, String title, String body, String pill) {
        final on = book.plan.dtp == c;
        return ClPressable(
          onPressed: () => choose(c),
          selected: on,
          semanticLabel: '$title. $body',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: on ? cl.colors.mintSoft : cl.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: on ? cl.colors.mintDeep : cl.colors.separator,
                width: on ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: on ? cl.colors.mintDeep : cl.colors.controlBorder,
                      width: on ? 7 : 1.5,
                    ),
                  ),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: cl.text.bodyStrong.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: cl.text.caption.copyWith(
                          color: cl.colors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cl.colors.surface,
                          borderRadius: BorderRadius.circular(ClRadius.pill),
                        ),
                        child: Text(
                          pill,
                          style: cl.text.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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

      // The series' dose joins the list once 6in1 or 5in1 is picked (or no choice is shown).
      final hideDtp = choosing && book.plan.dtp == null;
      final shots = [
        for (final i in group.items)
          if (!hideDtp || !i.def.dtpSeries) i,
      ];
      return _VxPage(
        children: [
          Text(
            late
                ? l10n.vxPlannedOverdue(
                    vxDate(date),
                    book.today.difference(date).inDays,
                  )
                : l10n.vxPlannedLeft(
                    vxDate(date),
                    vxLeft(l10n, book.today, date),
                  ),
            style: cl.text.caption.copyWith(
              fontSize: 13,
              color: late ? cl.colors.error : cl.colors.inkMuted,
            ),
          ),
          _Title(months == 0 ? l10n.vxBirth : l10n.vxMonthsOld(months)),
          if (choosing) ...[
            const SizedBox(height: ClSpace.s3),
            _Caption(l10n.vxChooseOne),
            option(
              DtpChoice.sixInOne,
              l10n.vx6in1Title,
              l10n.vx6in1Body,
              l10n.vxPaid,
            ),
            const SizedBox(height: ClSpace.s2),
            option(
              DtpChoice.fiveInOne,
              l10n.vx5in1Title,
              l10n.vx5in1Body,
              l10n.vxFree,
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          _Caption(hideDtp ? l10n.vxOtherShots : l10n.vxShots),
          _Group(
            children: [
              for (final i in shots)
                _ShotRow(
                  item: i,
                  book: book,
                  me: me,
                  onTap: () => openDose(context, me, book, i),
                ),
            ],
          ),
          if (parent) ...[
            const SizedBox(height: ClSpace.s3),
            _Group(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClPressable(
                          onPressed: () => showVaccineRecipientsSheet(
                            context,
                            me: me,
                            plan: book.plan,
                            members: members,
                          ),
                          semanticLabel: l10n.vxRecipientsTitle,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.vxRemind, style: cl.text.body),
                              Text(
                                names.isEmpty
                                    ? l10n.vxRemindNobody
                                    : names.join(', '),
                                style: cl.text.caption.copyWith(
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ClToggle(
                        value: book.plan.remind,
                        semanticLabel: l10n.vxRemind,
                        onChanged: (on) => ref
                            .read(vaccineRepositoryProvider)
                            .savePlan(
                              me.babyId,
                              me,
                              book.plan.copyWith(
                                remind: on,
                                recipients: recipients,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
                if (open.isNotEmpty)
                  ClPressable(
                    onPressed: () async {
                      final d = await pickVxDate(
                        context,
                        initial: date.isBefore(book.today) ? book.today : date,
                        first: book.today,
                        last: DateTime(book.today.year + 3),
                      );
                      if (d == null) return;
                      for (final i in open) {
                        ref
                            .read(vaccineRepositoryProvider)
                            .save(
                              babyId: me.babyId,
                              me: me,
                              item: i,
                              status: DoseRecordStatus.planned,
                              plannedOn: d,
                            );
                      }
                    },
                    semanticLabel: l10n.vxAppointment,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cl.colors.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: ClIcon(
                              ClIcons.clock,
                              size: 18,
                              color: cl.colors.ink,
                            ),
                          ),
                          const SizedBox(width: ClSpace.s3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.vxAppointment, style: cl.text.body),
                                Text(
                                  rescheduled == null
                                      ? l10n.vxAppointmentNone
                                      : l10n.vxAppointmentOn(
                                          vxDate(rescheduled.planned),
                                        ),
                                  style: cl.text.caption.copyWith(
                                    color: cl.colors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClIcon(
                            ClIcons.chevronRight,
                            size: 18,
                            color: cl.colors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          VxBanner(hasDtp ? l10n.vxAskDoctor : l10n.vxBannerMatrix),
        ],
      );
    });
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Text(
        text,
        style: cl.text.label.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cl.colors.inkMuted,
        ),
      ),
    );
  }
}

/// A shot in VX 2 / VX 7: icon chip · name · "Uống · Dịch vụ" · "Ghi" or its state.
class _ShotRow extends StatelessWidget {
  const _ShotRow({
    required this.item,
    required this.book,
    required this.me,
    required this.onTap,
    this.title,
  });

  final DoseItem item;
  final VaccineBook book;
  final Membership me;
  final VoidCallback onTap;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    final oral = item.def.route == VaccineRoute.oral;
    final sub = switch (item.status) {
      DoseStatus.given =>
        item.record?.givenOn == null
            ? l10n.vxLegendGiven
            : l10n.vxGivenOn(vxDay(item.record!.givenOn!)),
      DoseStatus.declined => l10n.vxLegendDeclined,
      _ when title != null => l10n.vxPlannedOn(vxDate(item.planned)),
      _ =>
        '${vxRouteLabel(l10n, item.def)} · '
            '${vxProgrammeLabel(l10n, item.def, national: book.country != null)}',
    };
    return ClPressable(
      onPressed: onTap,
      semanticLabel:
          '${title ?? vxDoseTitle(l10n, locale, item, book.plan)}. $sub',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: switch (item.status) {
                  DoseStatus.given => cl.colors.mintSoft,
                  DoseStatus.overdue => cl.colors.errorSoft,
                  DoseStatus.upcoming => cl.colors.sunshineSoft,
                  _ => oral ? cl.care.bottle.soft : cl.colors.peachSoft,
                },
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: ClIcon(
                item.status == DoseStatus.given
                    ? ClIcons.check
                    : (oral ? ClIcons.drop : ClIcons.heart),
                size: 18,
                color: item.status == DoseStatus.given
                    ? cl.colors.mintText
                    : cl.colors.ink,
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? vxDoseTitle(l10n, locale, item, book.plan),
                    style: cl.text.bodyStrong.copyWith(fontSize: 15),
                  ),
                  Text(
                    sub,
                    style: cl.text.caption.copyWith(
                      color: item.status == DoseStatus.overdue
                          ? cl.colors.error
                          : cl.colors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.done && vxCanLog(me))
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClSpace.s3,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cl.colors.mintDeep,
                  borderRadius: BorderRadius.circular(ClRadius.pill),
                ),
                child: Text(
                  l10n.vxLog,
                  style: cl.text.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cl.colors.onMintDeep,
                  ),
                ),
              )
            else
              ClIcon(ClIcons.chevronRight, size: 18, color: cl.colors.inkMuted),
          ],
        ),
      ),
    );
  }
}

// ---------- VX 6 ----------

/// A given (or declined) dose: when, where, who recorded it, the reaction, the next dose; edit
/// and delete for Cùng nuôi and whoever recorded it.
class VaccineDoseScreen extends ConsumerWidget {
  const VaccineDoseScreen({required this.doseKey, super.key});
  final String doseKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    return _withBook(context, ref, (me, book, dob) {
      final item = book.item(doseKey);
      final record = item?.record;
      if (item == null || record == null) return const _VxPage(children: []);
      final declined = record.status == DoseRecordStatus.declined;
      final canEdit = vxCanEdit(me, item);
      final next = book.item(doseKeyOf(item.def.id, item.dose + 1));
      final title = vxDoseTitle(l10n, locale, item, book.plan);

      Widget kv(String k, String v) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                k,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      Widget chip(String text, Color bg, Color fg, {ClIcons? icon}) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(ClRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  ClIcon(icon, size: 14, color: fg),
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  style: cl.text.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          );

      Future<void> delete() async {
        final ok = await showClSheet<bool>(
          context: context,
          builder: (sheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClSheetHeader(title: l10n.vxDeleteTitle(title)),
              Text(
                l10n.vxDeleteBody,
                style: sheet.cl.text.body.copyWith(
                  color: sheet.cl.colors.inkMuted,
                ),
              ),
              const SizedBox(height: ClSpace.s6),
              ClButton(
                label: l10n.vxDeleteConfirm,
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
        if (ok != true || !context.mounted) return;
        final toaster = ClToaster.of(context);
        ref
            .read(vaccineRepositoryProvider)
            .delete(
              me.babyId,
              item,
              onError: (_) => toaster.show(message: l10n.vxSaveFailed),
            );
        if (record.photoPath case final photo?) {
          unawaited(ref.read(vaccinePhotoStoreProvider).remove(photo));
        }
        toaster.show(message: l10n.vxDeleted(title));
        if (context.canPop()) context.pop();
      }

      return _VxPage(
        trailing: canEdit && !declined
            ? ClPressable(
                key: const Key('vxEdit'),
                onPressed: () =>
                    showDoseFormSheet(context, me: me, book: book, item: item),
                semanticLabel: l10n.vxEditTitle,
                child: Container(
                  width: ClSpace.tapMin,
                  height: ClSpace.tapMin,
                  decoration: BoxDecoration(
                    color: cl.colors.surface,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: ClIcon(ClIcons.edit, size: 18, color: cl.colors.ink),
                ),
              )
            : null,
        children: [
          Wrap(
            spacing: ClSpace.s2,
            children: [
              declined
                  ? chip(
                      l10n.vxLegendDeclined,
                      cl.colors.surface2,
                      cl.colors.inkMuted,
                      icon: ClIcons.close,
                    )
                  : chip(
                      l10n.vxLegendGiven,
                      cl.colors.mintSoft,
                      cl.colors.mintText,
                      icon: ClIcons.check,
                    ),
              chip(
                item.months == 0
                    ? l10n.vxMilestoneBirth
                    : l10n.vxMilestoneShort(item.months),
                cl.colors.surface2,
                cl.colors.ink,
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          _Title(title),
          const SizedBox(height: ClSpace.s4),
          _Group(
            children: [
              if (!declined) ...[
                kv(
                  l10n.vxDate,
                  record.givenOn == null
                      ? l10n.vxNoDate
                      : [
                          vxLongDate(locale, record.givenOn!),
                          ?record.givenTime,
                        ].join(' · '),
                ),
                if (record.place != null || record.facility != null)
                  kv(
                    l10n.vxPlace,
                    [
                      if (record.place != null)
                        vxPlaceLabel(l10n, record.place!),
                      ?record.facility,
                    ].join(' · '),
                  ),
              ],
              kv(
                l10n.vxRecordedBy,
                reminderWho(l10n, record.author, record.createdBy == me.uid),
              ),
              if (!declined && record.reaction != null)
                kv(l10n.vxReactionShort, record.reaction!),
              if (declined && record.declineReason != null)
                kv(l10n.vxReason, record.declineReason!),
            ],
          ),
          if (!declined && record.photoPath != null) ...[
            const SizedBox(height: ClSpace.s4),
            Text(
              l10n.vxPhoto,
              style: cl.text.label.copyWith(color: cl.colors.inkMuted),
            ),
            const SizedBox(height: ClSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: VxPhotoThumb(
                key: const Key('vxDosePhoto'),
                path: record.photoPath!,
                onPressed: () =>
                    showVxPhotoViewer(context, [record.photoPath!]),
              ),
            ),
          ],
          if (!declined && next != null && !next.done) ...[
            const SizedBox(height: ClSpace.s3),
            Container(
              padding: const EdgeInsets.all(ClSpace.s3),
              decoration: BoxDecoration(
                color: cl.colors.sunshineSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  ClIcon(ClIcons.clock, size: 18, color: cl.colors.ink),
                  const SizedBox(width: ClSpace.s2),
                  Expanded(
                    child: Text(
                      '${l10n.vxNextDose(next.dose, vxDay(next.planned))} · '
                      '${book.plan.remind ? l10n.vxReminderOn : l10n.vxReminderOff}',
                      style: cl.text.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: ClSpace.s4),
            if (!declined && record.givenOn == null)
              ClButton(
                label: l10n.vxAddDate,
                style: ClButtonStyle.secondary,
                expand: true,
                onPressed: () =>
                    showDoseFormSheet(context, me: me, book: book, item: item),
              ),
            ClButton(
              label: declined ? l10n.vxUndoDecline : l10n.vxDelete,
              style: ClButtonStyle.plain,
              expand: true,
              onPressed: () => unawaited(delete()),
            ),
          ],
        ],
      );
    });
  }
}

// ---------- VX 7 ----------

/// A vaccine: what it is for, doses, timing, interval, where, and this baby's doses with "Ghi".
class VaccineInfoScreen extends ConsumerWidget {
  const VaccineInfoScreen({required this.vaccineId, super.key});
  final String vaccineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = vxLocale(context);
    return _withBook(context, ref, (me, book, dob) {
      final def = vaccineById(vaccineId, book.schedule);
      if (def == null) return const _VxPage(children: []);
      final oral = def.route == VaccineRoute.oral;
      final nickname = ref.watch(babyProvider(me.babyId)).value?.nickname ?? '';
      Widget kv(String k, String v) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                k,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: cl.text.label.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      final timing = def.months.every((m) => m == 0)
          ? l10n.vxBirth
          : l10n.vxTimingValue(def.months.join(' · '));
      return _VxPage(
        children: [
          _Title(vxName(locale, def, book.plan)),
          const SizedBox(height: ClSpace.s2),
          Text(
            def.about.of(locale),
            style: cl.text.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: cl.colors.inkMuted,
            ),
          ),
          const SizedBox(height: ClSpace.s4),
          _Group(
            children: [
              kv(
                oral ? l10n.vxDosesOral : l10n.vxDoses,
                oral
                    ? l10n.vxDoseCountOral(def.doses)
                    : l10n.vxDoseCount(def.doses),
              ),
              kv(l10n.vxTiming, timing),
              if (def.minIntervalWeeks != null)
                kv(
                  l10n.vxInterval,
                  l10n.vxIntervalValue(def.minIntervalWeeks!),
                ),
              kv(l10n.vxRoute, vxRouteLabel(l10n, def)),
              kv(
                l10n.vxPlace,
                vxProgrammeLabel(l10n, def, national: book.country != null),
              ),
            ],
          ),
          const SizedBox(height: ClSpace.s4),
          _Caption(l10n.vxBabyDoses(nickname)),
          _Group(
            children: [
              for (final i in book.rowOf(def.id))
                _ShotRow(
                  item: i,
                  book: book,
                  me: me,
                  title: l10n.vxDoseN(i.dose),
                  onTap: () => openDose(context, me, book, i),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s3),
          VxBanner(l10n.vxInfoBanner),
        ],
      );
    });
  }
}
