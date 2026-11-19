import 'dart:async';

import 'package:flutter/material.dart';

import '../config/quiz_modes.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/question_repository.dart';
import '../services/stats_service.dart';
import '../ui.dart';
import '../widgets/lightning_storm_overlay.dart';
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
    setState(() {});
  }

  Future<void> _play(QuizMode mode) => _open(PlayScreen(mode: mode));

  Future<void> _leaderboard() async {
    final err = await LeaderboardService.open();
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mixedBest = StatsService.instance.best;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CuteBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          color: C.ink,
                          tooltip: 'Cách chơi',
                          onPressed: () => _open(const HowToPlayScreen()),
                          icon: const Icon(Icons.help_outline_rounded),
                        ),
                        const Spacer(),
                        const AudioToggles(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                            child: Column(
                              children: [
                                TopicBrandCarousel(
                                  onTopicTap: _play,
                                ),
                                const SizedBox(height: 12),
                                _MixedHeroCard(
                                  best: mixedBest,
                                  onPlay: () => _play(QuizMode.mixed),
                                  onLeaderboard: _leaderboard,
                                ),
                                const SizedBox(height: 18),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Chơi theo chủ đề',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: C.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Sao lưu trên máy · luyện đúng sở thích',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: C.pinkDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.35,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final mode = QuizMode.topics[index];
                                return _TopicCard(
                                  mode: mode,
                                  best: StatsService.instance.bestFor(mode.id),
                                  questionCount: QuestionRepository.instance
                                      .countForTopic(mode.topicFilter),
                                  onTap: () => _play(mode),
                                );
                              },
                              childCount: QuizMode.topics.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              ),
            ),
          ),
          const LightningStormOverlay(),
        ],
      ),
    );
  }
}

/// Carousel ngang: ô brand (điểm xuất phát) + toàn bộ chủ đề, tự cuộn 3s/ô, lặp vô hạn.
class TopicBrandCarousel extends StatefulWidget {
  final ValueChanged<QuizMode>? onTopicTap;

  const TopicBrandCarousel({super.key, this.onTopicTap});

  @override
  State<TopicBrandCarousel> createState() => _TopicBrandCarouselState();
}

class _TopicBrandCarouselState extends State<TopicBrandCarousel> {
  static const _interval = Duration(seconds: 3);
  static const _anim = Duration(milliseconds: 420);

  /// slides[0] = brand; sau đó là các chủ đề.
  late final List<_CarouselSlide> _slides;
  late final PageController _pageController;
  late final int _startPage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _slides = [
      const _CarouselSlide.brand(),
      for (final m in QuizMode.topics) _CarouselSlide.topic(m),
    ];
    // Bắt đầu tại bội số lớn của độ dài → ô brand, cuộn vô hạn không giật.
    _startPage = _slides.length * 200;
    _pageController = PageController(initialPage: _startPage, viewportFraction: 0.86);
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? _startPage;
    _pageController.animateToPage(
      current + 1,
      duration: _anim,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        padEnds: true,
        itemBuilder: (context, index) {
          final slide = _slides[index % _slides.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: slide.isBrand
                ? const _BrandCarouselCard()
                : _TopicCarouselCard(
                    mode: slide.mode!,
                    onTap: widget.onTopicTap == null
                        ? null
                        : () => widget.onTopicTap!(slide.mode!),
                  ),
          );
        },
      ),
    );
  }
}

class _CarouselSlide {
  final QuizMode? mode;
  const _CarouselSlide._(this.mode);
  const _CarouselSlide.brand() : this._(null);
  const _CarouselSlide.topic(QuizMode mode) : this._(mode);
  bool get isBrand => mode == null;
}

class _BrandCarouselCard extends StatelessWidget {
  const _BrandCarouselCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.pink.withValues(alpha: 0.45), width: 2.5),
        image: const DecorationImage(
          image: AssetImage('assets/carousel/brand.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0x55FFF6E5), BlendMode.srcATop),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21.5),
        child: const ColoredBox(
          color: Color(0x66FFFFFF),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Mascot(size: 72),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chớp Chớp',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: C.pinkDark,
                    ),
                  ),
                  Text(
                    'QUIZ',
                    style: TextStyle(
                      fontSize: 18,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w900,
                      color: C.skyDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCarouselCard extends StatelessWidget {
  final QuizMode mode;
  final VoidCallback? onTap;

  const _TopicCarouselCard({required this.mode, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                AudioService.instance.tap();
                onTap!();
              },
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  mode.carouselAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(color: mode.color),
                ),
                // Làm mờ / tối nền để icon + chữ nổi.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        mode.shadow.withValues(alpha: 0.72),
                        mode.color.withValues(alpha: 0.48),
                        mode.shadow.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(mode.emoji, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MixedHeroCard extends StatelessWidget {
  final int best;
  final VoidCallback onPlay;
  final VoidCallback onLeaderboard;

  const _MixedHeroCard({
    required this.best,
    required this.onPlay,
    required this.onLeaderboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8EC8), C.pink, C.pinkDark],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: C.pinkDark, offset: Offset(0, 7), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
                child: const Text('⚡', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng hợp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mọi chủ đề · lên bảng xếp hạng',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: C.yellow, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kỷ lục bảng xếp hạng: $best ⭐',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  label: 'CHƠI NGAY',
                  filled: true,
                  onTap: onPlay,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroAction(
                  label: '🏆 Bảng XH',
                  filled: false,
                  onTap: onLeaderboard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatefulWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_HeroAction> createState() => _HeroActionState();
}

class _HeroActionState extends State<_HeroAction> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        AudioService.instance.tap();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 44,
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: widget.filled ? null : Border.all(color: Colors.white, width: 2),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.filled ? C.pinkDark : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatefulWidget {
  final QuizMode mode;
  final int best;
  final int questionCount;
  final VoidCallback onTap;

  const _TopicCard({
    required this.mode,
    required this.best,
    required this.questionCount,
    required this.onTap,
  });

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        AudioService.instance.tap();
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: mode.color.withValues(alpha: 0.55), width: 2),
          boxShadow: [
            BoxShadow(
              color: mode.shadow.withValues(alpha: 0.85),
              offset: Offset(0, _down ? 1 : 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(mode.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: mode.shadow,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.questionCount} câu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: mode.color.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: mode.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 20, color: mode.color),
                  const SizedBox(width: 1),
                  Text(
                    '${widget.best}',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: mode.shadow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
