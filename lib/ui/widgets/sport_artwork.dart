import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/sports.dart';

class SportArtwork extends StatelessWidget {
  const SportArtwork({
    super.key,
    required this.style,
    required this.seed,
    this.child,
    this.iconSize = 150,
    this.showIcon = true,
  });

  final SportStyle style;
  final int seed;
  final Widget? child;
  final double iconSize;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [style.colors.first, style.colors.last],
              ),
            ),
          ),
          CustomPaint(painter: _SportPatternPainter(seed: seed)),
          if (showIcon)
            Positioned(
              right: -iconSize * 0.12,
              bottom: -iconSize * 0.16,
              child: IgnorePointer(
                child: Icon(
                  style.icon,
                  size: iconSize,
                  color: const Color(0x24FFFFFF),
                ),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _SportPatternPainter extends CustomPainter {
  const _SportPatternPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x14FFFFFF);
    final strong = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x22FFFFFF);

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final center = Offset(size.width * 0.28, size.height * 0.82);
    final radius = size.shortestSide * 0.42;
    canvas.drawCircle(center, radius, line);
    canvas.drawCircle(center, radius * 0.54, line);
    canvas.drawCircle(center, radius * 0.08, strong);

    final diagonal = Path();
    for (var i = -2; i < 8; i++) {
      final offset = i * size.width * 0.16 + random.nextDouble() * 20;
      diagonal
        ..moveTo(offset, size.height + 20)
        ..lineTo(offset + size.height * 0.9, -20);
    }
    canvas.drawPath(diagonal, line);

    final arcRect = Rect.fromCenter(
      center: Offset(size.width * 0.90, size.height * 0.12),
      width: size.width * 0.86,
      height: size.width * 0.86,
    );
    canvas.drawArc(arcRect, math.pi * 0.72, math.pi * 0.46, false, strong);
    canvas.drawArc(
      arcRect.inflate(-size.width * 0.1),
      math.pi * 0.76,
      math.pi * 0.4,
      false,
      line,
    );

    final dot = Paint()..color = const Color(0x1FFFFFFF);
    for (var i = 0; i < 14; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 1.6 + 0.4, dot);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SportPatternPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
