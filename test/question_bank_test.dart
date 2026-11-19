import 'dart:convert';
import 'dart:io';

import 'package:chop_chop_quiz/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('question bank is structurally valid', () {
    final data = jsonDecode(File('assets/data/questions.json').readAsStringSync())
        as Map<String, dynamic>;
    final list = data['questions'] as List;
    final total = data['meta']?['total_questions'] as int?;
    expect(list, isNotEmpty);
    expect(total, isNotNull);
    expect(list.length, total);

    final ids = <String>{};
    for (final raw in list) {
      final j = raw as Map<String, dynamic>;
      final q = Question.fromJson(j);
      expect(ids.add(q.id), isTrue, reason: 'trùng id ${q.id}');
      expect(q.difficulty, anyOf('easy', 'medium', 'hard'));
      expect(q.options, hasLength(4));
      expect(q.correctIndex, inInclusiveRange(0, 3));
      expect(q.text, isNotEmpty);
      expect(q.topic, isNotEmpty);
      expect(j['correct_answer'], q.options[q.correctIndex]);
    }
  });
}
