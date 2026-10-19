import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart' show SafePush;
import '../../app/route_guard.dart';
import '../../core/design/cl_theme.dart';
import '../../core/design/haptics.dart';
import '../../core/design/tokens.g.dart';
import '../../core/widgets/cl_button.dart';
import '../../core/widgets/cl_feedback.dart';
import '../../core/widgets/cl_icon.dart';
import '../../core/widgets/cl_inputs.dart';
import '../../core/widgets/cl_pressable.dart';
import '../../core/widgets/cl_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../baby/baby_models.dart' show Relation;
import '../care/care_models.dart' show CareAuthor;
import '../care/care_repository.dart' show timerClockProvider;
import '../care/care_sheets.dart' show CareSheetFrame;
import '../family/emergency_numbers.dart';
import '../first_aid/first_aid_modes.dart' show callEmergency;
import '../first_aid/first_aid_repository.dart' show firstAidPackProvider;
import '../first_aid/first_aid_widgets.dart' show FaCallButton;
import '../premium/premium_repository.dart' show selectedFamilyCountryProvider;
import '../vaccines/vaccine_photos.dart'
    show VaccinePhotoStore, vaccinePhotoStoreProvider;
import 'solids_calc.dart';
import 'solids_family.dart' show sdFamilyMealFill;
import 'solids_family_screens.dart' show SdFamilyChips;
import 'solids_format.dart';
import 'solids_models.dart';
import 'solids_photos.dart';
import 'solids_repository.dart';
import 'solids_state.dart';
import 'solids_widgets.dart';

/// 5c Ghi bữa ăn (Figma `313:1872`; plan §5, P-164 #5–#7): a sheet from 5b, the quick log, the
/// Today card, 5g "Ghi vào nhật ký" and a suggestion ([SdMealPrefill]). A new meal starts with
/// the "Món nhà mình" chips (D-086): a recent family recipe fills it and keeps its id.
///
/// Saved like a care record: straight to the local cache (synced later when offline), with
/// "Hoàn tác". The urgent symptoms show the "Gọi 115" card before saving (P-164 #6).

/// What 5g or a suggestion puts in a new meal (phase C / D).
@immutable
class SdMealPrefill {
  const SdMealPrefill({
    this.dish = '',
    this.foodIds = const [],
    this.freeFoods = const [],
    this.recipeId,
  });
  final String dish;
  final List<String> foodIds;
  final List<String> freeFoods;
  final String? recipeId;
}

/// Opens 5c: a new meal (now, or at this time of day on [day]), or "Sửa" of [edit].
Future<void> openMealSheet(
  BuildContext context, {
  SdMeal? edit,
  DateTime? day,
  SdMealPrefill? prefill,
}) => showClSheet<void>(
  context: context,
  builder: (_) => MealSheet(edit: edit, day: day, prefill: prefill),
);

/// The Sơ cứu situation for "Sơ cứu: Sốc phản vệ" (TH05, `content/first-aid/pack.seed.json`).
const sdAnaphylaxisSituation = 'anaphylaxis';

class MealSheet extends ConsumerStatefulWidget {
  const MealSheet({this.edit, this.day, this.prefill, super.key});
  final SdMeal? edit;
  final DateTime? day;
  final SdMealPrefill? prefill;

  @override
  ConsumerState<MealSheet> createState() => _MealSheetState();
}

class _MealSheetState extends ConsumerState<MealSheet> {
  late final String _id = widget.edit?.id ?? newMealId();
  late DateTime _date;
  late TimeOfDay _time;
  late SdSlot _slot;
  bool _slotTouched = false;
  late final _dish = TextEditingController(
    text: widget.edit?.dish ?? widget.prefill?.dish ?? '',
  );
  late final _note = TextEditingController(text: widget.edit?.note ?? '');
  late final _value = TextEditingController(
    text: switch (widget.edit?.amount?.value) {
      final v? => v == v.roundToDouble() ? '${v.round()}' : '$v',
      null => '',
    },
  );
  late List<String> _foodIds = [
    ...?(widget.edit?.foodIds ?? widget.prefill?.foodIds),
  ];
  late List<String> _free = [
    ...?(widget.edit?.freeFoods ?? widget.prefill?.freeFoods),
  ];
  late SdAmountPreset? _preset = widget.edit?.amount?.preset;
  late bool _custom = widget.edit?.amount?.value != null;
  late SdUnit _unit = widget.edit?.amount?.unit ?? SdUnit.spoon;
  late SdReaction? _reaction = widget.edit?.reaction;

