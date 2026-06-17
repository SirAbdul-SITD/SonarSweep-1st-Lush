// lib/game/board_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'game_state.dart';
import '../utils/constants.dart';

class BoardPainter extends CustomPainter {
  final GameState st;
  BoardPainter(this.st);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / st.width;

    for (int r = 0; r < st.height; r++) {
      for (int c = 0; c < st.width; c++) {
        final i = r * st.width + c;
        final cellObj = st.cells[i];
        final rect = Rect.fromLTWH(
            c * cell + 1, r * cell + 1, cell - 2, cell - 2);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));

        if (!cellObj.revealed) {
          // raised sonar panel
          canvas.drawRRect(rr, Paint()..color = kCovered);
          canvas.drawLine(rect.topLeft + const Offset(2, 2),
              rect.topRight + const Offset(-2, 2),
              Paint()
                ..color = kCoveredHi
                ..strokeWidth = 2);
          canvas.drawRRect(
              rr,
              Paint()
                ..color = kBorder
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1);
          if (cellObj.flagged) _buoy(canvas, rect);
        } else {
          canvas.drawRRect(rr, Paint()..color = kRevealed);
          canvas.drawRRect(
              rr,
              Paint()
                ..color = kBorder.withOpacity(0.4)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 0.8);
          if (cellObj.isMine) {
            _mine(canvas, rect);
          } else if (cellObj.adj > 0) {
            _number(canvas, rect, cellObj.adj, cell);
          }
        }
      }
    }
  }

  void _number(Canvas canvas, Rect rect, int n, double cell) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
          color: kNumColors[n],
          fontSize: cell * 0.52,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas,
        rect.center -
            Offset(tp.width / 2, tp.height / 2));
  }

  void _mine(Canvas canvas, Rect rect) {
    final c = rect.center;
    final r = rect.width * 0.26;
    canvas.drawCircle(
        c,
        r * 1.5,
        Paint()
          ..color = kMineColor.withOpacity(0.30)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    // spikes
    final sp = Paint()
      ..color = kMineColor
      ..strokeWidth = rect.width * 0.07
      ..strokeCap = StrokeCap.round;
    for (int k = 0; k < 8; k++) {
      final a = k * pi / 4;
      canvas.drawLine(
          c + Offset(cos(a), sin(a)) * r * 0.6,
          c + Offset(cos(a), sin(a)) * r * 1.45,
          sp);
    }
    canvas.drawCircle(c, r, Paint()..color = kMineColor);
    canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.3), r * 0.25,
        Paint()..color = Colors.white.withOpacity(0.6));
  }

  void _buoy(Canvas canvas, Rect rect) {
    final c = rect.center;
    final w = rect.width;
    // pole
    canvas.drawLine(
        Offset(c.dx, c.dy - w * 0.26),
        Offset(c.dx, c.dy + w * 0.26),
        Paint()
          ..color = kTextPrimary.withOpacity(0.8)
          ..strokeWidth = w * 0.06);
    // pennant
    final path = Path()
      ..moveTo(c.dx, c.dy - w * 0.26)
      ..lineTo(c.dx + w * 0.30, c.dy - w * 0.12)
      ..lineTo(c.dx, c.dy + w * 0.02)
      ..close();
    canvas.drawPath(path, Paint()..color = kFlagColor);
    // base
    canvas.drawLine(
        Offset(c.dx - w * 0.16, c.dy + w * 0.26),
        Offset(c.dx + w * 0.16, c.dy + w * 0.26),
        Paint()
          ..color = kFlagColor
          ..strokeWidth = w * 0.08
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(BoardPainter old) => true;
}
