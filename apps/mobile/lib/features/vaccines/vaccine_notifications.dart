import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/route_guard.dart';
import '../../app/router.dart';
import '../home/home_shell.dart';

/// A vaccination reminder push (VX 8, P-133): `kind = vaccine` with the baby, the date and the
/// milestone's month of age.
typedef VaccinePush = ({String babyId, String date, int months});

VaccinePush? vaccinePushOf(Map<String, dynamic> data) {
  if (data['kind'] != 'vaccine') return null;
  final babyId = data['babyId'], date = data['date'];
  if (babyId is! String || date is! String) return null;
  return (
    babyId: babyId,
    date: date,
    months: int.tryParse('${data['months'] ?? ''}') ?? 0,
  );
}

/// "Xem lịch tiêm" → the book; a tap or "Dời lịch" → the milestone page (VX 2), where the
/// appointment date is set. On top of what is showing: Back returns there.
void openVaccinePush(WidgetRef ref, VaccinePush push, {String? action}) {
  if (ref.read(selectedBabyIdProvider) != push.babyId) {
    ref.read(selectedBabyIdProvider.notifier).select(push.babyId);
  }
  unawaited(
    ref
        .read(routerProvider)
        .push<Object?>(
          action == 'view'
              ? Routes.vaccines
              : '${Routes.vaccineAge}/${push.months}',
        ),
  );
}
