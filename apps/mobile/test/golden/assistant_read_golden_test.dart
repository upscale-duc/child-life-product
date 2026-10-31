@Tags(['golden'])
library;

import 'package:child_life/core/design/cl_theme.dart';
import 'package:child_life/core/design/tokens.g.dart';
import 'package:child_life/features/assistant/assistant_cards.dart';
import 'package:child_life/features/assistant/assistant_models.dart';
import 'package:child_life/features/baby/time_zones.dart';
import 'package:child_life/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lumi read cards (`read_card`, one per read tool), Light / Night care × vi / en. The rows are
/// what `firebase/functions/src/assistant-reads.ts` builds for synthetic data on 15 Oct 2026,
/// 14:17 in Asia/Ho_Chi_Minh (the server owns the words; the app owns the layout).
/// Regenerate on macOS: flutter test --tags golden --update-goldens test/golden/assistant_read_golden_test.dart

const _asOf = '2026-10-15T07:17:00.000Z';

Map<String, Object?> _card(
  String tool,
  String title,
  List<List<String?>> rows, {
  required String action,
  required String link,
  String? caveat,
}) => {
  'type': 'read_card',
  'schemaVersion': 1,
  'tool': tool,
  'title': title,
  'asOf': _asOf,
  'rows': [
    for (final r in rows)
      {'label': r[0], 'value': r[1], if (r.length > 2) 'link': r[2]},
  ],
  'caveat': caveat,
  'action': {'label': action, 'link': link},
  'sourceIds': const <String>[],
};

String _logged(bool vi) => vi
    ? 'Chỉ tính dữ liệu gia đình đã ghi; thiếu ghi nhận không có nghĩa là không diễn ra.'
    : 'Only family logs are counted; missing logs do not mean an activity did not happen.';

/// Care reads: what was logged today.
List<Map<String, Object?>> _daily(bool vi) => [
  _card(
    'care_summary',
    vi ? 'Bú và ngủ đã ghi · 15/10' : 'Logged feeds and sleep · 15/10',
    [
      [
        vi ? 'Bú bình' : 'Bottle',
        vi ? '2 cữ · 300 ml' : '2 feeds · 300 ml',
        '/care/stats/feed',
      ],
      [
        vi ? 'Giấc ngủ' : 'Sleep',
        vi ? '2 giấc · 6 giờ 2 phút' : '2 sleeps · 6 h 2 min',
        '/care/stats/sleep',
      ],
    ],
    action: vi ? 'Mở Lịch sử' : 'Open History',
    link: '/care/history',
    caveat: _logged(vi),
  ),
  _card(
    'day_overview',
    vi ? 'Ngày của bé · 15/10' : "Baby's day · 15/10",
    [
      [
        vi ? 'Bú bình' : 'Bottle',
        vi ? '2 cữ · 270 ml\nGần nhất 11:00' : '2 feeds · 270 ml\nLatest 11:00',
        '/care/stats/feed',
      ],
      [
        vi ? 'Bú mẹ' : 'Nursing',
        vi
            ? '1 lần · 15 phút\nGần nhất 09:00'
            : '1 feed · 15 min\nLatest 09:00',
        '/care/stats/feed',
      ],
      [
        vi ? 'Giấc ngủ' : 'Sleep',
        vi ? '2 giấc · 7 giờ\nGần nhất 12:00' : '2 sleeps · 7 h\nLatest 12:00',
        '/care/stats/sleep',
      ],
      [
        vi ? 'Thay tã' : 'Diapers',
        vi
            ? 'Chưa ghi\nGần nhất 22:10 · 14/10'
            : 'None logged\nLatest 22:10 · 14/10',
        '/care/history?filter=diaper',
      ],
      [
        vi ? 'Đang ngủ' : 'Sleeping',
        vi ? '47 phút\nTừ 13:30' : '47 min\nSince 13:30',
        '/care/timer/sleep',
      ],
    ],
    action: vi ? 'Mở Hôm nay' : 'Open Today',
    link: '/today',
    caveat: _logged(vi),
  ),
  _card(
    'sleep_facts',
    vi ? 'Xu hướng giấc ngủ' : 'Sleep trend',
    [
      [
        vi ? 'Gần đây (mỗi ngày)' : 'Recently (per day)',
        vi ? 'khoảng 12 giờ 22 phút' : 'about 12 h 22 min',
      ],
      [
        vi ? 'Trước đó (mỗi ngày)' : 'Before (per day)',
        vi ? 'khoảng 13 giờ 25 phút' : 'about 13 h 25 min',
      ],
    ],
    action: vi ? 'Mở thống kê giấc ngủ' : 'Open sleep statistics',
    link: '/care/stats/sleep',
    caveat: _logged(vi),
  ),
  _card(
    'diaper_summary',
    vi ? 'Thay tã · 15/10' : 'Diapers · 15/10',
    [
      [vi ? 'Số lần đã ghi' : 'Logged', vi ? '5 lần' : '5 changes'],
      [vi ? 'Tã ướt' : 'Wet', vi ? '3 lần' : '3 changes'],
      [vi ? 'Cả ướt và bẩn' : 'Wet and dirty', vi ? '2 lần' : '2 changes'],
    ],
    action: vi ? 'Xem lịch sử thay tã' : 'Open diaper history',
    link: '/care/history?filter=diaper',
    caveat: _logged(vi),
  ),
];

