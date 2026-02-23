import 'dart:ui';

import 'package:flutter/material.dart';

class PatternEditorCanvas extends StatelessWidget {
  const PatternEditorCanvas({
    super.key,
    required this.points,
    required this.paths,
    required this.onTap,
  });

  final List<Offset> points;
  final List<List<int>> paths;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) => onTap(details.localPosition),
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 8,
        child: CustomPaint(
          size: const Size(1200, 1600),
          painter: _PatternPainter(points: points, paths: paths),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter({required this.points, required this.paths});

  final List<Offset> points;
  final List<List<int>> paths;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF9EFEA);
    canvas.drawRect(Offset.zero & size, bg);

    final linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final path in paths) {
      if (path.length < 2) continue;
      final p = Path()..moveTo(points[path.first].dx, points[path.first].dy);
      for (var i = 1; i < path.length; i++) {
        final point = points[path[i]];
        p.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(p, linePaint);
    }

    final pointPaint = Paint()..color = Colors.pink;
    for (final point in points) {
      canvas.drawCircle(point, 6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.paths != paths;
  }
}
