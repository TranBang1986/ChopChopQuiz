import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models.dart';

/// Nạp câu hỏi từ assets và chọn câu tiếp theo theo số sao hiện tại.
/// Thêm câu hỏi mới: chỉ cần bổ sung vào assets/data/questions.json (cùng schema).
class QuestionRepository {
  QuestionRepository._();
  static final instance = QuestionRepository._();

  static const _order = ['easy', 'medium', 'hard'];

  final _rand = Random();
  final Map<String, List<Question>> _byDiff = {for (final d in _order) d: []};
  final Set<String> _used = {};

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/questions.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    for (final j in data['questions'] as List) {
      final q = Question.fromJson(j as Map<String, dynamic>);
      (_byDiff[q.difficulty] ??= []).add(q);
    }
  }

  /// Độ khó tăng dần theo số sao (trộn lẫn để không đơn điệu).
  String _pickDifficulty(int stars) {
    final w = stars < 3
        ? [.75, .25, 0.0]
        : stars < 6
            ? [.25, .55, .20]
            : stars < 9
                ? [.05, .45, .50]
                : [0.0, .20, .80];
    var r = _rand.nextDouble();
    for (var i = 0; i < 3; i++) {
      if (r < w[i]) return _order[i];
      r -= w[i];
    }
    return 'medium';
  }

  Question next(int stars, {String? lastTopic}) {
    var diff = _pickDifficulty(stars);
    if ((_byDiff[diff] ?? []).isEmpty) {
      diff = _order.firstWhere((d) => (_byDiff[d] ?? []).isNotEmpty);
    }
    final all = _byDiff[diff]!;
    var pool = all.where((q) => !_used.contains(q.id)).toList();
    if (pool.isEmpty) {
      _used.removeAll(all.map((q) => q.id)); // hết câu thì xoay vòng lại
      pool = List.of(all);
    }
    var candidates = pool.where((q) => q.topic != lastTopic).toList();
    if (candidates.isEmpty) candidates = pool; // tránh 2 câu liền cùng chủ đề
    final q = candidates[_rand.nextInt(candidates.length)];
    _used.add(q.id);
    return q.shuffled(_rand);
  }
}
