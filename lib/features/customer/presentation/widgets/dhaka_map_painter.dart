import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/models/models.dart';

class DhakaMapPainter extends CustomPainter {
  final Order order;
  final double bounceOffset;

  static const _restaurantLat = 23.8103;
  static const _restaurantLng = 90.4125;
  static const _customerLat = 23.7461;
  static const _customerLng = 90.3742;

  DhakaMapPainter({required this.order, required this.bounceOffset});

  @override
  void paint(Canvas canvas, Size size) {
    _drawMap(canvas, size);

    final restaurantPt = _toScreen(size, _restaurantLat, _restaurantLng);
    final customerPt = _toScreen(size, _customerLat, _customerLng);

    final cp1 = Offset(
      restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.25,
      restaurantPt.dy + 40,
    );
    final cp2 = Offset(
      restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.75,
      customerPt.dy - 40,
    );

    _drawRoute(canvas, restaurantPt, cp1, cp2, customerPt, size);

    _drawMarker(
      canvas,
      restaurantPt,
      const Color(0xFFE53935),
      Icons.storefront,
      'Restaurant',
    );
    _drawMarker(canvas, customerPt, const Color(0xFF43A047), Icons.home, 'You');

    if (order.riderLocation != null) {
      final riderLat = order.riderLocation!.latitude;
      final riderLng = order.riderLocation!.longitude;

      final riderPt = _toScreen(
        size,
        riderLat.clamp(
          math.min(_restaurantLat, _customerLat),
          math.max(_restaurantLat, _customerLat),
        ),
        riderLng.clamp(
          math.min(_restaurantLng, _customerLng),
          math.max(_restaurantLng, _customerLng),
        ),
      );

      final bouncedRider = Offset(riderPt.dx, riderPt.dy + bounceOffset);
      _drawRiderMarker(canvas, bouncedRider);
    }
  }

  Offset _toScreen(Size size, double lat, double lng) {
    const minLat = 23.70;
    const maxLat = 23.85;
    const minLng = 90.35;
    const maxLng = 90.45;

    final x = (lng - minLng) / (maxLng - minLng) * size.width;
    final y = (1 - (lat - minLat) / (maxLat - minLat)) * size.height;
    return Offset(x, y);
  }

  void _drawMap(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F4F8),
    );

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    for (double i = -size.width; i < size.width * 2; i += size.width / 8) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        minorRoadPaint,
      );
    }

    final parkPaint = Paint()..color = const Color(0xFFDDF0E1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.2, 100, 80),
        const Radius.circular(20),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.6, size.height * 0.7, 120, 100),
        const Radius.circular(20),
      ),
      parkPaint,
    );
  }

  void _drawRoute(
    Canvas canvas,
    Offset start,
    Offset cp1,
    Offset cp2,
    Offset end,
    Size size,
  ) {
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.teal.shade100
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final innerPaint = Paint()
      ..color = Colors.teal.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashedPath = _dashPath(path, 10, 8);
    canvas.drawPath(dashedPath, innerPaint);

    if (order.status == OrderStatus.outForDelivery &&
        order.riderLocation != null) {
      final progress = _getProgress();
      if (progress > 0) {
        final metrics = path.computeMetrics().first;
        final trailLen = metrics.length * progress;
        final trailPath = metrics.extractPath(0, trailLen);
        final trailPaint = Paint()
          ..color = Colors.blue.shade500
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
        canvas.drawPath(trailPath, trailPaint);
      }
    }
  }

  double _getProgress() {
    if (order.riderLocation == null) return 0;
    final rLat = order.riderLocation!.latitude;
    final rLng = order.riderLocation!.longitude;
    final totalDist = _dist(
      _restaurantLat,
      _restaurantLng,
      _customerLat,
      _customerLng,
    );
    final remaining = _dist(rLat, rLng, _customerLat, _customerLng);
    return ((totalDist - remaining) / totalDist).clamp(0.0, 1.0);
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    return math.sqrt(math.pow(lat2 - lat1, 2) + math.pow(lng2 - lng1, 2));
  }

  Path _dashPath(Path source, double dashLen, double gapLen) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final end = math.min(d + dashLen, metric.length);
        result.addPath(metric.extractPath(d, end), Offset.zero);
        d = end + gapLen;
      }
    }
    return result;
  }

  void _drawMarker(
    Canvas canvas,
    Offset pos,
    Color color,
    IconData icon,
    String label,
  ) {
    canvas.drawCircle(
      pos,
      26,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    final pinPath = Path()..addOval(Rect.fromCircle(center: pos, radius: 20));
    canvas.drawPath(pinPath, Paint()..color = color);
    canvas.drawCircle(
      pos,
      20,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(pos, 14, Paint()..color = Colors.white);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 14,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    final lp = TextPainter(textDirection: TextDirection.ltr);
    lp.text = TextSpan(
      text: label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
    );
    lp.layout();

    canvas.drawRRect(
      RRect.fromLTRBR(
        pos.dx - lp.width / 2 - 6,
        pos.dy + 24,
        pos.dx + lp.width / 2 + 6,
        pos.dy + 38,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    lp.paint(canvas, Offset(pos.dx - lp.width / 2, pos.dy + 26));
  }

  void _drawRiderMarker(Canvas canvas, Offset pos) {
    canvas.drawCircle(
      pos,
      28,
      Paint()
        ..color = Colors.blue.shade400.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(pos, 22, Paint()..color = Colors.blue.shade600);
    canvas.drawCircle(
      pos,
      22,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(pos, 16, Paint()..color = Colors.white);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(Icons.motorcycle.codePoint),
      style: TextStyle(
        fontSize: 16,
        fontFamily: Icons.motorcycle.fontFamily,
        package: Icons.motorcycle.fontPackage,
        color: Colors.blue.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));

    const label = 'Rider';
    final lp = TextPainter(textDirection: TextDirection.ltr);
    lp.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 10,
        color: Colors.blue.shade700,
        fontWeight: FontWeight.bold,
      ),
    );
    lp.layout();
    canvas.drawRRect(
      RRect.fromLTRBR(
        pos.dx - lp.width / 2 - 6,
        pos.dy + 26,
        pos.dx + lp.width / 2 + 6,
        pos.dy + 40,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    lp.paint(canvas, Offset(pos.dx - lp.width / 2, pos.dy + 28));
  }

  @override
  bool shouldRepaint(covariant DhakaMapPainter old) =>
      old.order != order || old.bounceOffset != bounceOffset;
}
