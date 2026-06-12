import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../shared/models/models.dart';

// ═══════════════════════════════════════════
// ──── Enhanced Map Painter ────
// ═══════════════════════════════════════════
class EnhancedMapPainter extends CustomPainter {
  final UserLocation? riderLocation;
  final OrderStatus orderStatus;

  EnhancedMapPainter({
    required this.riderLocation,
    required this.orderStatus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Abstract Map Background
    _drawAbstractMap(canvas, size);

    // 2. Points mapping
    final restaurantPoint = Offset(size.width * 0.15, size.height * 0.15);
    final customerPoint = Offset(size.width * 0.85, size.height * 0.85);

    // 3. Draw Route Base Line
    final routePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(restaurantPoint.dx, restaurantPoint.dy)
      ..cubicTo(
        size.width * 0.2, size.height * 0.5,
        size.width * 0.6, size.height * 0.5,
        customerPoint.dx, customerPoint.dy,
      );

    // Dashed effect
    final dashPath = _createDashedPath(routePath, 8, 5);
    canvas.drawPath(dashPath, routePaint);

    // Draw Restaurant marker
    _drawEnhancedMarker(canvas, restaurantPoint, const Color(0xFFE53935), '🍳', 'Restaurant');
    // Draw Customer marker
    _drawEnhancedMarker(canvas, customerPoint, const Color(0xFF43A047), '🏠', 'You');

    // Draw Rider if available
    if (riderLocation != null) {
      // The mock simulation sends progress (0 to 100) in the latitude field
      double progress = riderLocation!.latitude / 100.0;
      progress = progress.clamp(0.0, 1.0);

      final riderPoint = _getPointOnBezier(
        restaurantPoint,
        Offset(size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.6, size.height * 0.5),
        customerPoint,
        progress,
      );

      // Rider trail (colored portion of route)
      final trailPaint = Paint()
        ..color = const Color(0xFF1565C0)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      final trailPath = Path()
        ..moveTo(restaurantPoint.dx, restaurantPoint.dy)
        ..cubicTo(
          size.width * 0.2, size.height * 0.5,
          size.width * 0.6, size.height * 0.5,
          customerPoint.dx, customerPoint.dy,
        );

      // Only draw up to rider position
      final trailMetrics = trailPath.computeMetrics().first;
      final trailLength = trailMetrics.length * progress;
      if (trailLength > 0) {
        final extractedPath = trailMetrics.extractPath(0, trailLength);
        canvas.drawPath(extractedPath, trailPaint);
      }

      // Rider glow effect
      final glowPaint = Paint()
        ..color = const Color(0xFF1565C0).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(riderPoint, 20, glowPaint);

      _drawEnhancedMarker(canvas, riderPoint, const Color(0xFF1565C0), '🏍️', 'Rider');

      // Progress percentage
      final progressText = '${(progress * 100).toInt()}%';
      final progressPainter = TextPainter(textDirection: TextDirection.ltr);
      progressPainter.text = TextSpan(
        text: progressText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      );
      progressPainter.layout();
      progressPainter.paint(canvas, riderPoint + const Offset(20, -8));
    }
  }

  void _drawAbstractMap(Canvas canvas, Size size) {
    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE3F2FD), // Water-like light blue
    );

    // Draw grid/streets
    final gridPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Abstract block parks/buildings
    final blockPaint = Paint()..color = const Color(0xFFC8E6C9); // Light green parks
    canvas.drawRRect(RRect.fromLTRBR(30, 30, 120, 100, const Radius.circular(8)), blockPaint);
    canvas.drawRRect(RRect.fromLTRBR(size.width - 150, size.height - 200, size.width - 50, size.height - 100, const Radius.circular(8)), blockPaint);

    final buildingPaint = Paint()..color = const Color(0xFFEEEEEE);
    canvas.drawRRect(RRect.fromLTRBR(200, 100, 280, 220, const Radius.circular(8)), buildingPaint);
    canvas.drawRRect(RRect.fromLTRBR(80, 250, 180, 320, const Radius.circular(8)), buildingPaint);

    _drawLandmarkLabel(canvas, 'Hatirjheel Park', const Offset(40, 50));
    _drawLandmarkLabel(canvas, 'Commercial Zone', const Offset(210, 150));
    _drawLandmarkLabel(canvas, 'Residential Area', Offset(size.width - 140, size.height - 150));
  }

  void _drawLandmarkLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  void _drawEnhancedMarker(Canvas canvas, Offset pos, Color color, String emoji, String label) {
    // Shadow
    final shadowPaint = Paint()..color = color.withOpacity(0.2);
    canvas.drawCircle(pos, 24, shadowPaint);

    // Outer ring
    final outerPaint = Paint()..color = color;
    canvas.drawCircle(pos, 18, outerPaint);

    // White inner ring
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 14, innerPaint);

    // Emoji text
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(text: emoji, style: const TextStyle(fontSize: 14));
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

    // Label below marker
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(pos.dx - labelPainter.width / 2, pos.dy + 22));
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashLength, metric.length);
        dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gapLength;
      }
    }
    return dashedPath;
  }

  Offset _getPointOnBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    double x = uuu * p0.dx;
    x += 3 * uu * t * p1.dx;
    x += 3 * u * tt * p2.dx;
    x += ttt * p3.dx;

    double y = uuu * p0.dy;
    y += 3 * uu * t * p1.dy;
    y += 3 * u * tt * p2.dy;
    y += ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant EnhancedMapPainter oldDelegate) {
    return oldDelegate.riderLocation != riderLocation ||
        oldDelegate.orderStatus != orderStatus;
  }
}
