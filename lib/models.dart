import 'dart:math';

class Question {
  final String id;
  final String topic;
  final String difficulty; // easy | medium | hard
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const Question({
    required this.id,
    required this.topic,
    required this.difficulty,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        topic: j['topic'] as String,
        difficulty: j['difficulty'] as String,
        text: j['question'] as String,
        options: List<String>.from(j['options'] as List),
        correctIndex: j['correct_index'] as int,
        explanation: (j['explanation'] ?? '') as String,
      );

  /// Trộn vị trí đáp án để chơi lại không nhớ vị trí.
  Question shuffled(Random r) {
    final order = List<int>.generate(options.length, (i) => i)..shuffle(r);
    return Question(
      id: id,
      topic: topic,
      difficulty: difficulty,
      text: text,
      options: [for (final i in order) options[i]],
      correctIndex: order.indexOf(correctIndex),
      explanation: explanation,
    );
  }
}
