import 'package:flutter/material.dart';

import 'services/audio_service.dart';
import 'services/stats_service.dart';

/// Bảng màu pastel dễ thương.
class C {
  static const cream = Color(0xFFFFF6E5);
  static const blush = Color(0xFFFFDDEE);
  static const pink = Color(0xFFFF7EB6);
  static const pinkDark = Color(0xFFE0558F);
  static const yellow = Color(0xFFFFD84D);
  static const yellowDark = Color(0xFFE0B100);
  static const mint = Color(0xFF63DDB4);
  static const mintDark = Color(0xFF2FB38A);
  static const sky = Color(0xFF72C8FF);
  static const skyDark = Color(0xFF3A9BE0);
  static const red = Color(0xFFFF6B6B);
  static const redDark = Color(0xFFD94848);
  static const ink = Color(0xFF5B3A5E);
}

class CuteBackground extends StatelessWidget {
  final Widget child;
  const CuteBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.cream, C.blush],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: 70, left: 24, child: _Deco('✨', 28)),
          const Positioned(top: 140, right: 30, child: _Deco('💡', 24)),
          const Positioned(bottom: 160, left: 40, child: _Deco('⚡', 36)),
          const Positioned(bottom: 230, right: 20, child: _Deco('✨', 22)),
          child,
        ],
      ),
    );
  }
}

class _Deco extends StatelessWidget {
  final String emoji;
  final double size;
  const _Deco(this.emoji, this.size);

  @override
  Widget build(BuildContext context) =>
      Opacity(opacity: .5, child: Text(emoji, style: TextStyle(fontSize: size)));
}

/// Nút 3D bo tròn, nhấn sẽ lún xuống.
class CuteButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color shadow;
  final double fontSize;
  final double height;

  const CuteButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = C.pink,
    this.shadow = C.pinkDark,
    this.fontSize = 20,
    this.height = 58,
  });

  @override
  State<CuteButton> createState() => _CuteButtonState();
}

class _CuteButtonState extends State<CuteButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                AudioService.instance.tap();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: widget.height,
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: widget.shadow, offset: Offset(0, _down ? 2 : 6)),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút nhạc / hiệu ứng trên góc màn hình.
class AudioToggles extends StatefulWidget {
  const AudioToggles({super.key});

  @override
  State<AudioToggles> createState() => _AudioTogglesState();
}

class _AudioTogglesState extends State<AudioToggles> {
  @override
  Widget build(BuildContext context) {
    final sound = StatsService.instance.soundOn;
    final music = StatsService.instance.musicOn;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          color: C.ink,
          tooltip: sound ? 'Tắt hiệu ứng' : 'Bật hiệu ứng',
          onPressed: () async {
            await AudioService.instance.setSoundEnabled(!sound);
            if (mounted) setState(() {});
          },
          icon: Icon(sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
        ),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          color: C.ink,
          tooltip: music ? 'Tắt nhạc' : 'Bật nhạc',
          onPressed: () async {
            await AudioService.instance.setMusicEnabled(!music);
            if (mounted) setState(() {});
          },
          icon: Icon(music ? Icons.music_note_rounded : Icons.music_off_rounded),
        ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  const Pill({super.key, required this.text, required this.color, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Linh vật: tia chớp trí tuệ — bolt hình học, hào quang ý tưởng, không mặt cười.
class Mascot extends StatefulWidget {
  final double size;
  final bool animate;
  const Mascot({super.key, this.size = 140, this.animate = true});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    value: widget.animate ? 0 : 0.45,
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.animate ? 0 : 0.7,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _float.repeat(reverse: true);
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: Listenable.merge([_float, _pulse]),
      builder: (_, __) {
        final bob = -7 * Curves.easeInOut.transform(_float.value);
        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: s,
            height: s,
            child: CustomPaint(
              painter: _WisdomBoltPainter(pulse: _pulse.value),
            ),
          ),
        );
      },
    );
  }
}

class _WisdomBoltPainter extends CustomPainter {
  final double pulse;
  const _WisdomBoltPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glow = 0.55 + 0.45 * pulse;

    final bolt = Path()
      ..moveTo(w * 0.58, h * 0.04)
      ..lineTo(w * 0.26, h * 0.42)
      ..lineTo(w * 0.48, h * 0.42)
      ..lineTo(w * 0.32, h * 0.96)
      ..lineTo(w * 0.78, h * 0.48)
      ..lineTo(w * 0.54, h * 0.48)
      ..close();

    canvas.drawPath(
      bolt.shift(const Offset(0, 6)),
      Paint()..color = C.yellowDark.withValues(alpha: 0.28),
    );

    canvas.drawCircle(
      Offset(w * 0.52, h * 0.38),
      w * 0.34 * glow,
      Paint()..color = C.yellow.withValues(alpha: 0.18 * glow),
    );

    canvas.drawPath(
      bolt,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.fill,
    );

    final inner = Path()
      ..moveTo(w * 0.56, h * 0.10)
      ..lineTo(w * 0.34, h * 0.40)
      ..lineTo(w * 0.48, h * 0.40)
      ..lineTo(w * 0.40, h * 0.78)
      ..lineTo(w * 0.68, h * 0.48)
      ..lineTo(w * 0.52, h * 0.48)
      ..close();
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFFF6C2), C.yellow.withValues(alpha: 0.15)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      bolt,
      Paint()
        ..color = C.yellowDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.045).clamp(2.5, 5)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Hào quang ý tưởng quanh đỉnh tia.
    final haloCenter = Offset(w * 0.52, h * 0.22);
    canvas.drawCircle(
      haloCenter,
      w * 0.20,
      Paint()
        ..color = C.sky.withValues(alpha: 0.18 + 0.12 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      haloCenter,
      w * 0.14 + w * 0.02 * pulse,
      Paint()
        ..color = C.sky.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Mạng nơ-ron nhỏ — “trí tuệ”.
    final n1 = Offset(w * 0.78, h * 0.18);
    final n2 = Offset(w * 0.90, h * 0.30);
    final n3 = Offset(w * 0.76, h * 0.34);
    final nodePaint = Paint()
      ..color = C.skyDark
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(n1, n2, nodePaint);
    canvas.drawLine(n2, n3, nodePaint);
    canvas.drawLine(n3, n1, nodePaint);
    for (final n in [n1, n2, n3]) {
      canvas.drawCircle(n, 3.4, Paint()..color = Colors.white);
      canvas.drawCircle(n, 2.4, Paint()..color = C.sky);
    }

    // Tia sáng ở lõi.
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.40),
      4.5 + 1.5 * pulse,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );

    _spark(canvas, Offset(w * 0.18, h * 0.16), 5 + 1.5 * pulse, C.pink);
    _spark(canvas, Offset(w * 0.86, h * 0.58), 4 + pulse, C.sky);
    _spark(canvas, Offset(w * 0.22, h * 0.72), 3.5, C.yellow);
  }

  void _spark(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(0, -r), c.translate(0, r), p);
    canvas.drawLine(c.translate(-r, 0), c.translate(r, 0), p);
    canvas.drawLine(c.translate(-r * 0.7, -r * 0.7), c.translate(r * 0.7, r * 0.7), p);
    canvas.drawLine(c.translate(-r * 0.7, r * 0.7), c.translate(r * 0.7, -r * 0.7), p);
  }

  @override
  bool shouldRepaint(covariant _WisdomBoltPainter oldDelegate) => oldDelegate.pulse != pulse;
}
