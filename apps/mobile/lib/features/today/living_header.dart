import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_duty.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../memories/media_bytes.dart';
import '../memories/memory_repository.dart';
import '../notifications/notification_bell.dart';
import 'header_settings.dart';

enum HeaderMoment { morning, afternoon, evening, birthday }

HeaderMoment headerMoment(DateTime localNow, {DateTime? birthday}) {
  if (birthday != null &&
      birthday.month == localNow.month &&
      birthday.day == localNow.day &&
      localNow.year > birthday.year) {
    return HeaderMoment.birthday;
  }
  return localNow.hour >= 5 && localNow.hour < 11
      ? HeaderMoment.morning
      : localNow.hour >= 11 && localNow.hour < 18
      ? HeaderMoment.afternoon
      : HeaderMoment.evening;
}

// Only resolves media still visible to this viewer. A deleted/revoked photo falls back to art.
final headerPhotoProvider = Provider.family<ImageProvider?, HeaderSettings>((
  ref,
  settings,
) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || settings.background == HeaderBackground.pattern) {
    return null;
  }
  final baby = ref.watch(babyProvider(me.babyId)).value;
  if (settings.background == HeaderBackground.avatar) {
    if (baby?.avatar case PhotoAvatar(:final version)) {
      final Uint8List? bytes = ref
          .watch(babyAvatarPhotoProvider((me.babyId, version)))
          .value;
      if (bytes != null) return MemoryImage(bytes);
    }
    return null;
  }
  final items =
      ref
          .watch(mediaProvider((me.babyId, me.role == MemberRole.coParent)))
          .value ??
      const [];
  final media = items
      .where(
        (m) =>
            m.id == settings.mediaId && m.isReady && !m.deleted && !m.isVideo,
      )
      .firstOrNull;
  final path = media?.displayPath;
  return path == null ? null : StorageImage(path);
});

class TodayLivingHeader extends ConsumerWidget {
  const TodayLivingHeader({
    required this.showDuty,
    this.settings,
    this.preview = false,
    super.key,
  });
  final bool showDuty;
  final HeaderSettings? settings;
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(selectedMembershipProvider);
    final baby = me == null ? null : ref.watch(babyProvider(me.babyId)).value;
    final now = ref.watch(careClockProvider).value ?? DateTime.now();
    final local = inBabyZone(baby?.timeZone.zone ?? 'Asia/Ho_Chi_Minh', now);
    final profile = me?.canViewBabyInfo == true
        ? ref.watch(babyPrivateProfileProvider(me!.babyId)).value
        : null;
    final moment = headerMoment(local, birthday: profile?.dateOfBirth);
    final HeaderSettings selected =
        settings ?? ref.watch(headerSettingsProvider);
    final name = baby?.nickname.trim() ?? '';
    final l = AppLocalizations.of(context);
    final title = switch (moment) {
      HeaderMoment.morning =>
        name.isEmpty ? l.hhMorningNoName : l.hhMorning(name),
      HeaderMoment.afternoon =>
        name.isEmpty ? l.hhAfternoonNoName : l.hhAfternoon(name),
      HeaderMoment.evening =>
        name.isEmpty ? l.hhEveningNoName : l.hhEvening(name),
      HeaderMoment.birthday => l.hhBirthday(name),
    };
    return LivingHeaderView(
      moment: moment,
      title: title,
      photo: ref.watch(headerPhotoProvider(selected)),
      topInset: preview ? 0 : MediaQuery.paddingOf(context).top,
      top: const BabyHeader(
        hero: true,
        actions: [
          NotificationBell(hero: true),
          SizedBox(width: ClSpace.s2),
          NightCareToggle(hero: true),
        ],
      ),
      duty: showDuty ? const CareDutyChip(hero: true) : null,
    );
  }
}

