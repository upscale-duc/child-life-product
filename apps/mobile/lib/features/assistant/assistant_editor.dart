import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../care/care_repository.dart' show inBabyZone;
import '../care/care_sheets.dart' show pickCareTime;
import 'assistant_controller.dart';
import 'assistant_labels.dart';
import 'assistant_models.dart';
import 'assistant_repository.dart';

/// CH06 · Sửa bản nháp (Chat/Biểu mẫu nháp): edits the draft only ("Cập nhật bản nháp", never
/// "Lưu"); the same checks as the care forms (future completed logs, units, sleep order) run
/// first, then `patchDraft` validates again (revision +1). The baby is locked: a draft never
/// moves to another child.
Future<void> showDraftEditor(
  BuildContext context, {
  required String scopeKey,
  required AssistantDraft draft,
  required String babyName,
  required String zone,
}) => showClSheet<void>(
  context: context,
  builder: (_) => _DraftEditor(
    scopeKey: scopeKey,
    draft: draft,
    babyName: babyName,
    zone: zone,
  ),
);

class _DraftEditor extends ConsumerStatefulWidget {
  const _DraftEditor({
    required this.scopeKey,
    required this.draft,
    required this.babyName,
    required this.zone,
  });

  final String scopeKey;
  final AssistantDraft draft;
  final String babyName;
  final String zone;

  @override
  ConsumerState<_DraftEditor> createState() => _DraftEditorState();
}

class _DraftEditorState extends ConsumerState<_DraftEditor> {
  late DraftPayload _payload = widget.draft.payload;
  late final _amount = TextEditingController(text: _initialNumber());
  var _problems = <DraftProblem>[];
  var _busy = false;

  String _initialNumber() => switch (_payload) {
    BottlePayload(:final amountMl?) => '${amountMl.round()}',
    BreastPayload(:final durationMin?) => '$durationMin',
    _ => '',
  };

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  DraftPayload _withNumber() {
    final n = int.tryParse(_amount.text.trim());
    return switch (_payload) {
      final BottlePayload p => BottlePayload(
        amountMl: n,
        occurredAt: p.occurredAt,
        milk: p.milk,
      ),
      final BreastPayload p => BreastPayload(
        occurredAt: p.occurredAt,
        durationMin: n,
        side: p.side,
      ),
      final p => p,
    };
  }

