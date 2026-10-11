import 'package:child_life/features/baby/baby_models.dart';
import 'package:child_life/features/care/care_models.dart';
import 'package:child_life/features/vaccines/vaccine_models.dart';

/// Sổ tiêm chủng fixtures (Figma VX, P-133): Teddy, born 17/9/2026.
VaccineDoseRecord vxRec(
  String vaccineId,
  int dose, {
  DoseRecordStatus status = DoseRecordStatus.given,
  DateTime? on,
  DateTime? plannedOn,
  String by = 'u_mai',
  String? reaction,
  String? photo,
}) => VaccineDoseRecord(
  key: doseKeyOf(vaccineId, dose),
  vaccineId: vaccineId,
  dose: dose,
  status: status,
  givenOn: on,
  plannedOn: plannedOn,
  place: status == DoseRecordStatus.given ? VaccinePlace.service : null,
  reaction: reaction,
  photoPath: photo,
  createdBy: by,
  author: CareAuthor(
    name: by == 'u_mai' ? 'Mai' : 'Minh',
    relation: by == 'u_mai' ? Relation.mother : Relation.father,
  ),
);

Map<String, VaccineDoseRecord> vxBirthDoses() => {
  for (final r in [
    vxRec('vitk', 1, on: DateTime(2026, 9, 17)),
    vxRec('bcg', 1, on: DateTime(2026, 9, 18)),
    vxRec('hepb', 1, on: DateTime(2026, 9, 17)),
  ])
    r.key: r,
};

const vxSetUp = VaccinePlan(setupDone: true, exists: true);
