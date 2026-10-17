import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reference/reference_repository.dart';
import 'vaccine_models.dart';
import 'vaccine_schedule.g.dart';

/// The vaccine schedule in use (P-138, Figma C03): an approved `vaccines.schedule` version
/// published to `publicConfig/reference_vaccines`, else the bundled schedule (version 1). Dose
/// records are keyed by vaccine id and dose number, so a new version moves only open doses.
@immutable
class VaccineScheduleTable {
  const VaccineScheduleTable({
    required this.version,
    required this.publishedAt,
    required this.defs,
  });

  final String version;
  final String publishedAt;
  final List<VaccineDef> defs;

  static const docId = 'reference_vaccines';
  static const dataset = 'vaccines.schedule';

  static const bundled = VaccineScheduleTable(
    version: 'v1',
    publishedAt: '',
    defs: vaccineSchedule,
  );

  static final _id = RegExp(r'^[a-z0-9]{2,12}$');

  static VxText? _text(Object? raw) {
    if (raw is! Map) return null;
    final vi = raw['vi'];
    final en = raw['en'];
    if (vi is! String || en is! String || vi.isEmpty || en.isEmpty) {
      return null;
    }
    return (vi: vi, en: en);
  }

  static int? _int(Object? v) {
    if (v is int) return v;
    if (v is double && v.isFinite && v == v.truncateToDouble()) {
      return v.toInt();
    }
    return null;
  }

  /// A row as published (`vaccineRowSchema` in contracts), or null when anything is off.
  static VaccineDef? parseRow(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = _text(raw['name']);
    final short = _text(raw['short']);
    final about = _text(raw['about']);
    if (id is! String || !_id.hasMatch(id)) return null;
    if (name == null || short == null || about == null) return null;
    final programme = VaccineProgramme.values
        .where((p) => p.name == raw['programme'])
        .firstOrNull;
    final route = VaccineRoute.values
        .where((r) => r.name == raw['route'])
        .firstOrNull;
    if (programme == null || route == null) return null;
    final monthsRaw = raw['months'];
    if (monthsRaw is! List || monthsRaw.isEmpty || monthsRaw.length > 9) {
      return null;
    }
    final months = <int>[];
    for (final m in monthsRaw) {
      final v = _int(m);
      if (v == null || v < 0 || v > 72) return null;
      if (months.isNotEmpty && v <= months.last) return null;
      months.add(v);
    }
    int? interval;
    if (raw['minIntervalWeeks'] != null) {
      interval = _int(raw['minIntervalWeeks']);
      if (interval == null || interval < 1 || interval > 104) return null;
    }
    bool? flag(String key) {
      final v = raw[key];
      return v == null ? false : (v is bool ? v : null);
    }

    final yearly = flag('yearly');
    final only5in1 = flag('only5in1');
    final dtpSeries = flag('dtpSeries');
    if (yearly == null || only5in1 == null || dtpSeries == null) return null;
    return VaccineDef(
      id: id,
      name: name,
      short: short,
      months: List.unmodifiable(months),
      programme: programme,
      route: route,
      about: about,
      minIntervalWeeks: interval,
      yearly: yearly,
      only5in1: only5in1,
      dtpSeries: dtpSeries,
    );
  }

  /// `publicConfig/reference_vaccines` (or its cached copy) when it is a valid schedule: all
  /// fields present, 1–40 valid rows, no id listed twice. Otherwise null.
  static VaccineScheduleTable? parse(Object? data) {
    if (data is! Map || data['dataset'] != dataset) return null;
    final version = data['version'];
    final publishedAt = data['publishedAt'];
    final rows = data['rows'];
    if (version is! String ||
        !RegExp(r'^v\d{4}\.\d{2}(?:\.\d+)?$').hasMatch(version)) {
      return null;
    }
    if (publishedAt is! String) return null;
    if (rows is! List || rows.isEmpty || rows.length > 40) return null;
    final defs = <VaccineDef>[];
    final ids = <String>{};
    for (final r in rows) {
      final def = parseRow(r);
      if (def == null || !ids.add(def.id)) return null;
      defs.add(def);
    }
    return VaccineScheduleTable(
      version: version,
      publishedAt: publishedAt,
      defs: List.unmodifiable(defs),
    );
  }

  static Map<String, Object?> rowJson(VaccineDef d) => {
    'id': d.id,
    'name': {'vi': d.name.vi, 'en': d.name.en},
    'short': {'vi': d.short.vi, 'en': d.short.en},
    'months': d.months,
    'programme': d.programme.name,
    'route': d.route.name,
    'about': {'vi': d.about.vi, 'en': d.about.en},
    if (d.minIntervalWeeks != null) 'minIntervalWeeks': d.minIntervalWeeks,
    if (d.yearly) 'yearly': true,
    if (d.only5in1) 'only5in1': true,
    if (d.dtpSeries) 'dtpSeries': true,
  };

  Map<String, Object?> toJson() => {
    'dataset': dataset,
    'version': version,
    'publishedAt': publishedAt,
    'rows': [for (final d in defs) rowJson(d)],
  };
}

/// The schedule in use: the last valid published copy on this device, else the bundled one;
/// [VaccineScheduleController.refresh] runs once at app start (`ChildLifeApp`).
final vaccineScheduleProvider =
    NotifierProvider<VaccineScheduleController, VaccineScheduleTable>(
      VaccineScheduleController.new,
    );

class VaccineScheduleController extends Notifier<VaccineScheduleTable> {
  @override
  VaccineScheduleTable build() =>
      ref
          .watch(referenceRepositoryProvider)
          .cached(VaccineScheduleTable.docId, VaccineScheduleTable.parse) ??
      VaccineScheduleTable.bundled;

  /// Reads `publicConfig/reference_vaccines`; keeps the current schedule when it cannot be read.
  Future<void> refresh() async {
    try {
      final table = await ref
          .read(referenceRepositoryProvider)
          .refresh<VaccineScheduleTable>(
            VaccineScheduleTable.docId,
            VaccineScheduleTable.parse,
            (t) => t.toJson(),
          );
      state = table ?? VaccineScheduleTable.bundled;
    } on Object {
      // Offline with nothing cached, or Firebase unavailable: keep what we have.
    }
  }
}
