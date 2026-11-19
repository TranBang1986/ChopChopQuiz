import 'package:shared_preferences/shared_preferences.dart';

import '../config/quiz_modes.dart';

/// Lưu kỷ lục theo chế độ và số lượt chơi đã kết thúc (để tính quảng cáo xen kẽ).
class StatsService {
  StatsService._();
  static final instance = StatsService._();

  late SharedPreferences _p;

  Future<void> load() async => _p = await SharedPreferences.getInstance();

  /// Kỷ lục chế độ Tổng hợp — dùng cho bảng xếp hạng Game Center / Play Games.
  int get best => bestFor(QuizMode.mixed.id);

  int get plays => _p.getInt('plays') ?? 0;

  bool get soundOn => _p.getBool('soundOn') ?? true;
  set soundOn(bool v) => _p.setBool('soundOn', v);

  bool get musicOn => _p.getBool('musicOn') ?? true;
  set musicOn(bool v) => _p.setBool('musicOn', v);

  String _key(String modeId) => modeId == QuizMode.mixed.id ? 'best' : 'best_$modeId';

  int bestFor(String modeId) => _p.getInt(_key(modeId)) ?? 0;

  /// Ghi nhận 1 lượt chơi kết thúc, trả về tổng số lượt.
  Future<int> addPlay(int score, {required QuizMode mode}) async {
    final plays = this.plays + 1;
    await _p.setInt('plays', plays);
    if (score > bestFor(mode.id)) {
      await _p.setInt(_key(mode.id), score);
    }
    return plays;
  }
}
