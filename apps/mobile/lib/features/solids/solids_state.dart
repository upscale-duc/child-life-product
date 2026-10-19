import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../baby/baby_models.dart';
import '../home/home_shell.dart';
import '../nutrition/nutrition_calc.dart' show nuMonthsOld;
import '../nutrition/nutrition_state.dart';
import 'solids_calc.dart';
import 'solids_models.dart';
import 'solids_repository.dart';

/// Ăn dặm for the selected baby. The age comes from Dinh dưỡng's baby ([nuBabyProvider]):
/// caregivers read the date of birth Cùng nuôi keep on the vaccine plan (P-133), as Dinh dưỡng
/// does. Meals and the catalogue are listened to only while tracking is on.
typedef SdState = ({
  NuBaby baby,
  Membership me,

  /// Completed months, when the date of birth is known to this member.
  int? months,
  SdAgeState? age,
  SdSettings settings,

  /// The settings document has not arrived yet (first open offline, slow network).
  bool loading,
  List<SdMeal> meals,
  Map<String, SdFood> foods,
});

extension SdStateX on SdState {
  bool get tracking => settings.enabled;
}

final sdStateProvider = Provider<SdState?>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  final baby = ref.watch(nuBabyProvider);
  if (me == null || baby == null) return null;
  final reads = me.sdReads;
  final settingsAsync = reads
      ? ref.watch(sdSettingsProvider(baby.babyId))
      : const AsyncValue<SdSettings?>.data(null);
  final settings = settingsAsync.value ?? SdSettings.off;
  final on = reads && settings.enabled;
  final meals = on
      ? ref.watch(sdMealsProvider(baby.babyId)).value ?? const <SdMeal>[]
      : const <SdMeal>[];
  final foods = on
      ? {
          for (final f
              in ref.watch(sdFoodsProvider).value?.items ?? const <SdFood>[])
            f.id: f,
        }
      : const <String, SdFood>{};
  final dob = baby.dob;
  final months = dob == null ? null : nuMonthsOld(dob, baby.today);
  return (
    baby: baby,
    me: me,
    months: months,
    age: months == null ? null : sdAgeState(months),
    settings: settings,
    loading: reads && settingsAsync.isLoading && !settingsAsync.hasValue,
    meals: meals,
    foods: foods,
  );
});

/// The foods tried by the selected baby (5b, 5e, food detail).
final sdTriedProvider = Provider<List<SdTried>>((ref) {
  final s = ref.watch(sdStateProvider);
  if (s == null || !s.tracking) return const [];
  return sdTriedFoods(s.meals, s.foods);
});

/// Today in the baby's zone (5h, the Care tile, Dinh dưỡng 9b); null while tracking is off.
final sdTodayProvider = Provider<SdDaySummary?>((ref) {
  final s = ref.watch(sdStateProvider);
  if (s == null || !s.tracking || !s.me.sdReads) return null;
  return sdDaySummary(s.meals, s.baby.zone, s.baby.today);
});

/// The selected baby's "Công thức nhà mình" (D-086), newest first: members who read care see them
/// (Rules `canReadCare`), with or without tracking (5f works without it).
final sdFamilyListProvider = Provider<List<SdFamilyRecipe>>((ref) {
  final me = ref.watch(selectedMembershipProvider);
  if (me == null || !me.sdReads) return const [];
  return ref.watch(sdFamilyRecipesProvider(me.babyId)).value ??
      const <SdFamilyRecipe>[];
});