  /// The recipe it was cooked from (5g, a family recipe page, a "Món nhà mình" chip).
  late String? _recipeId = widget.edit?.recipeId ?? widget.prefill?.recipeId;
  late final Set<SdSymptom> _symptoms = {...?widget.edit?.symptoms};
  late String? _photoPath = widget.edit?.photoPath;

  /// Photos uploaded while this sheet is open: the ones not kept are deleted (Cùng nuôi).
  final _uploaded = <String>{};

  /// "Lưu bữa" waits for an upload in progress (the book-photo pattern).
  bool _uploading = false;
  bool _saved = false;

  /// Read while mounted, for [dispose].
  late final VaccinePhotoStore _photos;
  bool _manages = false;
  String? _error;

  /// "Now" from care's clock (tests pin it).
  DateTime _now() => ref.read(timerClockProvider)();

  @override
  void initState() {
    super.initState();
    _photos = ref.read(vaccinePhotoStoreProvider);
    final now = _now();
    final edit = widget.edit;
    final at = edit?.occurredAt.toLocal() ?? now;
    final day = widget.day;
    _date = DateTime((day ?? at).year, (day ?? at).month, (day ?? at).day);
    _time = TimeOfDay(hour: at.hour, minute: at.minute);
    _slot = edit?.slot ?? sdSlotForTime(at.hour);
  }

  @override
  void dispose() {
    // Closed without saving: a photo uploaded here belongs to no meal.
    if (!_saved) sdDropPhotos(_photos, _uploaded, manages: _manages);
    _dish.dispose();
    _note.dispose();
    _value.dispose();
    super.dispose();
  }

  DateTime get _occurredAt {
    final at = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final now = _now();
    // Never in the future (Rules allow 5 minutes of skew).
    return at.isAfter(now) ? now : at;
  }

