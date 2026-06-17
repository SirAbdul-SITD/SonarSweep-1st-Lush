// lib/screens/home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/preferences.dart';
import 'level_select_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = Preferences.instance.getCompletedCount();
    final totalStars = Preferences.instance.getTotalStars();

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _SonarPainter(_ctrl.value),
          ),
        ),
        SafeArea(
          child: Column(children: [
            const Spacer(flex: 2),
            // sonar dish emblem
            SizedBox(
              width: 130,
              height: 110,
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _EmblemPainter(_ctrl.value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('SONARSWEEP',
                style: techno(38,
                    color: kAccent, weight: FontWeight.w900, letterSpacing: 7)),
            const SizedBox(height: 8),
            Text('SCAN  ·  DEDUCE  ·  DEFUSE',
                style: techno(12, color: kTextDim, letterSpacing: 4)),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _chip(Icons.check_circle_outline, '$completed / $kTotalLevels',
                  kEasyColor),
              const SizedBox(width: 14),
              _chip(Icons.star, '$totalStars', kStarOn),
            ]),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Column(children: [
                _btn('PLAY', Icons.play_arrow_rounded, true, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const LevelSelectScreen()));
                }),
                const SizedBox(height: 14),
                _btn('SETTINGS', Icons.tune_rounded, false, () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SettingsScreen()));
                }),
              ]),
            ),
            const SizedBox(height: 56),
          ]),
        ),
      ]),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: techno(13)),
        ]),
      );

  Widget _btn(String label, IconData icon, bool primary, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    colors: [Color(0xFF128F66), Color(0xFF1FBF8A)])
                : null,
            color: primary ? null : kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: primary ? kAccent.withOpacity(0.7) : kBorder,
                width: primary ? 1.5 : 1),
            boxShadow: primary
                ? [BoxShadow(color: kAccent.withOpacity(0.3), blurRadius: 22)]
                : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: primary ? kBg : kTextDim, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: techno(15,
                    color: primary ? kBg : kTextDim, letterSpacing: 3)),
          ]),
        ),
      );
}

/// Expanding sonar ping rings across the background
class _SonarPainter extends CustomPainter {
  final double t;
  _SonarPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.34);
    for (int k = 0; k < 3; k++) {
      final phase = ((t + k / 3) % 1.0);
      final r = phase * size.width * 0.85;
      canvas.drawCircle(
          center,
          r,
          Paint()
            ..color = kAccent.withOpacity(0.16 * (1 - phase))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    // depth lines
    final lp = Paint()..color = kBorder.withOpacity(0.25);
    for (double y = 60; y < size.height; y += 90) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lp);
    }
  }

  @override
  bool shouldRepaint(_SonarPainter o) => o.t != t;
}

/// Rotating sonar dish with sweep beam
class _EmblemPainter extends CustomPainter {
  final double t;
  _EmblemPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = kAccent.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(
        c,
        r * 0.62,
        Paint()
          ..color = kAccent.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    // sweep beam
    final a = t * 2 * pi;
    final sweep = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: a,
        endAngle: a + pi / 2,
        colors: [kAccent.withOpacity(0.45), kAccent.withOpacity(0)],
        transform: GradientRotation(a),
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, sweep);
    canvas.drawLine(
        c,
        c + Offset(cos(a), sin(a)) * r,
        Paint()
          ..color = kAccent
          ..strokeWidth = 2);
    // blip
    canvas.drawCircle(c + Offset(cos(a + 0.9), sin(a + 0.9)) * r * 0.5, 4,
        Paint()..color = kFlagColor);
    canvas.drawCircle(c, 4, Paint()..color = kAccent);
  }

  @override
  bool shouldRepaint(_EmblemPainter o) => o.t != t;
}