/// Family records: growth, vaccines, reminders, spending, solids.
List<Map<String, Object?>> _records(bool vi) => [
  _card(
    'growth_snapshot',
    vi ? 'Tăng trưởng đã ghi' : 'Logged growth',
    [
      [
        vi ? 'Cân nặng' : 'Weight',
        vi
            ? '7,2 kg · WHO P50\nĐo 10/10 · +0,35 kg so với 12/09'
            : '7.2 kg · WHO P50\nMeasured 10/10 · +0.35 kg since 12/09',
        '/care/growth',
      ],
      [
        vi ? 'Chiều dài' : 'Length',
        vi
            ? '66 cm · WHO P42,3\nĐo 10/10'
            : '66 cm · WHO P42.3\nMeasured 10/10',
        '/care/growth',
      ],
    ],
    action: vi ? 'Mở biểu đồ tăng trưởng' : 'Open growth chart',
    link: '/care/growth',
    caveat: vi
        ? 'Percentile WHO tham khảo theo tuổi và giới tính, không phải chẩn đoán. Chưa đủ ngày sinh hoặc giới tính thì chưa tính percentile; xem biểu đồ để theo dõi nhiều lần đo.'
        : 'WHO age-and-sex percentiles are a reference, not a diagnosis. A date of birth and sex are needed to calculate a percentile; open the chart to follow repeated measurements.',
  ),
  _card(
    'vaccine_next',
    vi ? 'Lịch tiêm sắp tới' : 'Upcoming vaccinations',
    [
      [
        vi ? '6in1 · mũi 2' : '6in1 · dose 2',
        vi
            ? '10/10\nLịch đã qua, chưa ghi đã tiêm'
            : '10/10\nPast planned date, no given record',
        '/care/vaccines/dose/dtp_2',
      ],
      [
        vi ? 'Phế cầu · mũi 2' : 'Pneumococcal · dose 2',
        '10/11',
        '/care/vaccines/dose/pcv_2',
      ],
    ],
    action: vi ? 'Mở Sổ tiêm chủng' : 'Open vaccination book',
    link: '/care/vaccines',
    caveat: vi
        ? 'Lịch Việt Nam trong ứng dụng. Theo ngày đã dời lịch và lựa chọn của gia đình; xác nhận lịch thực tế với nơi tiêm.'
        : 'Vietnam schedule in the app. Includes family choices and rescheduled dates; confirm actual appointments with your clinic.',
  ),
  _card(
    'reminders_today',
    vi ? 'Nhắc việc · 15/10' : 'Reminders · 15/10',
    [
      [
        vi ? 'Mua bỉm' : 'Buy diapers',
        vi ? 'Cả ngày · Chưa xong\nMai' : 'All day · Pending\nMai',
        '/care/reminders/r1',
      ],
      [
        vi ? 'Nhắc bú' : 'Feed reminder',
        vi ? '16:00 · lần tiếp theo\nMai, Minh' : '16:00 · next\nMai, Minh',
        '/care/reminders/rules/f1',
      ],
    ],
    action: vi ? 'Mở Nhắc việc' : 'Open Reminders',
    link: '/care/reminders',
  ),
  _card(
    'spending_month',
    vi ? 'Chi tiêu tháng 10/2026' : 'Spending for 10/2026',
    [
      [
        vi ? 'Tổng đã chi' : 'Total spent',
        vi ? '2.450.000 VND' : '2,450,000 VND',
      ],
      [
        vi ? 'Ngân sách tháng' : 'Monthly budget',
        vi ? '3.000.000 VND' : '3,000,000 VND',
        '/utilities/spending/budget',
      ],
      [
        vi ? 'Ngân sách còn lại' : 'Budget remaining',
        vi ? '550.000 VND' : '550,000 VND',
      ],
      [
        vi ? 'Sữa & ăn dặm' : 'Milk & solids',
        vi ? '1.650.000 VND' : '1,650,000 VND',
      ],
      [
        vi ? 'Tã & vệ sinh' : 'Diapers & hygiene',
        vi ? '800.000 VND' : '800,000 VND',
      ],
    ],
    action: vi ? 'Mở Chi tiêu' : 'Open Spending',
    link: '/utilities/spending',
    caveat: vi
        ? 'Chi tiêu của bé đang chọn, chỉ trong hội thoại riêng. Các loại tiền được cộng riêng, không quy đổi.'
        : 'Expenses for the selected baby, in your private conversation. Currencies are totalled separately without conversion.',
  ),
  _card(
    'solids_history',
    vi ? 'Thực phẩm bé đã thử' : 'Foods your baby has tried',
    [
      [
        vi ? 'Trứng gà' : 'Egg',
        vi
            ? '2 lần · Chưa hợp\nGần nhất 14/10 · Nổi mẩn, mề đay'
            : '2 tries · Not yet\nLatest 14/10 · Rash or hives',
        '/care/solids/food/fd_egg',
      ],
      [
        vi ? 'Bí đỏ' : 'Pumpkin',
        vi ? '4 lần · Thích\nGần nhất 13/10' : '4 tries · Liked\nLatest 13/10',
        '/care/solids/food/fd_pumpkin',
      ],
    ],
    action: vi ? 'Mở nhật ký ăn dặm' : 'Open solids diary',
    link: '/care/solids/history?tab=foods',
    caveat: vi
        ? 'Dấu hiệu gia đình ghi sau ăn không xác định nguyên liệu gây dị ứng; chưa ghi phản ứng không có nghĩa đã dung nạp tốt.'
        : 'Family symptoms after a meal do not identify an allergen; no recorded reaction does not establish tolerance.',
  ),
];

