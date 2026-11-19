import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/audio_service.dart';

/// Hiệu ứng tia sét full màn hình: tối nền, nhiều tia random, flash sáng, âm thanh nhẹ.
/// Không chặn tương tác ([IgnorePointer]). Chỉ chạy khi route đang hiện.
class LightningStormOverlay extends StatefulWidget {
  const LightningStormOverlay({super.key});

  @override
  State<LightningStormOverlay> createState() => _LightningStormOverlayState();
}

class _LightningStormOverlayState extends State<LightningStormOverlay>
    with SingleTickerProviderStateMixin {
  static const _stormDuration = Duration(milliseconds: 1450);

  final _rand = Random();
  late final AnimationController _ctrl;
  Timer? _loop;
  List<_Bolt> _bolts = const [];
  int _seed = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _stormDuration)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    // Lần đầu sau vài giây, rồi lặp ~12–18s (hợp lý, không làm phiền).
    _loop = Timer(const Duration(seconds: 4), _runCycle);
  }

  void _runCycle() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      _triggerStorm();
    }
    final wait = Duration(seconds: 12 + _rand.nextInt(7));
    _loop = Timer(wait, _runCycle);
  }

  void _triggerStorm() {
    _bolts = _spawnBolts();
    _seed = _rand.nextInt(1 << 30);
    _ctrl.forward(from: 0);
    AudioService.instance.lightning();
  }

  List<_Bolt> _spawnBolts() {
    final count = 2 + _rand.nextInt(4); // 2–5 tia
    return [
      for (var i = 0; i < count; i++)
        _Bolt.generate(
          _rand,
          delay: i * (0.04 + _rand.nextDouble() * 0.08),
          main: i == 0,
        ),
    ];
  }

  @override
  void dispose() {
    _loop?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    if (t == 0 && !_ctrl.isAnimating) {
      return const IgnorePointer(child: SizedBox.expand());
    }

    // Tối nền: lên nhanh rồi hạ dần.
    final dark = _envelope(t, peak: 0.18, hold: 0.42, end: 1.0, max: 0.55);
    // Flash sáng toàn màn (nhấp nháy 2–3 nhịp).
    final flash = _flashPulse(t);

    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _StormPainter(
            bolts: _bolts,
            t: t,
            dark: dark,
            flash: flash,
            seed: _seed,
          ),
        ),
      ),
    );
  }

  static double _envelope(
    double t, {
    required double peak,
    required double hold,
    required double end,
    required double max,
  }) {
    if (t <= peak) return max * (t / peak);
    if (t <= hold) return max;
    if (t >= end) return 0;
    return max * (1 - (t - hold) / (end - hold));
  }

  static double _flashPulse(double t) {
    // Các đỉnh flash ngắn.
    double pulse(double center, double width, double amp) {
      final d = (t - center).abs();
      if (d >= width) return 0;
      return amp * (1 - d / width);
    }

    return (pulse(0.16, 0.045, 0.55) +
            pulse(0.28, 0.035, 0.85) +
            pulse(0.40, 0.04, 0.35) +
            pulse(0.52, 0.03, 0.2))
        .clamp(0.0, 1.0);
  }
}

class _Bolt {
  final List<Offset> trunk; // toạ độ chuẩn hoá 0–1
  final List<List<Offset>> branches;
  final double width;
  final double delay;
  final double intensity;

  const _Bolt({
    required this.trunk,
    required this.branches,
    required this.width,
    required this.delay,
    required this.intensity,
  });

