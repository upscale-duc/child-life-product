import 'package:child_life/features/milestones/milestone_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits a paragraph into sentences', () {
    expect(
      readingChunks(
        'Khi bạn ghé mặt lại gần, bé nhìn chăm chú vào mắt bạn. '
        'Khác với lúc bé nhìn đăm đăm về phía cửa sổ sáng, ánh mắt bé bám theo bạn. '
        'Bạn thử lúc bé tỉnh táo, vừa bú no.',
      ),
      [
        'Khi bạn ghé mặt lại gần, bé nhìn chăm chú vào mắt bạn.',
        'Khác với lúc bé nhìn đăm đăm về phía cửa sổ sáng, ánh mắt bé bám theo bạn.',
        'Bạn thử lúc bé tỉnh táo, vừa bú no.',
      ],
    );
  });

  test('keeps a quoted exchange with the sentence before it', () {
    expect(
      readingChunks(
        'Bé trả lời câu bạn hỏi rồi nói thêm, như: Con ăn gì? Ăn cơm. '
        'Có ngon không? Ngon, cơm nóng. '
        'Bé cũng kể được việc đang diễn ra trong tranh, như đang chạy.',
      ),
      [
        'Bé trả lời câu bạn hỏi rồi nói thêm, như: Con ăn gì? Ăn cơm. '
            'Có ngon không? Ngon, cơm nóng.',
        'Bé cũng kể được việc đang diễn ra trong tranh, như đang chạy.',
      ],
    );
  });

  test('honours paragraph breaks and leaves decimals alone', () {
    expect(readingChunks('Bé nặng khoảng 2.5 kg lúc này.\n\nĐo lại sau.'), [
      'Bé nặng khoảng 2.5 kg lúc này.',
      'Đo lại sau.',
    ]);
  });
}
