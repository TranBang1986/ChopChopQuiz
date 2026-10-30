import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:games_services/games_services.dart';

import '../config/leaderboard_ids.dart';
import 'stats_service.dart';

/// Game Center (iOS) + Google Play Games (Android).
/// Điểm bảng xếp hạng = số sao cao nhất đạt được trong 1 lượt chơi.
class LeaderboardService {
  static Future<bool>? _signIn;

  static bool get isMobile => !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  static bool get isConfigured {
    if (!isMobile) return false;
    if (Platform.isAndroid && !LeaderboardIds.androidReady) return false;
    return true;
  }

  static Future<bool> signIn() async => _ensureSignedIn();

  static Future<bool> _ensureSignedIn() {
    if (!isConfigured) return Future<bool>.value(false);
    return _signIn ??= _signInImpl();
  }

  static Future<bool> _signInImpl() async {
    try {
      await GamesServices.signIn();
      final signedIn = await GamesServices.isSignedIn;
      if (!signedIn) _signIn = null;
      return signedIn;
    } catch (_) {
      _signIn = null;
      return false;
    }
  }

  static Future<void> submit(int score) async {
    if (score <= 0) return;
    if (!await _ensureSignedIn()) return;
    try {
      await GamesServices.submitScore(
        score: Score(
          androidLeaderboardID: LeaderboardIds.android,
          iOSLeaderboardID: LeaderboardIds.ios,
          value: score,
        ),
      );
    } catch (_) {}
  }

  /// `null` nếu mở được. Chuỗi lỗi để hiện snackbar.
  static Future<String?> open() async {
    if (!isMobile) return 'Bảng xếp hạng chỉ có trên điện thoại.';
    if (!isConfigured) {
      return 'Chưa gắn ID bảng xếp hạng Play Games.';
    }
    if (!await _ensureSignedIn()) {
      return 'Hãy đăng nhập Google Play Games / Game Center rồi thử lại.';
    }
    await submit(StatsService.instance.best);
    try {
      await GamesServices.showLeaderboards(
        iOSLeaderboardID: LeaderboardIds.ios,
        androidLeaderboardID: LeaderboardIds.android,
      );
      return null;
    } on PlatformException catch (e) {
      debugPrint('LeaderboardService.open: ${e.code} ${e.message}');
      try {
        await GamesServices.showLeaderboards(
          iOSLeaderboardID: '',
          androidLeaderboardID: '',
        );
        return null;
      } catch (_) {
        if ((e.code).contains('Leaderboard') || (e.message ?? '').contains('Leaderboard')) {
          return 'Bảng xếp hạng chưa Publish hoặc ID chưa đúng trên Play Console.';
        }
        return 'Không mở được bảng xếp hạng. Kiểm tra Play Games đã Publish và tài khoản nằm trong Testers.';
      }
    } catch (e) {
      debugPrint('LeaderboardService.open: $e');
      return 'Không mở được bảng xếp hạng.';
    }
  }

  static Future<bool> show() async => (await open()) == null;
}