/// Header geometry comes from 1187:15786, with live text and existing interactive controls.
/// A minimum height allows long names and Dynamic Type to grow instead of clipping.
class LivingHeaderView extends StatelessWidget {
  const LivingHeaderView({
    required this.moment,
    required this.title,
    required this.top,
    this.duty,
    this.photo,
    this.topInset = 0,
    super.key,
  });
  final HeaderMoment moment;
  final String title;
  final Widget top;
  final Widget? duty;
  final ImageProvider? photo;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final base = switch (moment) {
      HeaderMoment.morning => cl.colors.sunshineSoft,
      HeaderMoment.afternoon => cl.colors.mintSoft,
      HeaderMoment.evening => cl.care.sleep.soft,
      HeaderMoment.birthday => cl.colors.peachSoft,
    };
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = box.maxWidth / 375;
                final (w, h) = switch (moment) {
                  HeaderMoment.morning => (646.0, 522.0),
                  HeaderMoment.afternoon => (630.0, 528.0),
                  HeaderMoment.evening => (640.0, 522.0),
                  HeaderMoment.birthday => (620.0, 528.0),
                };
                return ExcludeSemantics(
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: base)),
                      if (photo != null) ...[
                        Positioned.fill(
                          left: box.maxWidth * .28,
                          child: Image(
                            image: photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(color: base),
                          ),
                        ),
                        Positioned.fill(
                          child: ColoredBox(color: base.withValues(alpha: .25)),
                        ),
                        Positioned.fill(
                          child: ColoredBox(
                            color: cl.colors.cloud.withValues(
                              alpha: cl.isNightCare ? .35 : .28,
                            ),
                          ),
                        ),
                      ],
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: photo == null ? w : 375,
                            height: photo == null ? h : 360,
                            child: SvgPicture.asset(
                              'assets/today/header-${photo == null ? moment.name : 'photo-stars'}.svg',
                              colorMapper: _HeaderColors(cl),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: photo == null
                                  ? [
                                      base,
                                      base,
                                      base.withValues(alpha: 0),
                                      base.withValues(alpha: 0),
                                    ]
                                  : [
                                      for (final alpha
                                          in cl.isNightCare
                                              ? [
                                                  1.0,
                                                  1.0,
                                                  .97,
                                                  .82,
                                                  .55,
                                                  .18,
                                                  0.0,
                                                ]
                                              : [
                                                  1.0,
                                                  1.0,
                                                  .88,
                                                  .6,
                                                  .26,
                                                  .04,
                                                  0.0,
                                                ])
                                        (cl.isNightCare
                                                ? cl.colors.cloud
                                                : base)
                                            .withValues(alpha: alpha),
                                    ],
                              stops: photo == null
                                  ? const [0, .34, .58, 1]
                                  : const [0, .28, .4, .55, .72, .9, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                for (final a in [0.0, 0.0, .24, .65, 1.0])
                                  cl.colors.cloud.withValues(alpha: a),
                              ],
                              stops: const [0, .45, .7, .88, 1],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ConstrainedBox(
            key: const Key('todayLivingHeader'),
            constraints: BoxConstraints(
              minHeight: (duty == null ? 224 : 320) + topInset,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                topInset + ClSpace.s3,
                ClSpace.s4,
                ClSpace.s6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      top,
                      const SizedBox(height: ClSpace.s6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(1) > 1.3
                              ? double.infinity
                              : 210,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              key: const Key('axGreeting'),
                              style: cl.text.title.copyWith(
                                color: cl.colors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (duty != null)
                    Padding(
                      padding: const EdgeInsets.only(top: ClSpace.s6),
                      child: duty!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderColors extends ColorMapper {
  const _HeaderColors(this.cl);
  final ClTheme cl;
  @override
  Color substitute(String? id, String element, String attribute, Color color) {
    if (!cl.isNightCare) return color;
    return {
          lightColors.surface: cl.colors.surface,
          lightColors.mintSoft: cl.colors.mintSoft,
          lightColors.mint: cl.colors.mint,
          lightColors.mintDeep: cl.colors.mintDeep,
          lightColors.peach: cl.colors.peach,
          lightColors.peachSoft: cl.colors.peachSoft,
          lightColors.sunshine: cl.colors.sunshine,
          lightCareColors.sleep.soft: cl.care.sleep.soft,
        }[color] ??
        color;
  }
}