/// Content and Hiểu con reads.
List<Map<String, Object?>> _content(bool vi) => [
  _card(
    'milestones',
    vi ? 'Mốc của bé' : 'Baby milestones',
    [
      [
        vi ? 'Lật người' : 'Rolls over',
        vi ? 'Đã ghi 02/10' : 'Seen 02/10',
        '/utilities/milestones/m1',
      ],
      [
        vi ? 'Ngồi có hỗ trợ' : 'Sits with support',
        vi ? 'Quanh tuổi bé' : 'Around this age',
        '/utilities/milestones/m2',
      ],
    ],
    action: vi ? 'Mở Mốc phát triển' : 'Open Milestones',
    link: '/utilities/milestones',
    caveat: vi
        ? 'Mỗi bé có nhịp riêng. Mốc tham khảo không phải đánh giá sớm, muộn hay chẩn đoán.'
        : 'Every baby develops at their own pace. Reference milestones are not an early/late assessment or diagnosis.',
  ),
  _card(
    'stage',
    vi ? 'Giai đoạn của bé' : 'Your baby’s stage',
    [
      [
        vi
            ? 'Tháng thứ 5: tò mò với mọi thứ'
            : 'Month 5: curious about everything',
        vi
            ? '• Với tay lấy đồ chơi\n• Cười thành tiếng'
            : '• Reaches for toys\n• Laughs out loud',
      ],
      [
        vi ? 'Ba mẹ có thể thử' : 'Things to try',
        vi
            ? '• Cho bé nằm sấp chơi 10 phút\n• Đọc sách tranh cùng bé'
            : '• Tummy time for 10 minutes\n• Read a picture book together',
      ],
    ],
    action: vi ? 'Mở Giai đoạn của bé' : 'Open Stages',
    link: '/stages/s5',
  ),
  _card(
    'first_aid',
    vi ? 'Sơ cứu trẻ em' : 'Child first aid',
    [
      [
        vi ? 'Sốt' : 'Fever',
        vi
            ? 'Đo nhiệt độ, cho bé mặc thoáng. Gọi 115 nếu bé dưới 3 tháng sốt từ 38°C.'
            : 'Take a temperature and dress your baby lightly. Call 115 if a baby under 3 months has 38°C or more.',
        '/utilities/first-aid/s/fever',
      ],
    ],
    action: vi ? 'Mở Sơ cứu' : 'Open First aid',
    link: '/utilities/first-aid',
  ),
  _card(
    'insight_basis',
    vi ? 'Điều đáng chú ý' : 'Worth noticing',
    [
      [
        vi
            ? 'Khoảng ngủ đêm dài nhất đang dài hơn'
            : 'Longest night stretch is getting longer',
        vi
            ? 'Mình lấy khoảng ngủ liền dài nhất mỗi đêm, từ 19:00 đến 07:00.\n5 đêm gần đây (10/10–14/10) trung bình 5 giờ 10 phút; 5 đêm trước đó (03/10–07/10) trung bình 4 giờ 20 phút.\nDài nhất là đêm 13/10: 6 giờ.\nĐêm 08/10, 09/10 chưa ghi đủ nên không tính.\nGhi bởi Mai, Minh.'
            : 'I took the longest single sleep each night, from 19:00 to 07:00.\nThe last 5 nights (10/10–14/10) averaged 5 h 10 min; the 5 nights before (03/10–07/10) averaged 4 h 20 min.\nThe longest was the night of 13/10: 6 h.\nNot counted: 08/10, 09/10 (not fully logged).\nLogged by Mai, Minh.',
      ],
    ],
    action: vi ? 'Mở Hiểu con' : 'Open Know your baby',
    link: '/care/insights/night_longest',
    caveat: vi
        ? 'Số liệu tính từ ghi nhận của gia đình. Dữ liệu chưa cho biết nguyên nhân; nếu lo lắng, hãy hỏi bác sĩ.'
        : "Figures come from your family's logs. They can't tell the cause; if you're worried, ask your doctor.",
  ),
];

