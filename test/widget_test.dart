import 'dart:math';

import 'package:chop_chop_quiz/models.dart';
import 'package:chop_chop_quiz/screens/how_to_play_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Question.fromJson parses the quiz schema', () {
    final q = Question.fromJson({
      'id': 't1',
      'topic': 'Toán',
      'difficulty': 'easy',
      'question': '1 + 1 = ?',
      'options': ['1', '2', '3', '4'],
      'correct_index': 1,
      'explanation': 'Hai.',
    });
    expect(q.text, '1 + 1 = ?');
    expect(q.options.length, 4);
    expect(q.correctIndex, 1);
  });

  test('shuffled question keeps the correct answer', () {
    final q = Question.fromJson({
      'id': 't2',
      'topic': 'Toán',
      'difficulty': 'easy',
      'question': '2 + 2 = ?',
      'options': ['3', '4', '5', '6'],
      'correct_index': 1,
      'explanation': '',
    });
    final shuffled = q.shuffled(Random(7));
    expect(shuffled.options[shuffled.correctIndex], '4');
  });

  testWidgets('how to play shows Ve chung toi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HowToPlayScreen()));
    await tester.pump();
    expect(find.text('Cách chơi'), findsOneWidget);
    expect(find.text('Về chúng tôi'), findsOneWidget);
  });
}
