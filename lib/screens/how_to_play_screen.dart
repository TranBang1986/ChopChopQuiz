import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ad_service.dart';
import '../ui.dart';

const kAboutUsUrl = 'https://glowing-gnome-6ab9e0.netlify.app/';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _rules = [
    ('⏱️', 'Mỗi lượt chơi có 120 giây. Trả lời càng nhanh càng tốt!'),
    ('⭐', 'Trả lời đúng: được +1 sao.'),
    ('💥', 'Trả lời sai: số sao quay về mức ban đầu (0 sao).'),
    ('📈', 'Càng nhiều sao, câu hỏi càng khó và đủ mọi chủ đề.'),
    ('🎬', 'Trước khi bắt đầu, xem 1 video để được +5 giây (1 lần mỗi lượt).'),
    ('🏆', 'Điểm của bạn là số sao cao nhất trong lượt chơi. Lên bảng xếp hạng nào!'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CuteBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: Colors.white),
                      color: C.ink,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    const Text('Cách chơi',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900, color: C.pinkDark)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Center(child: Mascot(size: 100)),
                    const SizedBox(height: 12),
                    for (final r in _rules)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: C.blush, width: 3),
                        ),
                        child: Row(
                          children: [
                            Text(r.$1, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(r.$2,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: C.ink)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _AboutUsLink(),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutUsLink extends StatelessWidget {
  const _AboutUsLink();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAboutUs,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: C.blush, width: 3),
          ),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Text('👋', style: TextStyle(fontSize: 32)),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Về chúng tôi',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: C.ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Game đố vui · độc lập, không cần tài khoản',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: C.pinkDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: C.pink, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openAboutUs() async {
  try {
    await launchUrl(Uri.parse(kAboutUsUrl), mode: LaunchMode.externalApplication);
  } catch (_) {}
}
