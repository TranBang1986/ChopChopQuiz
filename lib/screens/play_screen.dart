import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/question_repository.dart';
import '../services/stats_service.dart';
import '../ui.dart';

enum Phase { ready, playing, over }

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  static const baseSeconds = 120;
  static const bonusSeconds = 5;

  final _repo = QuestionRepository.instance;

  Phase phase = Phase.ready;
  int remaining = baseSeconds;
  bool bonusUsed = false;
  int stars = 0; // sao hiện tại
  int peak = 0; // sao cao nhất = điểm
  int correct = 0;
  Question? q;
  int? picked;
  bool locked = false;
  String? _lastTopic;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!AdService.instance.rewardedReady) AdService.instance.loadRewarded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.instance.playMusic(MusicTrack.menu);
    super.dispose();
  }

  // ---------------- Game flow ----------------
  void _start() {
    AudioService.instance.start();
    AudioService.instance.playMusic(MusicTrack.game);
    setState(() {
      stars = peak = correct = 0;
      picked = null;
      locked = false;
      _lastTopic = null;
      _nextQuestion();
      phase = Phase.playing;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (remaining <= 1) {
        setState(() => remaining = 0);
        _finish();
      } else {
        setState(() => remaining--);
        if (remaining <= 10) {
          AudioService.instance.tick(urgent: remaining <= 3);
        }
      }
    });
  }

  void _nextQuestion() {
    q = _repo.next(stars, lastTopic: _lastTopic);
    _lastTopic = q!.topic;
  }

  Future<void> _answer(int i) async {
    if (locked || phase != Phase.playing) return;
    final ok = i == q!.correctIndex;
    if (ok) {
      AudioService.instance.correct();
    } else {
      AudioService.instance.wrong();
    }
    setState(() {
      picked = i;
      locked = true;
      if (ok) {
        stars++;
        correct++;
        if (stars > peak) peak = stars;
      } else {
        stars = 0; // sai -> về mức ban đầu
      }
    });
    await Future.delayed(Duration(milliseconds: ok ? 450 : 900));
    if (!mounted || phase != Phase.playing) return;
    setState(() {
      _nextQuestion();
      picked = null;
      locked = false;
    });
  }

  Future<void> _finish() async {
    if (phase == Phase.over) return;
    _timer?.cancel();
    setState(() => phase = Phase.over);
    final isRecord = peak > 0 && peak >= StatsService.instance.best;
    AudioService.instance.finish(record: isRecord);
    AudioService.instance.playMusic(MusicTrack.menu);
    final plays = await StatsService.instance.addPlay(peak);
    LeaderboardService.submit(peak);
    // Interstitial sau mỗi 5 lượt chơi kết thúc.
    if (plays % 5 == 0) {
      await AudioService.instance.pauseForAd();
      await AdService.instance.showInterstitial();
      await AudioService.instance.resumeAfterAd();
    }
    if (!mounted) return;
    _showResult();
  }

  void _reset() {
    setState(() {
      phase = Phase.ready;
      remaining = baseSeconds;
      bonusUsed = false;
      stars = peak = correct = 0;
      picked = null;
      locked = false;
    });
    if (!AdService.instance.rewardedReady) AdService.instance.loadRewarded();
  }

  Future<void> _watchBonus() async {
    if (bonusUsed) return;
    if (!AdService.instance.rewardedReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video chưa sẵn sàng, thử lại sau nhé!')),
      );
      AdService.instance.loadRewarded();
      return;
    }
    await AudioService.instance.pauseForAd();
    final earned = await AdService.instance.showRewarded();
    await AudioService.instance.resumeAfterAd();
    if (!mounted) return;
    if (earned) {
      AudioService.instance.bonus();
      setState(() {
        bonusUsed = true;
        remaining += bonusSeconds;
      });
    }
  }

  Future<void> _confirmExit() async {
    if (phase != Phase.playing) {
      Navigator.of(context).pop();
      return;
    }
    _timer?.cancel(); // tạm dừng khi hỏi
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Thoát ván chơi?'),
        content: const Text('Ván này sẽ không được tính điểm.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Chơi tiếp')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Thoát')),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      Navigator.of(context).pop();
    } else {
      _startTimer();
    }
  }

  void _showResult() {
    final isRecord = peak > 0 && peak >= StatsService.instance.best;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Mascot(size: 90),
              const SizedBox(height: 6),
              const Text('Hết giờ rồi!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.pinkDark)),
              Text('⭐ $peak',
                  style: const TextStyle(
                      fontSize: 54, fontWeight: FontWeight.w900, color: C.yellowDark)),
              Text('Số sao cao nhất • Đúng $correct câu',
                  style: const TextStyle(fontSize: 16, color: C.ink)),
              if (isRecord)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Pill(text: '🎉 Kỷ lục mới!', color: C.mint, fontSize: 16),
                )
              else
                Text('Kỷ lục: ${StatsService.instance.best} ⭐',
                    style: const TextStyle(fontSize: 16, color: C.ink)),
              const SizedBox(height: 18),
              CuteButton(
                label: 'Chơi lại',
                color: C.mint,
                shadow: C.mintDark,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _reset();
                },
              ),
              const SizedBox(height: 12),
              CuteButton(
                label: '🏆 Bảng xếp hạng',
                color: C.sky,
                shadow: C.skyDark,
                height: 50,
                fontSize: 17,
                onTap: () => LeaderboardService.show(),
              ),
              const SizedBox(height: 12),
              CuteButton(
                label: 'Trang chủ',
                height: 50,
                fontSize: 17,
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: CuteBackground(
          child: SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(child: phase == Phase.ready ? _ready() : _board()),
                const BannerAdWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final low = phase == Phase.playing && remaining <= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            color: C.ink,
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 4),
          const AudioToggles(),
          const Spacer(),
          Pill(text: '⏱ ${remaining}s', color: low ? C.red : C.sky),
          const SizedBox(width: 8),
          Pill(text: '⭐ $stars', color: C.yellowDark),
        ],
      ),
    );
  }

  Widget _ready() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 130),
            const SizedBox(height: 8),
            const Text('Sẵn sàng chưa nào?',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.pinkDark)),
            const SizedBox(height: 6),
            Text(
              'Bạn có ${baseSeconds + (bonusUsed ? bonusSeconds : 0)} giây.\nĐúng +1 sao, sai về 0 sao!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: C.ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 26),
            CuteButton(
              label: 'BẮT ĐẦU',
              fontSize: 26,
              height: 68,
              color: C.mint,
              shadow: C.mintDark,
              onTap: _start,
            ),
            const SizedBox(height: 16),
            CuteButton(
              label: bonusUsed ? 'Đã cộng +5 giây ✓' : '🎬 Xem video: +5 giây',
              color: C.sky,
              shadow: C.skyDark,
              onTap: bonusUsed ? null : _watchBonus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _board() {
    final question = q!;
    final total = baseSeconds + (bonusUsed ? bonusSeconds : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (remaining / total).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white,
              color: remaining <= 10 ? C.red : C.mint,
            ),
          ),
          const SizedBox(height: 10),
          _ladder(),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _questionCard(question),
                  const SizedBox(height: 14),
                  for (var i = 0; i < question.options.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _answerTile(question, i),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ladder() {
    const slots = 10;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < slots; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(Icons.star_rounded,
                size: 26, color: i < stars ? C.yellow : const Color(0xFFEBDCE8)),
          ),
        if (stars > slots)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text('+${stars - slots}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w900, color: C.yellowDark)),
          ),
      ],
    );
  }

  Widget _questionCard(Question qu) {
    final diff = switch (qu.difficulty) {
      'easy' => '🌱 Dễ',
      'hard' => '💎 Khó',
      _ => '🔥 Vừa',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: C.pink, width: 3),
        boxShadow: const [BoxShadow(color: C.pinkDark, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 140,
                ),
                child: Pill(text: qu.topic, color: C.skyDark, fontSize: 13),
              ),
              Pill(text: diff, color: C.pink, fontSize: 13),
            ],
          ),
          const SizedBox(height: 12),
          Text(qu.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, color: C.ink)),
        ],
      ),
    );
  }

  Widget _answerTile(Question qu, int i) {
    var bg = Colors.white;
    var border = C.sky;
    var fg = C.ink;
    if (locked) {
      if (i == qu.correctIndex) {
        bg = C.mint;
        border = C.mintDark;
        fg = Colors.white;
      } else if (i == picked) {
        bg = C.red;
        border = C.redDark;
        fg = Colors.white;
      }
    }
    return GestureDetector(
      onTap: () => _answer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 3),
          boxShadow: [BoxShadow(color: border, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: border,
              child: Text('ABCD'[i],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(qu.options[i],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}