  factory _Bolt.generate(Random r, {required double delay, required bool main}) {
    final startX = 0.08 + r.nextDouble() * 0.84;
    final endY = 0.42 + r.nextDouble() * 0.55;
    final segments = main ? 8 + r.nextInt(6) : 5 + r.nextInt(5);
    final jagged = 0.035 + r.nextDouble() * 0.07;
    final trunk = <Offset>[Offset(startX, -0.02)];
    var x = startX;
    for (var i = 1; i <= segments; i++) {
      final y = endY * (i / segments);
      x += (r.nextDouble() - 0.5) * jagged * 2.2;
      x = x.clamp(0.02, 0.98);
      // lệch nhẹ về một phía để hình dạng đa dạng
      x += (r.nextDouble() - 0.5) * jagged * 0.4;
      trunk.add(Offset(x.clamp(0.02, 0.98), y));
    }

    final branches = <List<Offset>>[];
    final branchCount = main ? 1 + r.nextInt(3) : r.nextInt(2);
    for (var b = 0; b < branchCount; b++) {
      if (trunk.length < 4) break;
      final from = 2 + r.nextInt(trunk.length - 3);
      final origin = trunk[from];
      final len = 3 + r.nextInt(4);
      final dir = r.nextBool() ? 1.0 : -1.0;
      final branch = <Offset>[origin];
      var bx = origin.dx;
      var by = origin.dy;
      for (var i = 0; i < len; i++) {
        bx += dir * (0.03 + r.nextDouble() * 0.06);
        by += 0.04 + r.nextDouble() * 0.07;
        branch.add(Offset(bx.clamp(0.0, 1.0), by.clamp(0.0, 1.05)));
      }
      branches.add(branch);
    }

    return _Bolt(
      trunk: trunk,
      branches: branches,
      width: main ? 2.8 + r.nextDouble() * 1.6 : 1.6 + r.nextDouble() * 1.2,
      delay: delay,
      intensity: main ? 1 : 0.55 + r.nextDouble() * 0.35,
    );
  }
}

class _StormPainter extends CustomPainter {
  final List<_Bolt> bolts;
  final double t;
  final double dark;
  final double flash;
  final int seed;

  _StormPainter({
    required this.bolts,
    required this.t,
    required this.dark,
    required this.flash,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dark <= 0.01 && flash <= 0.01) return;

    // Nền tối
    if (dark > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: dark),
      );
    }

    for (final bolt in bolts) {
      final local = ((t - bolt.delay) / 0.55).clamp(0.0, 1.0);
      if (local <= 0) continue;
      // Tia hiện nhanh, nhấp, rồi mờ
      final visible = local < 0.15
          ? local / 0.15
          : local < 0.55
              ? 1.0
              : (1 - (local - 0.55) / 0.45).clamp(0.0, 1.0);
      final flicker = 0.75 + 0.25 * sin((t + bolt.delay) * 55);
      final alpha = (visible * bolt.intensity * flicker * (0.65 + 0.35 * flash))
          .clamp(0.0, 1.0);
      if (alpha < 0.02) continue;
      _drawBolt(canvas, size, bolt, alpha);
    }

    // Flash sáng toàn khung + vệt sáng từ trên xuống
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFEAF4FF).withValues(alpha: flash * 0.5),
      );
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(size.width * 0.5, 0),
            size.height * 0.6,
            [
              Color.fromRGBO(255, 255, 255, flash * 0.45),
              const Color(0x00BFD9FF),
            ],
          ),
      );
    }
  }

  void _drawBolt(Canvas canvas, Size size, _Bolt bolt, double alpha) {
    Path toPath(List<Offset> pts) {
      final p = Path();
      for (var i = 0; i < pts.length; i++) {
        final o = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
        if (i == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
      return p;
    }

    void stroke(Path path, double width, Color color) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    }

    final trunk = toPath(bolt.trunk);
    final w = bolt.width;

    // Hào quang
    stroke(trunk, w * 7, const Color(0xFF7EB6FF).withValues(alpha: alpha * 0.22));
    stroke(trunk, w * 3.2, const Color(0xFFBFDFFF).withValues(alpha: alpha * 0.45));
    // Lõi sáng
    stroke(trunk, w * 1.15, Colors.white.withValues(alpha: alpha));
    stroke(trunk, w * 0.45, const Color(0xFFFFF8E7).withValues(alpha: alpha));

    for (final branch in bolt.branches) {
      final bp = toPath(branch);
      stroke(bp, w * 3.5, const Color(0xFF9EC8FF).withValues(alpha: alpha * 0.28));
      stroke(bp, w * 0.9, Colors.white.withValues(alpha: alpha * 0.85));
    }
  }

  @override
  bool shouldRepaint(covariant _StormPainter old) =>
      old.t != t || old.dark != dark || old.flash != flash || old.seed != seed;
}