  Future<DateTime?> _pick(DateTime? current) async {
    final now = ref.read(assistantClockProvider)();
    final wall = inBabyZone(widget.zone, current ?? now);
    final picked = await pickCareTime(context, initial: wall);
    return picked == null ? null : fromBabyWall(widget.zone, picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final toaster = ClToaster.of(context);
    final navigator = Navigator.of(context);
    final payload = _withNumber();
    setState(() => _busy = true);
    final (outcome, problems) = await ref
        .read(assistantChatProvider(widget.scopeKey).notifier)
        .patch(widget.draft, payload);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problems = problems;
      _payload = payload;
    });
    switch (outcome) {
      case ActionOutcome.ok:
        navigator.pop();
      case ActionOutcome.offline:
        toaster.show(message: l10n.asSaveOffline, error: true);
      case ActionOutcome.stale:
        navigator.pop();
        toaster.show(message: l10n.asErrStale, error: true);
      case ActionOutcome.failed when problems.isEmpty:
        toaster.show(message: l10n.asEditFailed, error: true);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final now = ref.watch(assistantClockProvider)();
    String when(DateTime? at) => at == null
        ? l10n.asNoTime
        : '${dayLabel(l10n, locale, at, widget.zone, now)} · ${hm(at, widget.zone)}';
    final title = switch (_payload) {
      BreastPayload() => l10n.asEditBreast,
      SleepPayload() => l10n.asEditSleep,
      _ => l10n.asEditBottle,
    };
    final fields = <Widget>[
      _Field(
        label: l10n.asFieldBaby,
        value: widget.babyName,
        trailing: ClIcon(ClIcons.lock, size: 14, color: cl.colors.inkMuted),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text(
          l10n.asBabyLocked,
          style: cl.text.caption.copyWith(color: cl.colors.inkMuted),
        ),
      ),
      ...switch (_payload) {
        final BottlePayload p => [
          _Field(
            label: l10n.asFieldWhen,
            value: when(p.occurredAt),
            onTap: () async {
              final at = await _pick(p.occurredAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(occurredAt: at));
            },
          ),
          _NumberField(
            label: l10n.asFieldAmount,
            controller: _amount,
            suffix: 'ml',
          ),
        ],
        final BreastPayload p => [
          _Field(
            label: l10n.asFieldWhen,
            value: when(p.occurredAt),
            onTap: () async {
              final at = await _pick(p.occurredAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(occurredAt: at));
            },
          ),
          _NumberField(
            label: l10n.asFieldMinutes,
            controller: _amount,
            suffix: l10n.durationMinutes(0).replaceAll('0', '').trim(),
          ),
          const SizedBox(height: ClSpace.s2),
          Row(
            children: [
              Text(
                l10n.asFieldSide,
                style: cl.text.label.copyWith(color: cl.colors.inkMuted),
              ),
              const SizedBox(width: ClSpace.s3),
              for (final (wire, label) in [
                ('left', l10n.sideLeft),
                ('right', l10n.sideRight),
                ('both', l10n.sideBoth),
              ]) ...[
                _SideChip(
                  label: label,
                  selected: p.side == wire,
                  onPressed: () =>
                      setState(() => _payload = p.copyWith(side: wire)),
                ),
                const SizedBox(width: ClSpace.s2),
              ],
            ],
          ),
        ],
        final SleepPayload p => [
          _Field(
            label: l10n.asFieldStart,
            value: when(p.startedAt),
            onTap: () async {
              final at = await _pick(p.startedAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(startedAt: at));
            },
          ),
          _Field(
            label: l10n.asFieldEnd,
            value: when(p.endedAt),
            onTap: () async {
              final at = await _pick(p.endedAt);
              if (at == null) return;
              setState(() => _payload = p.copyWith(endedAt: at));
            },
          ),
        ],
        _ => const <Widget>[],
      },
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: title),
        for (final f in fields) ...[f, const SizedBox(height: ClSpace.s2)],
        for (final p in _problems)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                problemLabel(l10n, p),
                style: cl.text.caption.copyWith(color: cl.colors.error),
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          label: l10n.asUpdateDraft,
          expand: true,
          loading: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: ClSpace.s4),
      ],
    );
  }
}

/// A Chat/Biểu mẫu nháp row: muted label left, SemiBold value right (cloud fill, radius 14).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final row = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cl.colors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          Text(label, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
    return onTap == null
        ? Semantics(
            label: '$label, $value',
            child: ExcludeSemantics(child: row),
          )
        : ClPressable(
            onPressed: onTap,
            semanticLabel: '$label, $value',
            pressedOpacity: 0.7,
            child: row,
          );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: cl.colors.cloud,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cl.colors.controlBorder),
      ),
      child: Row(
        children: [
          Text(label, style: cl.text.label.copyWith(color: cl.colors.inkMuted)),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.end,
              style: cl.text.label.copyWith(
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
              decoration: InputDecoration.collapsed(
                hintText: '',
              ).copyWith(semanticCounterText: label),
            ),
          ),
          const SizedBox(width: 6),
          Text(suffix, style: cl.text.label.copyWith(color: cl.colors.ink)),
        ],
      ),
    );
  }
}

class _SideChip extends StatelessWidget {
  const _SideChip({
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.cl.colors;
    return ClPressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.mintSoft : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.pill),
          border: Border.all(
            color: selected ? c.mintDeep : c.controlBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: context.cl.text.label.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? c.mintText : c.ink,
          ),
        ),
      ),
    );
  }
}
