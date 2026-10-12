import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:child_life/features/spending/import/import_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nhập chi tiêu (D-060, P-144): the phone turns files into a grid of text.
void main() {
  Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));

  group('CSV', () {
    test('comma, semicolon or tab; quotes; text stays text', () {
      expect(
        readGrid(
          'a.csv',
          bytes('Ngày,Số tiền,Nội dung\n12/10/2026,"1.020.000","Sữa, bỉm"\n'),
        ),
        [
          ['Ngày', 'Số tiền', 'Nội dung'],
          ['12/10/2026', '1.020.000', 'Sữa, bỉm'],
        ],
      );
      expect(
        readGrid(
          'a.csv',
          bytes('Date;Amount;Note\r\n2026-10-12;-285000;Tã\r\n'),
        ),
        [
          ['Date', 'Amount', 'Note'],
          ['2026-10-12', '-285000', 'Tã'],
        ],
      );
      expect(readGrid('a.tsv', bytes('A\tB\n0912\t1,5\n'))[1], ['0912', '1,5']);
    });

    test('UTF-8 with a BOM and UTF-16 (Excel "Unicode text")', () {
      final bom = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('Nội dung,Tiền\nSữa,1\n'),
      ]);
      expect(readGrid('a.csv', bom).first, ['Nội dung', 'Tiền']);
      final units = 'Ngày\tTiền\n12/10\t5\n'.codeUnits;
      final utf16 = Uint8List.fromList([
        0xFF,
        0xFE,
        for (final u in units) ...[u & 0xFF, u >> 8],
      ]);
      expect(readGrid('a.txt', utf16), [
        ['Ngày', 'Tiền'],
        ['12/10', '5'],
      ]);
    });

    test(
      'blank rows keep their place, trailing ones go; empty and .xls refused',
      () {
        expect(readGrid('a.csv', bytes('a,b\n,\n1,2\n,\n')), [
          ['a', 'b'],
          ['', ''],
          ['1', '2'],
        ]);
        expect(
          () => readGrid('a.csv', bytes(' \n')),
          throwsA(
            isA<ReadException>().having(
              (e) => e.failure,
              'f',
              ReadFailure.empty,
            ),
          ),
        );
        expect(
          () => readGrid('a.xls', bytes('x')),
          throwsA(
            isA<ReadException>().having(
              (e) => e.failure,
              'f',
              ReadFailure.oldExcel,
            ),
          ),
        );
        expect(
          () => readGrid('a.pdf', bytes('x')),
          throwsA(
            isA<ReadException>().having(
              (e) => e.failure,
              'f',
              ReadFailure.unsupported,
            ),
          ),
        );
      },
    );
  });

  group('xlsx', () {
    Uint8List workbook(Map<String, String> files) {
      final a = Archive();
      for (final e in files.entries) {
        final data = utf8.encode(e.value);
        a.addFile(ArchiveFile(e.key, data.length, data));
      }
      return Uint8List.fromList(ZipEncoder().encode(a));
    }

    test('shared strings, inline strings, numbers, gaps; the fullest sheet', () {
      final grid = readGrid(
        'chi-tieu.xlsx',
        workbook({
          'xl/sharedStrings.xml':
              '<sst><si><t>Ngày</t></si><si><t>Số tiền</t></si><si><r><t>Sữa </t></r><r><t>bột</t></r></si></sst>',
          'xl/worksheets/sheet1.xml':
              '<worksheet><sheetData><row r="1"><c r="A1" t="s"><v>0</v></c></row></sheetData></worksheet>',
          'xl/worksheets/sheet2.xml':
              '<worksheet><sheetData>'
              '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="D1" t="inlineStr"><is><t>Ghi chú</t></is></c></row>'
              '<row r="2"><c r="A2"><v>46307</v></c><c r="B2"><v>1020000.0000000002</v></c><c r="D2" t="s"><v>2</v></c></row>'
              '</sheetData></worksheet>',
        }),
      );
      expect(grid, [
        ['Ngày', 'Số tiền', '', 'Ghi chú'],
        ['46307', '1020000', '', 'Sữa bột'],
      ]);
    });

    test('a broken workbook is reported, not thrown raw', () {
      expect(
        () => readGrid('a.xlsx', Uint8List.fromList([1, 2, 3])),
        throwsA(
          isA<ReadException>().having(
            (e) => e.failure,
            'f',
            ReadFailure.broken,
          ),
        ),
      );
    });
  });
}
