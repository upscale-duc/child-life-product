import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/route_guard.dart';
import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../l10n/app_localizations.dart';
import '../me/help_screen.dart';
import '../onboarding/widgets/onboarding_layout.dart';
import 'feedback_repository.dart';
import 'review_prompt.dart';

String feedbackTypeLabel(AppLocalizations l10n, FeedbackType t) => switch (t) {
  FeedbackType.idea => l10n.fbTypeIdea,
  FeedbackType.bug => l10n.fbTypeBug,
  FeedbackType.other => l10n.fbTypeOther,
};

ClIcons _typeIcon(FeedbackType t) => switch (t) {
  FeedbackType.idea => ClIcons.spark,
  FeedbackType.bug => ClIcons.alert,
  FeedbackType.other => ClIcons.mail,
};

/// FB2 "Ảnh chụp màn hình": a picture from the library, re-encoded without EXIF.
final feedbackShotPickerProvider = Provider<Future<FeedbackShot?> Function()>(
  (ref) => () async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      requestFullMetadata: false,
    );
    if (file == null) return null;
    return FeedbackShot(
      await FlutterImageCompress.compressWithList(
        await file.readAsBytes(),
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
      ),
      png: false,
    );
  },
);

/// FB2 Góp ý (477:6493), opened as a modal from Tôi (FB1) or from FB4 "Báo lỗi" with the
/// screenshot attached. A "Vào ngay" identity can send too, without "Cho phép liên hệ lại".
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({this.type = FeedbackType.idea, super.key});
  final FeedbackType type;

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  late FeedbackType _type = widget.type;
  FeedbackShot? _shot;
  var _device = true;
  bool? _reply;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // FB4's capture, handed over once.
    _shot = ref.read(pendingShotProvider);
    if (_shot != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(pendingShotProvider.notifier).set(null),
      );
    }
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String? get _email {
    final session = ref.read(sessionProvider);
    if (session is! SessionSignedIn || session.isAnonymous) return null;
    final email = session.user.email;
    return email == null || email.isEmpty ? null : email;
  }

  Future<void> _pick() async {
    final shot = await ref.read(feedbackShotPickerProvider)();
    if (shot != null && mounted) setState(() => _shot = shot);
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final router = GoRouter.of(context);
    final reply = (_reply ?? true) && _email != null;
    setState(() => _busy = true);
    try {
      await ref
          .read(feedbackRepositoryProvider)
          .send(
            type: _type,
            message: _message.text,
            shot: _shot,
            diagnostics: _device ? await deviceSnapshot(ref) : null,
            replyByEmail: reply,
            locale: locale == 'en' ? 'en' : 'vi',
          );
      // FB5: no rating prompt for 30 days after a bug report.
      if (_type == FeedbackType.bug) {
        unawaited(ref.read(reviewPrompterProvider).bugReported(DateTime.now()));
      }
      ref.invalidate(myTicketsProvider);
      router.replace(
        reply ? Routes.meFeedbackSent : '${Routes.meFeedbackSent}?reply=0',
      );
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      showClToast(context, message: l10n.fbSendFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final email = _email;
    final reply = email != null && (_reply ?? true);
    return OnboardingScaffold(
      topBar: Padding(
        padding: const EdgeInsets.only(top: ClSpace.s2),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ClPressable(
            semanticLabel: l10n.a11yClose,
            onPressed: () => context.pop(),
            child: Container(
              width: ClSpace.tapMin,
              height: ClSpace.tapMin,
              decoration: BoxDecoration(
                color: cl.colors.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: ClIcon(ClIcons.close, size: 20, color: cl.colors.ink),
            ),
          ),
        ),
      ),
      content: [
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text(l10n.fbTitle, style: cl.text.title),
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.fbIntro,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted, height: 1.5),
        ),
        const SizedBox(height: ClSpace.s4),
        Row(
          children: [
            for (final t in FeedbackType.values) ...[
              if (t != FeedbackType.values.first)
                const SizedBox(width: ClSpace.s2),
              Expanded(
                child: _TypeChip(
                  label: feedbackTypeLabel(l10n, t),
                  icon: _typeIcon(t),
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: ClSpace.s4),
        Text(
          l10n.fbMessageLabel,
          style: cl.text.caption.copyWith(
            color: cl.colors.inkMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        _MessageBox(controller: _message, label: l10n.fbMessageLabel),
        const SizedBox(height: ClSpace.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: _ShotTile(
            shot: _shot,
            onPick: _pick,
            onRemove: () => setState(() => _shot = null),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: cl.colors.surface,
            boxShadow: cl.shadows.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ToggleRow(
                title: l10n.fbDevice,
                subtitle: l10n.fbDeviceHint,
                value: _device,
                onChanged: (v) => setState(() => _device = v),
              ),
              _ToggleRow(
                title: l10n.fbReply,
                subtitle: email ?? l10n.fbReplyNoEmail,
                value: reply,
                onChanged: email == null
                    ? null
                    : (v) => setState(() => _reply = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s4),
      ],
      bottom: [
        ClButton(
          label: l10n.fbSend,
          expand: true,
          loading: _busy,
          onPressed: _busy || _message.text.trim().isEmpty ? null : _send,
        ),
      ],
    );
  }
}

/// FB2 type chip: equal thirds, icon 14 + SemiBold 13; selected = mint-soft with a mint-deep edge.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final ClIcons icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    final ink = selected ? c.mintText : c.ink;
    return Semantics(
      selected: selected,
      button: true,
      child: ClPressable(
        onPressed: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
          decoration: BoxDecoration(
            color: selected ? c.mintSoft : c.surface,
            borderRadius: BorderRadius.circular(ClRadius.pill),
            border: Border.all(color: selected ? c.mintDeep : c.separator),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(icon, size: 14, color: ink),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.cl.text.caption.copyWith(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

/// FB2 message: a 120 tall box, control-border edge, radius 14.
class _MessageBox extends StatelessWidget {
  const _MessageBox({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cl.colors.controlBorder),
    );
    return SizedBox(
      height: 120,
      child: TextField(
        controller: controller,
        expands: true,
        maxLines: null,
        maxLength: 2000,
        textAlignVertical: TextAlignVertical.top,
        textCapitalization: TextCapitalization.sentences,
        style: cl.text.body.copyWith(fontSize: 15, height: 1.45),
        decoration: InputDecoration(
          semanticCounterText: '',
          counterText: '',
          filled: true,
          fillColor: cl.colors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: cl.colors.mintDeep, width: 1.5),
          ),
          hintText: label,
          hintStyle: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
      ),
    );
  }
}

/// FB2 "Ảnh chụp màn hình": a dashed 150 × 80 tile; once attached, the picture with "×".
class _ShotTile extends StatelessWidget {
  const _ShotTile({
    required this.shot,
    required this.onPick,
    required this.onRemove,
  });

  final FeedbackShot? shot;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final shot = this.shot;
    if (shot != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              shot.bytes,
              width: 80,
              height: 120,
              fit: BoxFit.cover,
              semanticLabel: l10n.fbScreenshot,
            ),
          ),
          Positioned(
            top: -10,
            right: -10,
            child: ClPressable(
              semanticLabel: l10n.fbScreenshotRemove,
              onPressed: onRemove,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cl.colors.ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: cl.colors.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: ClIcon(
                  ClIcons.close,
                  size: 14,
                  color: cl.colors.surface,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return ClPressable(
      semanticLabel: l10n.fbScreenshot,
      onPressed: onPick,
      child: CustomPaint(
        painter: _DashedBorder(cl.colors.controlBorder),
        child: SizedBox(
          width: 150,
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClIcon(ClIcons.camera, size: 20, color: cl.colors.inkMuted),
              const SizedBox(height: ClSpace.s1),
              Text(
                l10n.fbScreenshot,
                style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(16),
        ).deflate(0.5),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// FB2 settings row: SemiBold 15 title, Medium 12 subtitle, the iOS switch at 85 %.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: cl.text.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: cl.text.caption.copyWith(
                        color: cl.colors.inkMuted,
                        letterSpacing: 0,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Transform.scale(
                scale: 0.85,
                child: CupertinoSwitch(
                  value: value,
                  activeTrackColor: cl.colors.mintDeep,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FB3 Đã gửi góp ý (477:6549): no top bar, everything centred, "Xong" right under the text.
class FeedbackSentScreen extends StatelessWidget {
  const FeedbackSentScreen({this.reply = true, super.key});

  /// "Cho phép liên hệ lại" was on: the team may write back.
  final bool reply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    return Scaffold(
      backgroundColor: cl.colors.cloud,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ClSpace.s4,
            100,
            ClSpace.s4,
            ClSpace.s6,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cl.colors.mintSoft,
                  shape: BoxShape.circle,
                ),
                child: ClIcon(
                  ClIcons.check,
                  size: 40,
                  color: cl.colors.mintDeep,
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              Semantics(
                header: true,
                child: Text(
                  l10n.fbSentTitle,
                  textAlign: TextAlign.center,
                  style: cl.text.title.copyWith(fontSize: 26),
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              Text(
                reply ? l10n.fbSentBody : l10n.fbSentBodyNoReply,
                textAlign: TextAlign.center,
                style: cl.text.body.copyWith(
                  fontSize: 15,
                  height: 1.5,
                  color: cl.colors.inkMuted,
                ),
              ),
              const SizedBox(height: ClSpace.s4),
              ClButton(
                label: l10n.fbDone,
                expand: true,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
