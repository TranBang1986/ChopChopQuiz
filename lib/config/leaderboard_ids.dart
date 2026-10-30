/// Leaderboard IDs. The platform keeps the highest submitted value.
///
/// iOS: create a Game Center leaderboard in App Store Connect with this exact ID.
/// Android: paste the leaderboard ID from Play Console
/// (Play Games Services → Setup and management → Leaderboards).
class LeaderboardIds {
  static const ios = 'com.tranbang.chopChopQuiz.best_stars';

  static const android = 'CgkIl_afm9sJEAIQAg';

  static bool get androidReady => !android.startsWith('REPLACE_');
}
