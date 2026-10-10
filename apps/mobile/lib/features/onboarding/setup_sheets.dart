import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/platform/external_apps.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/time_zones.dart';
import 'setup_draft.dart';
import 'setup_screens.dart';

/// Sheet body with header, content and the "Xong" button (SheetHeader 37:293).
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.children,
    required this.onDone,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ClSpace.s4,
        0,
        ClSpace.s4,
        MediaQuery.of(context).padding.bottom + ClSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClSheetHeader(
            title: title,
            onClose: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: ClSpace.s2),
          ...children,
          const SizedBox(height: ClSpace.s4),
          ClButton(label: l10n.actionDone, expand: true, onPressed: onDone),
        ],
      ),
    );
  }
}

/// 11a Chọn ngày sinh (38:1498): wheel, default today, no future date, live age.
Future<void> showDobSheet(BuildContext context) =>
    showClSheet<void>(context: context, builder: (_) => const _DobSheet());

class _DobSheet extends ConsumerStatefulWidget {
  const _DobSheet();

  @override
  ConsumerState<_DobSheet> createState() => _DobSheetState();
}

class _DobSheetState extends ConsumerState<_DobSheet> {
  late DateTime _value = ref.read(setupDraftProvider).dateOfBirth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final draft = ref.watch(setupDraftProvider);
    return _SheetFrame(
      title: l10n.babyDob,
      onDone: () {
        ref
            .read(setupDraftProvider.notifier)
            .update(draft.copyWith(dateOfBirth: _value));
        Navigator.of(context).pop();
      },
      children: [
        SizedBox(
          height: 216,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: cl.text.headline.copyWith(
                  color: cl.colors.ink,
                  fontSize: 21,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              dateOrder: DatePickerDateOrder.dmy,
              initialDateTime: _value.isAfter(today) ? today : _value,
              maximumDate: today,
              minimumDate: DateTime(
                today.year - maxBabyAgeYears,
                today.month,
                today.day,
              ),
              onDateTimeChanged: (d) =>
                  setState(() => _value = DateTime(d.year, d.month, d.day)),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          liveRegion: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(ClIcons.cake, size: 16, color: cl.colors.mintText),
              const SizedBox(width: ClSpace.s1),
              Text(
                dobHint(l10n, draft.nickname, _value),
                style: cl.text.label.copyWith(color: cl.colors.mintText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Oldest selectable birth date (mirrors contracts `maxBabyAgeYears`).
const maxBabyAgeYears = 18;

/// 11b Chọn múi giờ (38:1581).
Future<void> showTimeZoneSheet(BuildContext context) =>
    showClSheet<void>(context: context, builder: (_) => const _TimeZoneSheet());

class _TimeZoneSheet extends ConsumerStatefulWidget {
  const _TimeZoneSheet();

  @override
  ConsumerState<_TimeZoneSheet> createState() => _TimeZoneSheetState();
}

class _TimeZoneSheetState extends ConsumerState<_TimeZoneSheet> {
  final _query = TextEditingController();
  late TimeZoneSetting? _value = ref.read(setupDraftProvider).timeZone;
  String? _device;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    unawaited(
      deviceTimeZone().then((z) {
        if (mounted) setState(() => _device = z);
      }),
    );
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final results = searchZones(_query.text);
    final device = _device;
    final auto = _value?.auto ?? true;
    return _SheetFrame(
      title: l10n.babyTimeZone,
      onDone: () {
        final value =
            _value ??
            (device == null ? null : TimeZoneSetting(zone: device, auto: true));
        if (value != null) {
          final draft = ref.read(setupDraftProvider);
          ref
              .read(setupDraftProvider.notifier)
              .update(draft.copyWith(timeZone: value));
        }
        Navigator.of(context).pop();
      },
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
          decoration: BoxDecoration(
            color: cl.colors.surface2,
            borderRadius: BorderRadius.circular(ClRadius.pill),
          ),
          child: Row(
            children: [
              ClIcon(ClIcons.search, size: 18, color: cl.colors.inkMuted),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: CupertinoTextField.borderless(
                  controller: _query,
                  padding: EdgeInsets.zero,
                  placeholder: l10n.tzSearch,
                  placeholderStyle: cl.text.label.copyWith(
                    color: cl.colors.inkMuted,
                  ),
                  style: cl.text.label.copyWith(color: cl.colors.ink),
                  cursorColor: cl.colors.mintDeep,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClSettingRow(
          icon: ClIcons.globe,
          title: l10n.tzAuto,
          subtitle: device == null
              ? null
              : l10n.tzAutoUsing(
                  gmtOffsetLabel(device, now),
                  placeOf(device, lang),
                ),
          value: auto,
          onChanged: device == null
              ? null
              : (on) => setState(
                  () => _value = on
                      ? TimeZoneSetting(zone: device, auto: true)
                      : TimeZoneSetting(
                          zone: _value?.zone ?? device,
                          auto: false,
                        ),
                ),
        ),
        const SizedBox(height: ClSpace.s3),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(ClSpace.s4),
                  child: Text(
                    l10n.tzNoResults,
                    textAlign: TextAlign.center,
                    style: cl.text.label.copyWith(color: cl.colors.inkMuted),
                  ),
                )
              : SingleChildScrollView(
                  child: ClCardGroup(
                    children: [
                      for (final choice in results)
                        ClOptionRow(
                          title: gmtOffsetLabel(choice.zone, now),
                          subtitle: choice.cities(lang),
                          selected: !auto && _value?.zone == choice.zone,
                          onTap: () => setState(
                            () => _value = TimeZoneSetting(
                              zone: choice.zone,
                              auto: false,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// 11c Chọn ảnh đại diện (41:1861): camera / library / 4 illustrations; family-private.
Future<void> showAvatarSheet(BuildContext context) =>
    showClSheet<void>(context: context, builder: (_) => const _AvatarSheet());

class _AvatarSheet extends ConsumerStatefulWidget {
  const _AvatarSheet();

  @override
  ConsumerState<_AvatarSheet> createState() => _AvatarSheetState();
}

class _AvatarSheetState extends ConsumerState<_AvatarSheet> {
  late int _preset = ref.read(setupDraftProvider).avatarPreset;
  late bool _photo = ref.read(setupDraftProvider).avatarPhoto != null;
  bool _busy = false;

  Future<void> _pick(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        requestFullMetadata: false,
      );
      if (file == null) return;
      // Re-encode to a 512 px JPEG without metadata (no location in the family-private photo).
      final jpeg = await FlutterImageCompress.compressWithList(
        await file.readAsBytes(),
        minWidth: 512,
        minHeight: 512,
        quality: 85,
        keepExif: false,
      );
      final draft = ref.read(setupDraftProvider);
      ref
          .read(setupDraftProvider.notifier)
          .update(draft.copyWith(avatarPhoto: jpeg));
      if (mounted) Navigator.of(context).pop();
    } on PlatformException catch (e) {
      if (!mounted) return;
      final denied = e.code.contains('denied') || e.code.contains('access');
      showClToast(
        context,
        message: denied
            ? (source == ImageSource.camera
                  ? l10n.avatarCameraDenied
                  : l10n.avatarLibraryDenied)
            : l10n.authErrorGeneric,
        actionLabel: denied ? l10n.actionOpenSettings : null,
        onAction: denied ? openAppSettings : null,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    Widget action(ClIcons icon, String label, ImageSource source) =>
        ClPressable(
          semanticLabel: label,
          onPressed: _busy ? null : () => _pick(source),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClSpace.s4,
              vertical: ClSpace.s4,
            ),
            child: Row(
              children: [
                ClIcon(icon, size: 20, color: cl.colors.mintText),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Text(
                    label,
                    style: cl.text.body.copyWith(color: cl.colors.ink),
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
        );
    return _SheetFrame(
      title: l10n.avatarTitle,
      onDone: () {
        if (!_photo) {
          final draft = ref.read(setupDraftProvider);
          ref
              .read(setupDraftProvider.notifier)
              .update(draft.copyWith(avatarPreset: _preset, clearPhoto: true));
        }
        Navigator.of(context).pop();
      },
      children: [
        Container(
          decoration: BoxDecoration(
            color: cl.colors.mintSoft,
            borderRadius: BorderRadius.circular(ClRadius.card),
          ),
          child: Column(
            children: [
              action(ClIcons.camera, l10n.avatarCamera, ImageSource.camera),
              Container(height: 1, color: cl.colors.separator),
              action(ClIcons.memories, l10n.avatarLibrary, ImageSource.gallery),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.avatarOrIllustration,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var preset = 1; preset <= 4; preset++)
              _PresetChoice(
                preset: preset,
                selected: !_photo && _preset == preset,
                label: l10n.avatarPreset(preset),
                onTap: () => setState(() {
                  _preset = preset;
                  _photo = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClIcon(ClIcons.lock, size: 14, color: cl.colors.inkMuted),
            const SizedBox(width: ClSpace.s1),
            Flexible(
              child: Text(
                l10n.avatarPrivacy,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChoice extends StatelessWidget {
  const _PresetChoice({
    required this.preset,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final int preset;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Semantics(
      selected: selected,
      child: ClPressable(
        semanticLabel: label,
        onPressed: onTap,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? cl.colors.mintDeep : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              BabyAvatarImage.preset(preset, size: 64),
              if (selected)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cl.colors.mintDeep,
                      shape: BoxShape.circle,
                      border: Border.all(color: cl.colors.surface, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: ClIcon(
                      ClIcons.check,
                      size: 12,
                      color: cl.colors.onMintDeep,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
