import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/session.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_choices.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_rows.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_avatar_view.dart';
import '../baby/baby_models.dart';
import '../baby/baby_repository.dart';
import '../onboarding/setup_screens.dart';
import 'me_repository.dart';
import 'me_screen.dart';
import 'me_widgets.dart';

typedef _Rel = ({Relation relation, String custom});

/// 13m "Hồ sơ của bạn": display name for every baby, "Bạn là ai với bé" per baby.
/// The photo is the initial for now (user photos are not stored in V1; noted in the S11 report).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _name;
  final _changed = <String, _Rel>{};
  var _busy = false;

  List<Membership> get _memberships {
    final s = ref.read(sessionProvider);
    return s is SessionSignedIn ? s.active : const [];
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: _memberships.firstOrNull?.displayName ?? '',
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _changed.isNotEmpty ||
      _name.text.trim() != (_memberships.firstOrNull?.displayName ?? '');

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final toaster = ClToaster.of(context);
    setState(() => _busy = true);
    try {
      await withClProgress(
        context,
        () => ref
            .read(meRepositoryProvider)
            .updateProfile(
              displayName: name != _memberships.firstOrNull?.displayName
                  ? name
                  : null,
              relations: [
                for (final e in _changed.entries)
                  (
                    babyId: e.key,
                    relation: e.value.relation,
                    custom: e.value.custom.trim(),
                  ),
              ],
            ),
      );
      _changed.clear();
      toaster.show(message: l10n.pfSaved);
    } on Object {
      toaster.show(message: l10n.profileSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final session = ref.watch(sessionProvider);
    final memberships = session is SessionSignedIn
        ? session.active
        : const <Membership>[];
    return MePage(
      title: l10n.pfTitle,
      trailing: MeRowAction(
        label: l10n.actionSave,
        onPressed: _busy || !_dirty || _name.text.trim().isEmpty ? null : _save,
      ),
      children: [
        Center(child: InitialAvatar(name: _name.text, size: 104)),
        const SizedBox(height: ClSpace.s4),
        ClTextField(
          label: l10n.pfName,
          controller: _name,
          standalone: true,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
        ),
        MeSection(l10n.pfWho),
        ClCardGroup(
          children: [
            for (final m in memberships)
              Builder(
                builder: (context) {
                  final baby = ref.watch(babyProvider(m.babyId)).value;
                  final rel =
                      _changed[m.babyId] ??
                      (relation: m.relation, custom: m.relationCustom ?? '');
                  return MeRow(
                    leading: baby == null
                        ? null
                        : SavedBabyAvatar(baby: baby, size: 36),
                    title: baby?.nickname ?? '',
                    value: relationLabel(l10n, rel.relation, rel.custom),
                    onTap: () async {
                      final picked = await _pickRelation(
                        context,
                        baby?.nickname ?? '',
                        rel,
                      );
                      if (picked != null) {
                        setState(() => _changed[m.babyId] = picked);
                      }
                    },
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        Text(
          l10n.pfFootnote,
          style: cl.text.label.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}

/// Relation chips as on 10a, "Khác…" with free text (not drawn for 13m).
Future<_Rel?> _pickRelation(BuildContext context, String name, _Rel current) {
  var relation = current.relation;
  final custom = TextEditingController(text: current.custom);
  return showClSheet<_Rel>(
    context: context,
    builder: (sheet) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        final valid =
            relation != Relation.other || custom.text.trim().isNotEmpty;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.pfRelationTitle(name)),
            Wrap(
              spacing: ClSpace.s2,
              runSpacing: ClSpace.s2,
              children: [
                for (final r in Relation.values)
                  ClRelationChip(
                    label: r == Relation.other
                        ? l10n.relationOther
                        : relationLabel(l10n, r),
                    selected: relation == r,
                    onTap: () => setState(() => relation = r),
                  ),
              ],
            ),
            if (relation == Relation.other) ...[
              const SizedBox(height: ClSpace.s3),
              ClTextField(
                label: l10n.whoCustomLabel,
                placeholder: l10n.whoCustomPlaceholder,
                controller: custom,
                standalone: true,
                maxLength: relationCustomMaxLength,
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: ClSpace.s4),
            ClButton(
              label: l10n.actionDone,
              expand: true,
              onPressed: valid
                  ? () => Navigator.of(
                      sheet,
                    ).pop((relation: relation, custom: custom.text))
                  : null,
            ),
          ],
        );
      },
    ),
  );
}
