import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:xml/xml.dart';

/// Nhập chi tiêu (D-060, P-144): the phone turns a CSV or `.xlsx` file into a grid of text; the
/// server reads the grid. Nothing here is logged.

/// Why a file could not be read.
enum ReadFailure { unsupported, oldExcel, empty, tooBig, broken }

class ReadException implements Exception {
  const ReadException(this.failure);
  final ReadFailure failure;
}

abstract final class GridLimits {
  static const fileBytesMax = 10 * 1024 * 1024;
  static const rowsMax = 5000;
  static const colsMax = 40;
  static const cellMax = 300;
}

/// Reads [bytes] by the file's extension. Rows are trimmed to [GridLimits]; empty rows dropped.
List<List<String>> readGrid(String fileName, Uint8List bytes) {
  if (bytes.length > GridLimits.fileBytesMax) {
    throw const ReadException(ReadFailure.tooBig);
  }
  final ext = fileName.toLowerCase().split('.').last;
  final List<List<String>> grid;
  try {
    grid = switch (ext) {
      'csv' || 'txt' || 'tsv' => readCsv(decodeText(bytes)),
      'xlsx' || 'xlsm' => readXlsx(bytes),
      'xls' => throw const ReadException(ReadFailure.oldExcel),
      _ => throw const ReadException(ReadFailure.unsupported),
    };
  } on ReadException {
    rethrow;
  } on Object {
    throw const ReadException(ReadFailure.broken);
  }
  final rows = [
    for (final r in grid)
      if (r.any((c) => c.trim().isNotEmpty))
        [
          for (final c in r.take(GridLimits.colsMax))
            c.length > GridLimits.cellMax
                ? c.substring(0, GridLimits.cellMax)
                : c.trim(),
        ],
  ];
  if (rows.isEmpty) throw const ReadException(ReadFailure.empty);
  if (rows.length > GridLimits.rowsMax + 10) {
    throw const ReadException(ReadFailure.tooBig);
  }
  return rows;
}

/// UTF-8 (with or without BOM) or UTF-16 with a BOM, as Excel and Numbers save CSV.
String decodeText(Uint8List b) {
  if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
    return _utf16(b.sublist(2), little: true);
  }
  if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
    return _utf16(b.sublist(2), little: false);
  }
  final start = b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF
      ? 3
      : 0;
  return utf8.decode(b.sublist(start), allowMalformed: true);
}

String _utf16(Uint8List b, {required bool little}) {
  final units = <int>[
    for (var i = 0; i + 1 < b.length; i += 2)
      little ? b[i] | (b[i + 1] << 8) : (b[i] << 8) | b[i + 1],
  ];
  return String.fromCharCodes(units);
}

/// The delimiter is the one of `,` `;` tab that splits the first lines most evenly. Cells stay
/// text (no number parsing: "0912…" or "1.020.000" keep their form).
List<List<String>> readCsv(String text) {
  final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final sample = normalized.split('\n').take(10).join('\n');
  List<List<dynamic>> parse(String s, String d) => const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(s, fieldDelimiter: d);
  var best = ',';
  var bestScore = -1;
  for (final d in const [',', ';', '\t']) {
    final widths = [
      for (final r in parse(sample, d))
        if (r.length > 1) r.length,
    ];
    if (widths.isEmpty) continue;
    final same = widths.where((w) => w == widths.first).length;
    final score = same * 100 + widths.first;
    if (score > bestScore) {
      bestScore = score;
      best = d;
    }
  }
  return [
    for (final r in parse(normalized, best)) [for (final c in r) '${c ?? ''}'],
  ];
}

// ---------- .xlsx ----------

/// The sheet with the most rows of an `.xlsx` workbook. Numbers stay as written in the cell (an
/// Excel day stays a serial number such as 46307; the server reads it as a day).
List<List<String>> readXlsx(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  String? text(String path) {
    final f = zip.findFile(path);
    if (f == null) return null;
    return utf8.decode(f.content, allowMalformed: true);
  }

  final shared = <String>[];
  final sst = text('xl/sharedStrings.xml');
  if (sst != null) {
    for (final si in XmlDocument.parse(sst).findAllElements('si')) {
      shared.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }
  final sheets = [
    for (final f in zip.files)
      if (f.isFile && RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name))
        f.name,
  ]..sort();
  if (sheets.isEmpty) throw const ReadException(ReadFailure.broken);
  List<List<String>>? best;
  for (final path in sheets) {
    final grid = _sheet(text(path)!, shared);
    if (best == null || grid.length > best.length) best = grid;
  }
  return best!;
}

List<List<String>> _sheet(String xml, List<String> shared) {
  final out = <List<String>>[];
  for (final row in XmlDocument.parse(xml).findAllElements('row')) {
    final cells = <int, String>{};
    var next = 0;
    for (final c in row.findElements('c')) {
      final ref = c.getAttribute('r');
      final col = ref == null ? next : _column(ref);
      next = col + 1;
      if (col >= GridLimits.colsMax) continue;
      final type = c.getAttribute('t');
      final v = c.getElement('v')?.innerText ?? '';
      cells[col] = switch (type) {
        's' =>
          (int.tryParse(v) ?? -1) >= 0 && int.parse(v) < shared.length
              ? shared[int.parse(v)]
              : '',
        'inlineStr' => c.findAllElements('t').map((t) => t.innerText).join(),
        'b' => v == '1' ? 'TRUE' : 'FALSE',
        _ => _number(v),
      };
    }
    if (cells.isEmpty) continue;
    final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
    out.add([for (var i = 0; i < width; i++) cells[i] ?? '']);
    if (out.length > GridLimits.rowsMax + 10) break;
  }
  return out;
}

/// "AB12" → 27.
int _column(String ref) {
  var n = 0;
  for (final ch in ref.codeUnits) {
    if (ch < 65 || ch > 90) break;
    n = n * 26 + (ch - 64);
  }
  return n - 1;
}

/// "1020000" stays; "1020000.0000000002" (floating noise) becomes "1020000".
String _number(String v) {
  final d = double.tryParse(v);
  if (d == null) return v;
  if ((d - d.roundToDouble()).abs() < 1e-6) return d.round().toString();
  return v;
}
