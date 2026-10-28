import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../care/care_repository.dart';
import '../home/home_shell.dart';
import '../memories/memory_repository.dart';
import '../notifications/notification_bell.dart';
import 'header_settings.dart';
import 'header_photo_cache.dart';

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

// Resolve the saved local image while metadata is loading; known deletion,
// avatar replacement and permission changes invalidate it immediately.
final headerPhotoProvider = Provider.family<ImageProvider?, HeaderSettings>((
  ref,
  settings,
) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || settings.background == HeaderBackground.pattern) {
    return null;
  }
  final cache = ref.watch(headerPhotoCacheProvider);
  final choice = '${settings.background.name}:${settings.mediaId ?? ''}';
  if (me.role == MemberRole.coParent) {
    ref.watch(headerCachedPhotoProvider((me.uid, me.babyId)));
  }
  final cached = me.role == MemberRole.coParent
      ? cache.read(me.uid, me.babyId, choice)
      : null;
  final saved = ref.watch(headerSettingsProvider);
  final applied =
      saved.background == settings.background &&
      saved.mediaId == settings.mediaId;
  ImageProvider? resolved(Uint8List? bytes, String source) {
    if (bytes != null) {
      if (applied && me.role == MemberRole.coParent) {
        unawaited(
          cache
              .remember(me.uid, me.babyId, choice, source, bytes)
              .catchError((Object _) {}),
        );
        final remembered = cache.read(me.uid, me.babyId, choice);
        if (remembered?.source == source) return remembered?.image;
      }
      return MemoryImage(bytes);
    }
    return cached?.source == source ? cached?.image : null;
  }

  void discard() {
    if (applied) {
      unawaited(cache.forget(me.uid, me.babyId).catchError((Object _) {}));
    }
  }

  final baby = ref.watch(babyProvider(me.babyId));
  if (settings.background == HeaderBackground.avatar) {
    if (!baby.hasValue) return cached?.image;
    if (baby.value?.avatar case PhotoAvatar(:final version)) {
      return resolved(
        ref.watch(babyAvatarPhotoProvider((me.babyId, version))).value,
        'avatar:$version',
      );
    }
    discard();
    return null;
  }
  final media = ref.watch(
    mediaProvider((me.babyId, me.role == MemberRole.coParent)),
  );
  if (!media.hasValue) return cached?.image;
  final item = (media.value ?? const [])
      .where(
        (m) =>
            m.id == settings.mediaId && m.isReady && !m.deleted && !m.isVideo,
      )
      .firstOrNull;
  final path = item?.displayPath;
  if (path == null) {
    discard();
    return null;
  }
  return resolved(ref.watch(headerMemoryBytesProvider(path)).value, path);
});

class TodayLivingHeader extends ConsumerWidget {
  const TodayLivingHeader({this.settings, this.preview = false, super.key});
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
      contentLift: 0,
      top: const BabyHeader(
        hero: true,
        actions: [
          NotificationBell(hero: true),
          SizedBox(width: ClSpace.s2),
          NightCareToggle(hero: true),
        ],
      ),
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
    this.contentLift = 0,
    super.key,
  });
  final HeaderMoment moment;
  final String title;
  final Widget top;
  final Widget? duty;
  final ImageProvider? photo;
  final double topInset;

  /// Let following content overlap the faded footer without cropping the photo.
  /// Only decorative paint overflows; controls retain their actual layout/hit areas.
  final double contentLift;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final base = switch (moment) {
      HeaderMoment.morning => cl.colors.sunshineSoft,
      HeaderMoment.afternoon => cl.colors.mintSoft,
      HeaderMoment.evening => cl.care.sleep.soft,
      HeaderMoment.birthday => cl.colors.peachSoft,
    };
    final visualMinHeight = (duty == null ? 164 : 208) + topInset;
    return ClipRect(
      clipBehavior: Clip.none,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, layout) {
                // Preserve the previous photo/art height and crop. At large text
                // sizes the foreground grows naturally and needs no overlap.
                final artHeight = layout.maxHeight.clamp(
                  visualMinHeight,
                  double.infinity,
                );
                return OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: artHeight,
                  maxHeight: artHeight,
                  child: ClipRect(
                    key: const Key('todayHeaderArtwork'),
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
                                    errorBuilder: (_, _, _) =>
                                        ColoredBox(color: base),
                                  ),
                                ),
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: base.withValues(alpha: .25),
                                  ),
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
                                        for (final a in [
                                          0.0,
                                          0.0,
                                          .24,
                                          .65,
                                          1.0,
                                        ])
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
                );
              },
            ),
          ),
          ConstrainedBox(
            key: const Key('todayLivingHeader'),
            constraints: BoxConstraints(
              minHeight: visualMinHeight - contentLift,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                ClSpace.s4,
                topInset + ClSpace.s2,
                ClSpace.s4,
                ClSpace.s3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      top,
                      const SizedBox(height: ClSpace.s4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: MediaQuery.textScalerOf(context).scale(1) > 1.3
                              ? double.infinity
                              : MediaQuery.sizeOf(context).width * .56,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              key: const Key('axGreeting'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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
                      padding: const EdgeInsets.only(top: ClSpace.s3),
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
