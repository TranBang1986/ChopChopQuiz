import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/stats_service.dart';
import '../ui.dart';
import 'how_to_play_screen.dart';
import 'play_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.playMusic(MusicTrack.menu);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    AudioService.instance.playMusic(MusicTrack.menu);
    setState(() {}); // cập nhật kỷ lục
  }

  Future<void> _leaderboard() async {
    final err = await LeaderboardService.open();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CuteBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Align(alignment: Alignment.centerRight, child: AudioToggles()),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Mascot(size: 150),
                        const SizedBox(height: 8),
                        const Text('Chớp Chớp',
                            style: TextStyle(
                                fontSize: 48,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: C.pinkDark)),
                        const Text('QUIZ',
                            style: TextStyle(
                                fontSize: 30,
                                letterSpacing: 8,
                                fontWeight: FontWeight.w900,
                                color: C.skyDark)),
                        const SizedBox(height: 14),
                        Pill(
                            text: '🏆 Kỷ lục: ${StatsService.instance.best} ⭐',
                            color: C.yellowDark),
                        const SizedBox(height: 28),
                        CuteButton(
                          label: 'CHƠI NGAY',
                          fontSize: 26,
                          height: 68,
                          color: C.mint,
                          shadow: C.mintDark,
                          onTap: () => _open(const PlayScreen()),
                        ),
                        const SizedBox(height: 16),
                        CuteButton(
                          label: '🏆 Bảng xếp hạng',
                          color: C.sky,
                          shadow: C.skyDark,
                          onTap: _leaderboard,
                        ),
                        const SizedBox(height: 16),
                        CuteButton(
                          label: '📖 Cách chơi',
                          onTap: () => _open(const HowToPlayScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