  /// Up to 7 days back, never before the 6-month day (the app's gate; Rules do not check it).
  List<DateTime> _days(SdState? s) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final dob = s?.baby.dob;
    final six = dob == null ? null : sdSixMonthDay(dob);
    final days = [
      for (var i = 0; i <= SdLimits.backDays; i++)
        if (DateTime(today.year, today.month, today.day - i) case final d
            when six == null || !d.isBefore(six))
          d,
    ];
    if (!days.contains(_date)) days.add(_date);
    return days;
  }

  Future<void> _pickDate(SdState? s) async {
    final l10n = AppLocalizations.of(context);
    final tag = Localizations.localeOf(context).toLanguageTag();
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showClSheet<DateTime>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.sdDate),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final d in _days(s))
                      ClPressable(
                        key: Key('sdDate_${d.year}-${d.month}-${d.day}'),
                        onPressed: () => Navigator.of(sheet).pop(d),
                        selected: d == _date,
                        semanticLabel: sdDayLabel(l10n, tag, d, today),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  sdDayLabel(l10n, tag, d, today),
                                  style: cl.text.body,
                                ),
                              ),
                              if (d == _date)
                                ClIcon(
                                  ClIcons.check,
                                  size: 18,
                                  color: cl.colors.mintText,
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final l10n = AppLocalizations.of(context);
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final max = _date == today ? now : null;
    var picked = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (max != null && picked.isAfter(max)) picked = max;
    final next = await showClSheet<DateTime>(
      context: context,
      builder: (sheet) {
        final cl = sheet.cl;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClSheetHeader(title: l10n.sdTime),
            SizedBox(
              height: 200,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: cl.isNightCare
                      ? Brightness.dark
                      : Brightness.light,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: cl.text.title2.copyWith(
                      color: cl.colors.ink,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: picked,
                  maximumDate: max,
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
        );
      },
    );
    if (next == null || !mounted) return;
    setState(() {
      _time = TimeOfDay(hour: next.hour, minute: next.minute);
      if (!_slotTouched && widget.edit == null) {
        _slot = sdSlotForTime(next.hour);
      }
    });
  }

  /// "Món nhà mình" (D-086): the recipe's dish and ingredients, and its id; tapped again, the
  /// meal no longer points at it.
  void _pickFamily(SdFamilyRecipe r) => setState(() {
    if (_recipeId == r.id) {
      _recipeId = null;
      return;
    }
    final fill = sdFamilyMealFill(r);
    _dish.text = fill.dish;
    _foodIds = [...fill.foodIds];
    _free = [...fill.freeFoods];
    _recipeId = r.id;
    _error = null;
  });

  Future<void> _pickFoods(SdState? s) async {
    final picked = await sdPickFoods(context, ids: _foodIds, free: _free);
    if (picked != null && mounted) {
      setState(() {
        _foodIds = picked.ids;
        _free = picked.free;
        _error = null;
      });
    }
  }

  SdAmount? _amount() {
    if (_preset != null) return SdAmount.preset(_preset!);
    if (!_custom) return null;
    final v = num.tryParse(_value.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0 || v > SdLimits.amountMax) return null;
    return SdAmount.custom(v, _unit);
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final s = ref.read(sdStateProvider);
    if (s == null || !s.me.sdLogs) return;
    final dish = _dish.text.trim();
    if (dish.isEmpty && _foodIds.isEmpty && _free.isEmpty) {
      setState(() => _error = l10n.sdNeedDish);
      return;
    }
    final amount = _amount();
    if (_custom && amount == null) {
      setState(() => _error = l10n.sdAmountInvalid);
      return;
    }
    final repo = ref.read(solidsStoreProvider);
    final toaster = ClToaster.of(context);
    final locale = Localizations.localeOf(context);
    void failed(Object _) =>
        toaster.show(message: l10n.careSaveFailed, error: true);
    final edit = widget.edit;
    final symptoms = [
      for (final x in SdSymptom.values)
        if (_symptoms.contains(x)) x,
    ];
    final meal = edit != null
        ? edit.edited(
            occurredAt: _occurredAt,
            slot: _slot,
            dish: dish,
            foodIds: _foodIds,
            freeFoods: _free,
            amount: amount,
            reaction: _reaction,
            symptoms: symptoms,
            note: _note.text.trim(),
            photoPath: _photoPath,
          )
        : SdMeal.create(
            id: _id,
            me: s.me,
            occurredAt: _occurredAt,
            slot: _slot,
            dish: dish,
            foodIds: _foodIds,
            freeFoods: _free,
            amount: amount,
            reaction: _reaction,
            symptoms: symptoms,
            note: _note.text.trim(),
            recipeId: _recipeId,
            photoPath: _photoPath,
          );
    if (edit != null) {
      repo.edit(meal, s.me.uid, onError: failed);
    } else {
      repo.create(meal, onError: failed);
    }
    // D-085 #2: a Cùng nuôi who replaced or removed the photo deletes the old object, and any
    // photo uploaded here and dropped; a caregiver only clears `photoPath` (Storage Rules).
    _saved = true;
    sdDropPhotos(
      _photos,
      [..._uploaded, edit?.photoPath].where((p) => p != _photoPath),
      manages: s.me.sdManages,
    );
    ClHaptics.success();
    Navigator.of(context).maybePop();
    if (edit != null) {
      toaster.show(message: l10n.editedToast);
    } else {
      toaster.show(
        message: l10n.sdSavedToast(sdMealTitle(meal, s.foods, locale)),
        actionLabel: l10n.undo,
        onAction: () => repo.softDelete(meal, s.me.uid, onError: failed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final tag = locale.toLanguageTag();
    final s = ref.watch(sdStateProvider);
    final foods = s?.foods ?? const <String, SdFood>{};
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    // ✦ marked live: catalogue foods no earlier meal has.
    final draft = SdMeal(
      id: _id,
      babyId: s?.baby.babyId ?? '',
      occurredAt: _occurredAt,
      slot: _slot,
      foodIds: _foodIds,
      createdBy: s?.me.uid ?? '',
      author:
          widget.edit?.author ??
          const CareAuthor(name: '', relation: Relation.other),
      clientCreatedAt: widget.edit?.clientCreatedAt ?? now,
      createdAt: widget.edit?.createdAt,
    );
    final firsts = sdFirstTryIds(draft, s?.meals ?? const []);
    final urgent = _symptoms.any((x) => x.urgent);
    _manages = s?.me.sdManages ?? false;

    return CareSheetFrame(
      title: widget.edit == null ? l10n.sdSheetTitle : l10n.sdSheetEditTitle,
      titleColor: cl.care.bottle.ink,
      primary: ClButton(
        key: const Key('sdSaveMeal'),
        label: l10n.sdSave,
        expand: true,
        onPressed: _uploading ? null : _save,
      ),
      children: [
        // D-086: recent family recipes, one tap (new meals not started from a recipe).
        if (widget.edit == null && widget.prefill?.recipeId == null)
          SdFamilyChips(selected: _recipeId, onPick: _pickFamily),
        SdSlotPicker(
          selected: _slot,
          onChanged: (x) => setState(() {
            _slot = x;
            _slotTouched = true;
          }),
        ),
        Row(
          children: [
            Expanded(
              child: _FieldBox(
                key: const Key('sdTimeField'),
                label: l10n.sdTime,
                icon: ClIcons.clock,
                value: sdTime(tag, _occurredAt),
                onTap: () => unawaited(_pickTime()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FieldBox(
                key: const Key('sdDateField'),
                label: l10n.sdDate,
                icon: ClIcons.cake,
                value: sdDayLabel(l10n, tag, _date, today),
                onTap: () => unawaited(_pickDate(s)),
              ),
            ),
          ],
        ),
        SdLabel(l10n.sdDish),
        ClTextField(
          key: const Key('sdDish'),
          controller: _dish,
          placeholder: l10n.sdDishHint,
          maxLength: SdLimits.mealDish,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() => _error = null),
        ),
        SdLabel(l10n.sdIngredients),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final id in _foodIds)
              SdFoodChip(
                firsts.contains(id)
                    ? l10n.sdFirstTryChip(sdFoodName(id, foods, locale))
                    : sdFoodName(id, foods, locale),
                key: Key('sdIngredient_$id'),
                look: firsts.contains(id)
                    ? SdChipLook.firstTry
                    : SdChipLook.plain,
                semanticLabel: l10n.sdRemoveFood(sdFoodName(id, foods, locale)),
                onRemove: () => setState(() => _foodIds.remove(id)),
              ),
            for (final f in _free)
              SdFoodChip(
                f,
                key: Key('sdIngredient_${sdFreeKey(f)}'),
                semanticLabel: l10n.sdRemoveFood(f),
                onRemove: () => setState(() => _free.remove(f)),
              ),
            _AddChip(onTap: () => unawaited(_pickFoods(s))),
          ],
        ),
        SdLabel(l10n.sdAmount),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in SdAmountPreset.values)
              SdPill(
                sdPresetLabel(l10n, p),
                key: Key('sdAmount_${p.name}'),
                selected: _preset == p,
                onTap: () => setState(() {
                  _preset = _preset == p ? null : p;
                  _custom = false;
                  _error = null;
                }),
              ),
            SdPill(
              l10n.sdAmountCustom,
              key: const Key('sdAmount_custom'),
              selected: _custom,
              onTap: () => setState(() {
                _custom = !_custom;
                _preset = null;
                _error = null;
              }),
            ),
          ],
        ),
        if (_custom) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: ClTextField(
                  key: const Key('sdAmountValue'),
                  controller: _value,
                  placeholder: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() => _error = null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final u in SdUnit.values)
                      SdPill(
                        sdUnitLabel(l10n, u),
                        key: Key('sdUnit_${u.name}'),
                        selected: _unit == u,
                        soft: true,
                        onTap: () => setState(() => _unit = u),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
        SdLabel(l10n.sdReaction),
        Row(
          children: [
            for (final (i, r) in SdReaction.values.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SdPill(
                  sdReactionLabel(l10n, r),
                  key: Key('sdReaction_${r.name}'),
                  selected: _reaction == r,
                  soft: true,
                  expand: true,
                  onTap: () =>
                      setState(() => _reaction = _reaction == r ? null : r),
                ),
              ),
            ],
          ],
        ),
        SdLabel(l10n.sdSymptomsQuestion),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final x in SdSymptom.values)
              SdPill(
                sdSymptomLabel(l10n, x),
                key: Key('sdSymptom_${x.name}'),
                selected: _symptoms.contains(x),
                danger: x.urgent,
                soft: !x.urgent,
                onTap: () => setState(
                  () => _symptoms.contains(x)
                      ? _symptoms.remove(x)
                      : _symptoms.add(x),
                ),
              ),
          ],
        ),
        if (urgent) ...[
          const SizedBox(height: 12),
          const _UrgentCard(),
        ] else if (_symptoms.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.sdSymptomsNote,
            key: const Key('sdSymptomsNote'),
            style: cl.text.label.copyWith(
              fontSize: 13,
              height: 1.45,
              color: cl.colors.inkMuted,
            ),
          ),
        ],
        SdLabel(l10n.sdNote),
        ClTextField(
          key: const Key('sdNote'),
          controller: _note,
          placeholder: l10n.sdNoteHint,
          maxLength: SdLimits.mealNote,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        // Meal photo (D-085 #2): one per meal, camera or library.
        if (s != null) ...[
          SdLabel(l10n.sdPhoto),
          SdPhotoField(
            babyId: s.baby.babyId,
            path: _photoPath,
            busy: _uploading,
            onBusy: (busy) {
              if (mounted) setState(() => _uploading = busy);
            },
            onChanged: (p) {
              if (!mounted) {
                // Uploaded after the sheet closed: nobody keeps it.
                sdDropPhotos(_photos, [p], manages: _manages);
                return;
              }
              setState(() {
                if (p != null) _uploaded.add(p);
                _photoPath = p;
              });
            },
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: ClSpace.s3),
            child: Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                key: const Key('sdSheetError'),
                style: cl.text.label.copyWith(color: cl.colors.error),
              ),
            ),
          ),
      ],
    );
  }
}

