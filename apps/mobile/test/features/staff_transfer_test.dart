import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/features/me/account_screen.dart';
import 'package:child_life/features/me/me_models.dart';
import 'package:child_life/features/me/me_screen.dart';
import 'package:child_life/features/me/staff_transfer.dart';
import 'package:child_life/features/memories/media_bytes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/family_fixtures.dart';
import '../helpers/me_fixtures.dart';
import '../helpers/memory_fixtures.dart';
import '../helpers/router_pump.dart';

/// A17 / G-091 (P-136): the owner answers a transfer opened by Child Life Hỗ trợ.

const _id = 'ft_0123456789abcdef0123';

/// `pumpRouted` sets the minute clock to 8 Oct 2026, 10:00; the request ends 48 h after 9:00.
final _expires = DateTime(2026, 10, 10, 9);

StaffTransferRequest _request({
  String? ticket = 'CL-1042',
  DateTime? expires,
}) => StaffTransferRequest(
  transferId: _id,
  toMasked: 'm***@gmail.com',
  ticket: ticket,
  at: DateTime(2026, 10, 8, 9),
  expiresAt: expires ?? _expires,
);

class _Repo extends FakeMeRepository {
  _Repo({this.reason});

  /// Server error reason to throw instead of answering.
  final String? reason;
  final answers = <(String, bool)>[];

  @override
  Future<String> answerStaffTransfer(
    String transferId, {
    required bool accept,
  }) async {
    answers.add((transferId, accept));
    if (reason != null) throw AccountActionException(reason!);
    return accept ? 'confirmed' : 'declined';
  }
}

List<Override> _overrides({required AccountDoc account, _Repo? repo}) => [
  ...familyOverrides(
    email: 'mai@gmail.com',
    providers: const ['password'],
    account: account,
  ),
  ...memoryOverrides(),
  ...meOverrides(repo: repo),
];

String _deadline(String locale) =>
    DateFormat.MMMd(locale).add_Hm().format(_expires);

