import 'package:flutter/material.dart';

/// Premium scan overlay: dimmed backdrop, transparent scan window with
/// glowing corner brackets and an animated laser line sweeping vertically.
class ScanOverlay extends StatefulWidget {
  final double windowSize;
  const ScanOverlay({super.key, this.windowSize = 260});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _OverlayPainter(
          progress: _ctrl.value,
          accent: accent,
          windowSize: widget.windowSize,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double progress;
  final Color accent;
  final double windowSize;

  _OverlayPainter({
    required this.progress,
    required this.accent,
    required this.windowSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: windowSize, height: windowSize);

    // Dim everything outside the window.
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, dim);
    canvas.drawRect(rect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Subtle inner glow border.
    canvas.drawRect(
      rect,
      Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Glowing corner brackets.
    const bracketLen = 34.0;
    const bracketWidth = 6.0;
    final glow = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final solid = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = bracketWidth
      ..strokeCap = StrokeCap.round;

    final corners = [
      (rect.topLeft, 1, 1),
      (rect.topRight, -1, 1),
      (rect.bottomLeft, 1, -1),
      (rect.bottomRight, -1, -1),
    ];
    for (final (point, dx, dy) in corners) {
      for (final paint in [glow, solid]) {
        final hPath = Path()
          ..moveTo(point.dx, point.dy + dy * bracketLen)
          ..lineTo(point.dx, point.dy)
          ..lineTo(point.dx + dx * bracketLen, point.dy);
        canvas.drawPath(hPath, paint);
      }
    }

    // Animated laser line with gradient + glow dot.
    final laserY = rect.top + 12 + progress * (windowSize - 24);
    final laserGlow = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.0),
          accent,
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(rect.left, laserY - 2, windowSize, 4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(Rect.fromLTWH(rect.left + 8, laserY - 3, windowSize - 16, 6), laserGlow);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 8, laserY - 1, windowSize - 16, 2),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );

    // Faint scan grid shimmer inside the window.
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.05 + 0.04 * progress)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final x = rect.left + (windowSize / 6) * i;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.progress != progress || old.accent != accent;
}
