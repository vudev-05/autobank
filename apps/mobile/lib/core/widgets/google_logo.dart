import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = w / 2;
    final Offset center = Offset(w / 2, h / 2);
    final double strokeWidth = w * 0.22;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Red (Top): ~215 deg to ~335 deg
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.1, 1.7, false, paint);

    // Yellow (Bottom-left): ~135 deg to ~215 deg
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.3, 1.9, false, paint);

    // Green (Bottom): ~45 deg to ~135 deg
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.6, 1.7, false, paint);

    // Blue (Right arc + horizontal bar): ~335 deg to ~45 deg
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.4, 1.0, false, paint);

    // Horizontal bar of "G"
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(w * 0.45, h * 0.38, w * 0.95, h * 0.62),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
