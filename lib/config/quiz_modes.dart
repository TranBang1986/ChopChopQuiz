import 'package:flutter/material.dart';

import '../ui.dart';

/// Chế độ chơi: Tổng hợp (lên bảng xếp hạng) hoặc theo từng chủ đề (sao local).
class QuizMode {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color shadow;
  /// `null` = lấy câu từ mọi chủ đề.
  final String? topicFilter;
  final bool ranksOnLeaderboard;

  const QuizMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.shadow,
    this.topicFilter,
    this.ranksOnLeaderboard = false,
  });

  bool get isMixed => topicFilter == null;

  /// Ảnh nền carousel Home: `assets/carousel/<id>.png`.
  String get carouselAsset => 'assets/carousel/$id.png';

  static const mixed = QuizMode(
    id: 'mixed',
    title: 'Tổng hợp',
    subtitle: 'Mọi chủ đề · lên bảng xếp hạng',
    emoji: '⚡',
    color: C.pink,
    shadow: C.pinkDark,
    ranksOnLeaderboard: true,
  );

  static const topics = <QuizMode>[
    QuizMode(
      id: 'toan',
      title: 'Toán · Logic',
      subtitle: 'Số học & suy luận',
      emoji: '🧮',
      color: Color(0xFF7C6CF0),
      shadow: Color(0xFF5A4BC7),
      topicFilter: 'Toán – Logic',
    ),
    QuizMode(
      id: 'dia_ly',
      title: 'Địa lý',
      subtitle: 'Đất nước & bản đồ',
      emoji: '🌍',
      color: Color(0xFF3CB8A0),
      shadow: Color(0xFF2A8F7B),
      topicFilter: 'Địa lý',
    ),
    QuizMode(
      id: 'the_thao',
      title: 'Thể thao',
      subtitle: 'Trận đấu & kỷ lục',
      emoji: '⚽',
      color: Color(0xFFFF8A4C),
      shadow: Color(0xFFD96A30),
      topicFilter: 'Thể thao',
    ),
    QuizMode(
      id: 'choi_chu',
      title: 'Chơi chữ',
      subtitle: 'Tiếng Việt vui',
      emoji: '✍️',
      color: Color(0xFFE0558F),
      shadow: Color(0xFFB83D6E),
      topicFilter: 'Chơi chữ – Tiếng Việt',
    ),
    QuizMode(
      id: 'tieng_anh',
      title: 'Tiếng Anh',
      subtitle: 'Từ vựng cơ bản',
      emoji: '🔤',
      color: Color(0xFF4C8DFF),
      shadow: Color(0xFF2F6AD1),
      topicFilter: 'Tiếng Anh cơ bản',
    ),
    QuizMode(
      id: 'khoa_hoc',
      title: 'Khoa học',
      subtitle: 'Khám phá thế giới',
      emoji: '🔬',
      color: Color(0xFF2FB38A),
      shadow: Color(0xFF1F8A68),
      topicFilter: 'Khoa học',
    ),
    QuizMode(
      id: 'cong_nghe',
      title: 'Công nghệ',
      subtitle: 'Máy móc & số hóa',
      emoji: '💻',
      color: Color(0xFF5B7CFF),
      shadow: Color(0xFF3F5AC7),
      topicFilter: 'Công nghệ',
    ),
    QuizMode(
      id: 'lich_su',
      title: 'Lịch sử',
      subtitle: 'Sự kiện & nhân vật',
      emoji: '📜',
      color: Color(0xFFC48A3A),
      shadow: Color(0xFF9A6A28),
      topicFilter: 'Lịch sử',
    ),
    QuizMode(
      id: 'van_hoa',
      title: 'Văn hóa',
      subtitle: 'Đời sống quanh ta',
      emoji: '🎭',
      color: Color(0xFFFF6B9D),
      shadow: Color(0xFFD44A7A),
      topicFilter: 'Văn hóa – Đời sống',
    ),
    QuizMode(
      id: 'meo',
      title: 'Mẹo · Câu đố',
      subtitle: 'Tư duy nhanh',
      emoji: '💡',
      color: Color(0xFFE0B100),
      shadow: Color(0xFFB88E00),
      topicFilter: 'Mẹo – Câu đố',
    ),
    QuizMode(
      id: 'nghe_thuat',
      title: 'Nghệ thuật',
      subtitle: 'Nhạc · phim · nghệ thuật',
      emoji: '🎬',
      color: Color(0xFF9B6BFF),
      shadow: Color(0xFF7548D4),
      topicFilter: 'Âm nhạc – Điện ảnh – Nghệ thuật',
    ),
    QuizMode(
      id: 'thien_nhien',
      title: 'Thiên nhiên',
      subtitle: 'Động vật & môi trường',
      emoji: '🐾',
      color: Color(0xFF63DDB4),
      shadow: Color(0xFF2FB38A),
      topicFilter: 'Động vật – Thiên nhiên',
    ),
    QuizMode(
      id: 'suc_khoe',
      title: 'Sức khỏe',
      subtitle: 'Cơ thể con người',
      emoji: '❤️',
      color: Color(0xFFFF6B6B),
      shadow: Color(0xFFD94848),
      topicFilter: 'Sức khỏe – Cơ thể người',
    ),
    QuizMode(
      id: 'am_thuc',
      title: 'Ẩm thực',
      subtitle: 'Món ngon quanh ta',
      emoji: '🍜',
      color: Color(0xFFFF9F43),
      shadow: Color(0xFFD97C20),
      topicFilter: 'Ẩm thực',
    ),
  ];

  static List<QuizMode> get all => [mixed, ...topics];

  static QuizMode byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => mixed);
}
