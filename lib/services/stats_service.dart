import 'package:shared_preferences/shared_preferences.dart';

/// Lưu kỷ lục cá nhân và số lượt chơi đã kết thúc (để tính quảng cáo xen kẽ).
class StatsService {
  StatsService._();
  static final instance = StatsService._();

  late SharedPreferences _p;

  Future<void> load() async => _p = await SharedPreferences.getInstance();

  int get best => _p.getInt('best') ?? 0;
  int get plays => _p.getInt('plays') ?? 0;

  bool get soundOn => _p.getBool('soundOn') ?? true;
  set soundOn(bool v) => _p.setBool('soundOn', v);

  bool get musicOn => _p.getBool('musicOn') ?? true;
  set musicOn(bool v) => _p.setBool('musicOn', v);

  /// Ghi nhận 1 lượt chơi kết thúc, trả về tổng số lượt.
  Future<int> addPlay(int score) async {
    final plays = this.plays + 1;
    await _p.setInt('plays', plays);
    if (score > best) await _p.setInt('best', score);
    return plays;
  }
}
