import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../bloc/customer_bloc.dart';

// ═══════════════════════════════════════════
// ──── Live Tracking Screen ────
// ═══════════════════════════════════════════
class CustomerTrackingScreen extends StatefulWidget {
  const CustomerTrackingScreen({super.key});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _riderBounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _riderBounceAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _riderBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _riderBounceAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _riderBounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _riderBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          final order = state.activeOrder;
          if (order == null) {
            return const Center(child: Text('No active order'));
          }

          return Column(
            children: [
              // ─── Map Section ───
              Expanded(
                flex: 6,
                child: _buildMapSection(order),
              ),

              // ─── Info Panel ───
              Expanded(
                flex: 5,
                child: _buildInfoPanel(context, order),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapSection(Order order) {
    return Stack(
      children: [
        // Custom drawn map
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _riderBounceAnimation,
            builder: (context, _) {
              return CustomPaint(
                painter: _DhakaMapPainter(
                  order: order,
                  bounceOffset: _riderBounceAnimation.value,
                ),
              );
            },
          ),
        ),

        // Top gradient overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: GestureDetector(
            onTap: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
        ),

        // Status chip (top center)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: order.status == OrderStatus.outForDelivery
                      ? _pulseAnimation.value
                      : 1.0,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(order.status).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(order.status), color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      order.status.displayValue,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ETA chip (bottom right of map)
        if (order.status == OrderStatus.outForDelivery)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ETA', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Text(
                    _getETA(order),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoPanel(BuildContext context, Order order) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Order progress steps
            _buildOrderProgressSteps(order),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Rider info
            if (order.status.index >= OrderStatus.outForDelivery.index)
              _buildRiderCard(order),

            if (order.status.index >= OrderStatus.outForDelivery.index)
              const SizedBox(height: 16),

            // Delivery address
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home, color: Colors.green.shade600, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Order amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        '৳${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Items', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        '${order.items.fold(0, (s, i) => s + i.quantity)} pcs',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (order.status == OrderStatus.delivered || order.status == OrderStatus.rejected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderProgressSteps(Order order) {
    final steps = [
      _StepInfo(OrderStatus.pending, 'Order Placed', Icons.receipt_long),
      _StepInfo(OrderStatus.accepted, 'Confirmed', Icons.check_circle_outline),
      _StepInfo(OrderStatus.preparing, 'Preparing', Icons.restaurant),
      _StepInfo(OrderStatus.readyForPickup, 'Ready', Icons.shopping_bag_outlined),
      _StepInfo(OrderStatus.outForDelivery, 'On the Way', Icons.motorcycle),
      _StepInfo(OrderStatus.delivered, 'Delivered', Icons.home),
    ];

    if (order.status == OrderStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text('Order was rejected by restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = order.status.index >= step.status.index;
        final isCurrent = order.status == step.status;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 36 : 28,
                      height: isCurrent ? 36 : 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? _getStatusColor(step.status)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [BoxShadow(
                                color: _getStatusColor(step.status).withOpacity(0.4),
                                blurRadius: 8,
                              )]
                            : null,
                      ),
                      child: Icon(
                        step.icon,
                        size: isCurrent ? 18 : 14,
                        color: isCompleted ? Colors.white : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppTheme.primary : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    color: order.status.index > steps[index].status.index
                        ? AppTheme.primary
                        : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.motorcycle, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Rider', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  order.riderName ?? 'Searching...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (order.riderLocation != null)
                  Text(
                    'Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                  ),
              ],
            ),
          ),
          if (order.riderName != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
              ),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling rider...')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _getETA(Order order) {
    if (order.riderLocation == null) return '~15 min';
    // Calculate rough ETA based on distance remaining
    final destLat = 23.7461;
    final destLng = 90.3742;
    final riderLat = order.riderLocation!.latitude;
    final riderLng = order.riderLocation!.longitude;
    final distKm = _haversineDistance(riderLat, riderLng, destLat, destLng);
    final minutes = (distKm / 0.5).round(); // ~30kmh in city traffic
    return '~$minutes min';
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.preparing: return Colors.amber.shade700;
      case OrderStatus.readyForPickup: return Colors.teal;
      case OrderStatus.outForDelivery: return Colors.indigo;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.rejected: return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.hourglass_top;
      case OrderStatus.accepted: return Icons.check_circle;
      case OrderStatus.preparing: return Icons.restaurant;
      case OrderStatus.readyForPickup: return Icons.shopping_bag;
      case OrderStatus.outForDelivery: return Icons.motorcycle;
      case OrderStatus.delivered: return Icons.home;
      case OrderStatus.rejected: return Icons.cancel;
    }
  }
}

class _StepInfo {
  final OrderStatus status;
  final String label;
  final IconData icon;
  const _StepInfo(this.status, this.label, this.icon);
}

// ─── Custom Map Painter (Dhaka Style) ───
class _DhakaMapPainter extends CustomPainter {
  final Order order;
  final double bounceOffset;

  // Fixed Dhaka coordinates mapped to screen
  static const _restaurantLat = 23.8103;
  static const _restaurantLng = 90.4125;
  static const _customerLat = 23.7461;
  static const _customerLng = 90.3742;

  _DhakaMapPainter({required this.order, required this.bounceOffset});

  @override
  void paint(Canvas canvas, Size size) {
    _drawMap(canvas, size);
    
    final restaurantPt = _toScreen(size, _restaurantLat, _restaurantLng);
    final customerPt = _toScreen(size, _customerLat, _customerLng);
    
    // Control points for bezier curve
    final cp1 = Offset(restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.25,
                       restaurantPt.dy + 40);
    final cp2 = Offset(restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.75,
                       customerPt.dy - 40);

    _drawRoute(canvas, restaurantPt, cp1, cp2, customerPt, size);
    
    // Draw markers
    _drawMarker(canvas, restaurantPt, const Color(0xFFE53935), Icons.storefront, 'Restaurant');
    _drawMarker(canvas, customerPt, const Color(0xFF43A047), Icons.home, 'You');

    // Draw rider
    if (order.riderLocation != null) {
      final riderLat = order.riderLocation!.latitude;
      final riderLng = order.riderLocation!.longitude;
      
      // Clamp rider position between restaurant and customer
      final riderPt = _toScreen(size, 
        riderLat.clamp(math.min(_restaurantLat, _customerLat), math.max(_restaurantLat, _customerLat)),
        riderLng.clamp(math.min(_restaurantLng, _customerLng), math.max(_restaurantLng, _customerLng)),
      );
      
      final bouncedRider = Offset(riderPt.dx, riderPt.dy + bounceOffset);
      _drawRiderMarker(canvas, bouncedRider);
    }
  }

  Offset _toScreen(Size size, double lat, double lng) {
    // Map lat/lng range to screen coordinates
    const minLat = 23.70;
    const maxLat = 23.85;
    const minLng = 90.35;
    const maxLng = 90.45;
    
    final x = (lng - minLng) / (maxLng - minLng) * size.width;
    final y = (1 - (lat - minLat) / (maxLat - minLat)) * size.height;
    return Offset(x, y);
  }

  void _drawMap(Canvas canvas, Size size) {
    // Sky-like background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8F4F8),
    );

    // Draw grid roads
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minorRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Main roads
    for (double x = 0; x < size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    // Minor roads
    for (double x = size.width / 10; x < size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // City blocks (buildings)
    final blockColors = [
      const Color(0xFFD1E8C4), // parks
      const Color(0xFFE8DCC4), // buildings
      const Color(0xFFCCD4E0), // commercial
    ];

    final rng = math.Random(42);
    for (int i = 0; i < 25; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 30.0 + rng.nextDouble() * 50;
      final h = 20.0 + rng.nextDouble() * 40;
      canvas.drawRRect(
        RRect.fromLTRBR(x, y, x + w, y + h, const Radius.circular(4)),
        Paint()..color = blockColors[i % 3],
      );
    }

    // Water body (Buriganga river style)
    final riverPaint = Paint()..color = const Color(0xFFB3D9E8);
    final riverPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..cubicTo(
        size.width * 0.3, size.height * 0.8,
        size.width * 0.7, size.height * 0.9,
        size.width, size.height * 0.85,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(riverPath, riverPaint);

    // River label
    _drawText(canvas, 'Buriganga River', Offset(size.width * 0.35, size.height * 0.88),
        color: Colors.blue.shade700, fontSize: 9);

    // Area labels
    _drawText(canvas, 'Mirpur', Offset(size.width * 0.1, size.height * 0.15));
    _drawText(canvas, 'Gulshan', Offset(size.width * 0.7, size.height * 0.2));
    _drawText(canvas, 'Dhanmondi', Offset(size.width * 0.2, size.height * 0.55));
    _drawText(canvas, 'Motijheel', Offset(size.width * 0.65, size.height * 0.6));
    _drawText(canvas, 'Old Dhaka', Offset(size.width * 0.45, size.height * 0.75));
  }

  void _drawText(Canvas canvas, String text, Offset pos,
      {Color color = const Color(0xFF888888), double fontSize = 10}) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  void _drawRoute(Canvas canvas, Offset start, Offset cp1, Offset cp2, Offset end, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.5)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final routePath = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    canvas.drawPath(routePath, shadowPaint);

    // Dashed route
    final dashPaint = Paint()
      ..color = Colors.blue.shade700
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final dashedPath = _dashPath(routePath, 10, 6);
    canvas.drawPath(dashedPath, dashPaint);

    // Rider trail
    if (order.riderLocation != null) {
      final progress = _getProgress();
      if (progress > 0) {
        final metrics = routePath.computeMetrics().first;
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
    final totalDist = _dist(_restaurantLat, _restaurantLng, _customerLat, _customerLng);
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

  void _drawMarker(Canvas canvas, Offset pos, Color color, IconData icon, String label) {
    // Shadow
    canvas.drawCircle(pos, 26, Paint()..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Pin body
    final pinPath = Path()
      ..addOval(Rect.fromCircle(center: pos, radius: 20));
    canvas.drawPath(pinPath, Paint()..color = color);
    canvas.drawCircle(pos, 20, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);

    // Inner circle
    canvas.drawCircle(pos, 14, Paint()..color = Colors.white);

    // Icon
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

    // Label
    final lp = TextPainter(textDirection: TextDirection.ltr);
    lp.text = TextSpan(
      text: label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
    );
    lp.layout();
    
    // Label background
    canvas.drawRRect(
      RRect.fromLTRBR(
        pos.dx - lp.width / 2 - 6, pos.dy + 24,
        pos.dx + lp.width / 2 + 6, pos.dy + 38,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    lp.paint(canvas, Offset(pos.dx - lp.width / 2, pos.dy + 26));
  }

  void _drawRiderMarker(Canvas canvas, Offset pos) {
    // Glow
    canvas.drawCircle(pos, 28, Paint()
      ..color = Colors.blue.shade400.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    canvas.drawCircle(pos, 22, Paint()..color = Colors.blue.shade600);
    canvas.drawCircle(pos, 22, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
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

    // "Rider" label
    const label = 'Rider';
    final lp = TextPainter(textDirection: TextDirection.ltr);
    lp.text = TextSpan(
      text: label,
      style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
    );
    lp.layout();
    canvas.drawRRect(
      RRect.fromLTRBR(
        pos.dx - lp.width / 2 - 6, pos.dy + 26,
        pos.dx + lp.width / 2 + 6, pos.dy + 40,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
    lp.paint(canvas, Offset(pos.dx - lp.width / 2, pos.dy + 28));
  }

  @override
  bool shouldRepaint(covariant _DhakaMapPainter old) =>
      old.order != order || old.bounceOffset != bounceOffset;
}