void main() {
  setUpAll(ensureTimeZones);
  final groups = {
    'rc_daily': (_daily, 1400.0),
    'rc_records': (_records, 1700.0),
    'rc_content': (_content, 1300.0),
  };
  for (final MapEntry(key: name, value: (cards, height)) in groups.entries) {
    for (final palette in ClPalette.values) {
      for (final lang in const ['vi', 'en']) {
        testWidgets('$name ${palette.name} $lang', (tester) async {
          tester.view.physicalSize = Size(375, height);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final parts = [
            for (final c in cards(lang == 'vi')) ReadCardPart.fromJson(c)!,
          ];
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('golden'),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildClTheme(palette),
                locale: Locale(lang),
                supportedLocales: const [Locale('vi'), Locale('en')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: Builder(
                  builder: (context) => Scaffold(
                    backgroundColor: context.cl.colors.cloud,
                    body: ListView(
                      padding: const EdgeInsets.all(ClSpace.s4),
                      children: [
                        for (final p in parts) ...[
                          AsReadCard(
                            part: p,
                            zone: 'Asia/Ho_Chi_Minh',
                            now: DateTime.utc(2026, 10, 15, 7, 17),
                            onOpen: (_) {},
                          ),
                          const SizedBox(height: ClSpace.s3),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(const ValueKey('golden')),
            matchesGoldenFile('goldens/as/${name}_${palette.name}_$lang.png'),
          );
        });
      }
    }
  }
}