void main() {
  setUpAll(ensureTimeZones);
  setUp(() => mediaBytes = FakeMediaBytes());

  group('model', () {
    test(
      'reads users/{uid}.pendingStaffTransfer, ignores anything malformed',
      () {
        final at = Timestamp.fromDate(DateTime(2026, 10, 8, 9));
        final expires = Timestamp.fromDate(_expires);
        final doc = AccountDoc.fromMap({
          'pendingStaffTransfer': {
            'transferId': _id,
            'toMasked': 'm***@gmail.com',
            'ticket': null,
            'at': at,
            'expiresAt': expires,
          },
        });
        final r = doc.staffTransfer!;
        expect(r.transferId, _id);
        expect(r.ticket, isNull);
        expect(r.expiresAt, _expires);
        expect(r.isOpenAt(DateTime(2026, 10, 10, 8, 59)), isTrue);
        expect(r.isOpenAt(_expires), isFalse);

        for (final bad in [
          {
            'transferId': 'ft_x',
            'toMasked': 'm***@gmail.com',
            'expiresAt': expires,
          },
          {'transferId': _id, 'expiresAt': expires},
          {'transferId': _id, 'toMasked': 'm***@gmail.com'},
          {
            'transferId': _id,
            'toMasked': 'm***@gmail.com',
            'expiresAt': '2026',
          },
        ]) {
          expect(
            AccountDoc.fromMap({'pendingStaffTransfer': bad}).staffTransfer,
            isNull,
          );
        }
        expect(AccountDoc.fromMap(null).staffTransfer, isNull);
      },
    );
  });

  group('Tài khoản & đăng nhập › Chủ hồ sơ', () {
    testWidgets('agreeing asks first, then answers and hides the card', (
      tester,
    ) async {
      final repo = _Repo();
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(
          account: AccountDoc(staffTransfer: _request()),
          repo: repo,
        ),
      );
      final title = find.text(
        'Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ',
      );
      await tester.scrollUntilVisible(title, 200);
      expect(title, findsOneWidget);
      expect(
        find.text(
          'Cho m***@gmail.com · mã CL-1042. Bạn đồng ý trong 48 giờ '
          '(đến ${_deadline('vi')}); nếu không, đề nghị tự huỷ. Đồng ý thì '
          'm***@gmail.com sẽ nhận lời mời làm chủ hồ sơ như bình thường.',
        ),
        findsOneWidget,
      );
      // Title and body are read together; each button is its own control.
      final semantics = tester.ensureSemantics();
      final label = tester.getSemantics(title).label;
      expect(label, startsWith('Hỗ trợ Child Life đề nghị'));
      expect(label, contains('mã CL-1042'));
      expect(find.bySemanticsLabel('Đồng ý'), findsOneWidget);
      expect(find.bySemanticsLabel('Không đồng ý'), findsOneWidget);
      semantics.dispose();

      await tester.ensureVisible(find.text('Đồng ý'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();
      expect(find.text('Đồng ý chuyển quyền chủ hồ sơ?'), findsOneWidget);
      expect(repo.answers, isEmpty, reason: 'nothing sent before confirming');
      await tester.tap(find.text('Đồng ý').last);
      await tester.pumpAndSettle();

      expect(repo.answers, [(_id, true)]);
      expect(
        find.text('Đã đồng ý · m***@gmail.com sẽ nhận lời mời'),
        findsOneWidget,
      );
      expect(title, findsNothing);
    });

    testWidgets('cancelling the sheet sends nothing', (tester) async {
      final repo = _Repo();
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(
          account: AccountDoc(staffTransfer: _request()),
          repo: repo,
        ),
      );
      await tester.scrollUntilVisible(find.text('Đồng ý'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đồng ý'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Huỷ'));
      await tester.pumpAndSettle();
      expect(repo.answers, isEmpty);
      expect(
        find.text('Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ'),
        findsOneWidget,
      );
    });

    testWidgets('an expired or answered request says so and goes away', (
      tester,
    ) async {
      final repo = _Repo(reason: 'not-pending');
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(
          account: AccountDoc(staffTransfer: _request()),
          repo: repo,
        ),
      );
      await tester.scrollUntilVisible(find.text('Không đồng ý'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không đồng ý'));
      await tester.pumpAndSettle();
      expect(repo.answers, [(_id, false)]);
      expect(
        find.text('Đề nghị này đã hết hạn hoặc đã được trả lời.'),
        findsOneWidget,
      );
      expect(find.text('Không đồng ý'), findsNothing);
    });

    testWidgets('a past deadline hides it without asking the server', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const AccountScreen(),
        overrides: _overrides(
          account: AccountDoc(
            staffTransfer: _request(expires: DateTime(2026, 10, 8, 9, 59)),
          ),
        ),
      );
      expect(
        find.text('Hỗ trợ Child Life đề nghị chuyển quyền chủ hồ sơ'),
        findsNothing,
      );
      expect(find.text('Chuyển chủ hồ sơ'), findsOneWidget);
    });
  });

  group('Tôi', () {
    testWidgets('shows the request first; English without a ticket', (
      tester,
    ) async {
      await pumpRouted(
        tester,
        const MeScreen(),
        locale: const Locale('en'),
        overrides: _overrides(
          account: AccountDoc(staffTransfer: _request(ticket: null)),
        ),
      );
      expect(
        find.text('Child Life Support suggests transferring profile ownership'),
        findsOneWidget,
      );
      expect(
        find.text(
          'To m***@gmail.com. Agree within 48 hours (by ${_deadline('en')}); '
          'otherwise the request cancels itself. If you agree, m***@gmail.com '
          'gets the usual invitation to become the profile owner.',
        ),
        findsOneWidget,
      );
      expect(find.text('Agree'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    for (final palette in ClPalette.values) {
      testWidgets('card and sheet use the ${palette.name} palette', (
        tester,
      ) async {
        await pumpRouted(
          tester,
          const MeScreen(),
          palette: palette,
          overrides: _overrides(account: AccountDoc(staffTransfer: _request())),
        );
        final card = find.byType(StaffTransferCard);
        expect(card, findsOneWidget);
        final colors = tester.element(card).cl.colors;
        final box = tester.widget<Container>(
          find.descendant(of: card, matching: find.byType(Container)).first,
        );
        expect((box.decoration! as BoxDecoration).color, colors.sunshineSoft);
        await tester.tap(find.text('Đồng ý'));
        await tester.pumpAndSettle();
        expect(find.text('Đồng ý chuyển quyền chủ hồ sơ?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