/// 5c "Giờ" / "Ngày" box: white, control border, icon + value, label above.
class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    super.key,
  });
  final String label;
  final ClIcons icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SdLabel(label),
        ClPressable(
          onPressed: onTap,
          semanticLabel: '$label, $value',
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cl.colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cl.colors.controlBorder),
            ),
            child: Row(
              children: [
                ClIcon(icon, size: 16, color: cl.colors.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cl.text.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
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

/// 5c "+ Thêm" chip.
class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    return ClPressable(
      key: const Key('sdAddFood'),
      onPressed: onTap,
      semanticLabel: l10n.sdAddFood,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          border: Border.all(color: cl.colors.controlBorder),
          borderRadius: BorderRadius.circular(ClRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClIcon(ClIcons.plus, size: 12, color: cl.colors.ink),
            const SizedBox(width: 5),
            Text(
              l10n.sdAddFood,
              style: cl.text.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cl.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// P-164 #6: "Gọi 115 ngay nếu bé khó thở, sưng môi hoặc lưỡi, lả đi", with the call and the
/// Sơ cứu anaphylaxis page, shown at once when an urgent symptom is chosen (before saving).
class _UrgentCard extends ConsumerWidget {
  const _UrgentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cl = context.cl;
    final l10n = AppLocalizations.of(context);
    final pack = ref.watch(firstAidPackProvider).value;
    final number =
        pack?.emergencyNumber ??
        emergencyNumbers[ref.watch(selectedFamilyCountryProvider)] ??
        '115';
    final guide = pack?.situation(sdAnaphylaxisSituation) != null;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('sdUrgentCard'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cl.colors.errorSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cl.colors.error),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClIcon(
                    ClIcons.alert,
                    size: 18,
                    color: cl.colors.error,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.sdUrgent(number),
                    style: cl.text.bodyStrong.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: cl.colors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FaCallButton(
              number: number,
              expand: true,
              onPressed: () {
                unawaited(HapticFeedback.heavyImpact());
                unawaited(callEmergency(context, ref));
              },
            ),
            if (guide) ...[
              const SizedBox(height: 4),
              ClButton(
                key: const Key('sdAnaphylaxis'),
                label: l10n.sdAnaphylaxis,
                style: ClButtonStyle.plain,
                onPressed: () {
                  // The guide matters more than the draft: close the sheet, open Sơ cứu (TH05).
                  final router = GoRouter.of(context);
                  Navigator.of(context).maybePop();
                  unawaited(
                    router.pushSafe(
                      '${Routes.firstAidSituation}/$sdAnaphylaxisSituation',
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The ingredient picker ([_FoodPicker]): the chosen catalogue ids and free names, or null when
/// dismissed. A meal takes up to 12 foods and 3 free names; a family recipe (D-086) passes its own
/// limits ([maxTotal] together).
Future<({List<String> ids, List<String> free})?> sdPickFoods(
  BuildContext context, {
  required List<String> ids,
  required List<String> free,
  int maxIds = SdLimits.mealFoods,
  int maxFree = SdLimits.mealFree,
  int? maxTotal,
}) => showClSheet<({List<String> ids, List<String> free})>(
  context: context,
  builder: (_) => _FoodPicker(
    ids: ids,
    free: free,
    maxIds: maxIds,
    maxFree: maxFree,
    maxTotal: maxTotal,
  ),
);

/// 5c ingredient picker: the published catalogue (names and synonyms, liked and recent first, the
/// group shown) and up to 3 free names ("Thêm tên khác", group "Khác").
class _FoodPicker extends ConsumerStatefulWidget {
  const _FoodPicker({
    required this.ids,
    required this.free,
    this.maxIds = SdLimits.mealFoods,
    this.maxFree = SdLimits.mealFree,
    this.maxTotal,
  });
  final List<String> ids;
  final List<String> free;
  final int maxIds;
  final int maxFree;
  final int? maxTotal;

  @override
  ConsumerState<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends ConsumerState<_FoodPicker> {
  late final List<String> _ids = [...widget.ids];
  late final List<String> _free = [...widget.free];
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool get _full =>
      widget.maxTotal != null && _ids.length + _free.length >= widget.maxTotal!;

  void _addFree(String name) {
    final n = name.trim();
    if (n.isEmpty || _free.length >= widget.maxFree || _full) return;
    final key = sdFreeKey(n);
    if (_free.any((f) => sdFreeKey(f) == key)) return;
    setState(() {
      _free.add(
        n.length > SdLimits.freeName ? n.substring(0, SdLimits.freeName) : n,
      );
      _query.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cl = context.cl;
    final locale = Localizations.localeOf(context);
    final s = ref.watch(sdStateProvider);
    final foods = s?.foods.values ?? const <SdFood>[];
    final tried = {for (final t in ref.watch(sdTriedProvider)) t.key: t};
    final q = _query.text.trim();
    final hits = sdSearchFoods(
      foods,
      q,
      tried: tried,
      locale: locale,
    ).take(60).toList();
    final exact = hits.any(
      (f) => f.searchNames.any((n) => sdFreeKey(n) == sdFreeKey(q)),
    );
    final canFree =
        q.isNotEmpty && !exact && _free.length < widget.maxFree && !_full;
    final months = s?.months;

    String sub(SdFood f) {
      final t = tried[f.id];
      return [
        sdGroupLabel(l10n, f.group),
        if (t == null)
          l10n.sdNotTried
        else if (t.latestReaction != null)
          l10n.sdTriedReaction(sdReactionLabel(l10n, t.latestReaction!))
        else
          l10n.sdTried,
        if (months != null && f.minAgeMonths > months)
          l10n.sdFromMonths(f.minAgeMonths),
      ].join(' · ');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSheetHeader(title: l10n.sdIngredients),
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
                  key: const Key('sdFoodQuery'),
                  controller: _query,
                  textInputAction: TextInputAction.done,
                  onSubmitted: canFree ? _addFree : null,
                  style: cl.text.body.copyWith(fontSize: 15),
                  decoration: InputDecoration.collapsed(
                    hintText: l10n.sdFoodSearch,
                    hintStyle: cl.text.body.copyWith(
                      fontSize: 15,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_free.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in _free)
                SdFoodChip(
                  f,
                  semanticLabel: l10n.sdRemoveFood(f),
                  onRemove: () => setState(() => _free.remove(f)),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (canFree)
                ClPressable(
                  key: const Key('sdAddFree'),
                  onPressed: () => _addFree(q),
                  semanticLabel: l10n.sdAddFree(q),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        ClIcon(
                          ClIcons.plus,
                          size: 18,
                          color: cl.colors.mintText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.sdAddFree(q),
                            style: cl.text.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cl.colors.mintText,
                            ),
                          ),
                        ),
                        Text(
                          l10n.sdGroupOther,
                          style: cl.text.caption.copyWith(
                            color: cl.colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (foods.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    widget.maxFree == SdLimits.mealFree
                        ? l10n.sdNoCatalogue
                        : l10n.sdNoCatalogueFree,
                    key: const Key('sdNoCatalogue'),
                    style: cl.text.label.copyWith(
                      height: 1.45,
                      color: cl.colors.inkMuted,
                    ),
                  ),
                ),
              for (final f in hits)
                ClPressable(
                  key: Key('sdFood_${f.id}'),
                  selected: _ids.contains(f.id),
                  semanticLabel: f.name.pick(locale),
                  onPressed: () => setState(() {
                    if (_ids.contains(f.id)) {
                      _ids.remove(f.id);
                    } else if (_ids.length < widget.maxIds && !_full) {
                      _ids.add(f.id);
                    }
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f.name.pick(locale),
                                style: cl.text.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                sub(f),
                                style: cl.text.caption.copyWith(
                                  color: cl.colors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClIcon(
                          _ids.contains(f.id) ? ClIcons.check : ClIcons.plus,
                          size: 18,
                          color: _ids.contains(f.id)
                              ? cl.colors.mintText
                              : cl.colors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: ClSpace.s3),
        ClButton(
          key: const Key('sdFoodsDone'),
          label: l10n.actionDone,
          expand: true,
          onPressed: () => Navigator.of(context).pop((ids: _ids, free: _free)),
        ),
      ],
    );
  }
}
