import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../bloc/customer_bloc.dart';
import 'home_screen.dart';

class CustomerTrackingScreen extends StatefulWidget {
  final String? orderId;
  const CustomerTrackingScreen({super.key, this.orderId});

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
    ); // Don't auto-start — controlled by order status

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

  // Track if rating has been shown for this delivery session
  String? _lastRatedOrderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<CustomerBloc, CustomerState>(
        listenWhen: (previous, current) {
          // Trigger when a new order moves to history as delivered
          if (current.orderHistory.length > previous.orderHistory.length) {
            final newHistoryOrder = current.orderHistory.isNotEmpty
                ? current.orderHistory.last
                : null;
            if (newHistoryOrder != null) {
              final wasActive = previous.activeOrders.any(
                (o) => o.id == newHistoryOrder.id,
              );
              if (wasActive &&
                  newHistoryOrder.status == OrderStatus.delivered &&
                  newHistoryOrder.riderName != null &&
                  _lastRatedOrderId != newHistoryOrder.id) {
                return true;
              }
            }
          }
          return false;
        },
        listener: (context, state) {
          final deliveredOrder = state.orderHistory.isNotEmpty
              ? state.orderHistory.last
              : null;
          if (deliveredOrder != null &&
              deliveredOrder.status == OrderStatus.delivered &&
              deliveredOrder.riderName != null &&
              _lastRatedOrderId != deliveredOrder.id) {
            _lastRatedOrderId = deliveredOrder.id;
            // Pop the tracking screen to return to dashboard/home, where the dashboard's BlocListener will show the rating popup
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
        child: BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, state) {
            Order? order;
            if (widget.orderId != null) {
              final idx = state.activeOrders.indexWhere(
                (o) => o.id == widget.orderId,
              );
              order = idx >= 0 ? state.activeOrders[idx] : null;
            } else {
              order = state.activeOrders.isNotEmpty
                  ? state.activeOrders.last
                  : null;
            }

            // Control rider bounce animation based on order status
            final isOutForDelivery =
                order?.status == OrderStatus.outForDelivery;
            if (isOutForDelivery && !_riderBounceController.isAnimating) {
              _riderBounceController.repeat(reverse: true);
            } else if (!isOutForDelivery &&
                _riderBounceController.isAnimating) {
              _riderBounceController.stop();
              _riderBounceController.reset();
            }

            if (order == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No active order or Order delivered!'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const CustomerCategoryHome(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // ─── Map Section ───
                Expanded(flex: 6, child: _buildMapSection(order)),

                // ─── Info Panel ───
                Expanded(
                  flex: 5,
                  child: _buildInfoPanel(context, order, state),
                ),
              ],
            );
          },
        ),
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

        // Back to Home Button
        Positioned(
          top: 40,
          left: 16,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerCategoryHome()),
                (route) => false,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: 8),
                  Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),

        // Status pill
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                    Icon(
                      _getStatusIcon(order.status),
                      color: Colors.white,
                      size: 18,
                    ),
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
                  const Text(
                    'ETA',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
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

  Widget _buildInfoPanel(
    BuildContext context,
    Order order,
    CustomerState state,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
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
            const SizedBox(height: 24),

            // Order Steps timeline
            _buildSteps(order),

            const Divider(height: 40),

            // Rider Info (if assigned)
            if (order.riderName != null)
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.riderName!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (context) {
                            final stats = state.riderStats[order.riderName];
                            if (stats != null) {
                              final double avg = stats['averageRating'] ?? 0.0;
                              final int total = stats['totalDeliveries'] ?? 0;
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '($total deliveries)',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const Text(
                              'Your Rider',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
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

            if (order.status == OrderStatus.delivered &&
                order.riderName != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(context, order.riderName!),
                  icon: const Icon(Icons.star, color: Colors.orange),
                  label: const Text(
                    'Rate Rider',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String riderName) {
    int rating = 5;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('Rate $riderName', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How was your delivery?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<CustomerBloc>().add(
                      RateRider(riderName, rating),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for rating $riderName!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSteps(Order order) {
    final steps = [
      const _StepInfo(
        OrderStatus.accepted,
        'Order Confirmed',
        Icons.check_circle,
      ),
      const _StepInfo(
        OrderStatus.preparing,
        'Preparing your food',
        Icons.restaurant,
      ),
      const _StepInfo(
        OrderStatus.readyForPickup,
        'Ready for Pickup',
        Icons.shopping_bag,
      ),
      const _StepInfo(
        OrderStatus.outForDelivery,
        'Out for Delivery',
        Icons.motorcycle,
      ),
      const _StepInfo(OrderStatus.delivered, 'Delivered', Icons.home),
    ];

    int currentIndex = steps.indexWhere((s) => s.status == order.status);
    // If pending, none are completed.
    if (order.status == OrderStatus.pending) currentIndex = -1;
    // If rejected, just show error
    if (order.status == OrderStatus.rejected) currentIndex = -1;

    return Column(
      children: steps.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;

        final isCompleted = idx <= currentIndex;
        final isCurrent = idx == currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line & node
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? _getStatusColor(step.status)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(
                            color: _getStatusColor(
                              step.status,
                            ).withOpacity(0.3),
                            width: 4,
                          )
                        : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted
                        ? _getStatusColor(step.status)
                        : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Timeline content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCompleted ? Colors.black87 : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
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

  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.accepted:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.amber.shade700;
      case OrderStatus.readyForPickup:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_top;
      case OrderStatus.accepted:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.readyForPickup:
        return Icons.shopping_bag;
      case OrderStatus.outForDelivery:
        return Icons.motorcycle;
      case OrderStatus.delivered:
        return Icons.home;
      case OrderStatus.rejected:
        return Icons.cancel;
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
    final cp1 = Offset(
      restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.25,
      restaurantPt.dy + 40,
    );
    final cp2 = Offset(
      restaurantPt.dx + (customerPt.dx - restaurantPt.dx) * 0.75,
      customerPt.dy - 40,
    );

    _drawRoute(canvas, restaurantPt, cp1, cp2, customerPt, size);

    // Draw markers
    _drawMarker(
      canvas,
      restaurantPt,
      const Color(0xFFE53935),
      Icons.storefront,
      'Restaurant',
    );
    _drawMarker(canvas, customerPt, const Color(0xFF43A047), Icons.home, 'You');

    // Draw rider
    if (order.riderLocation != null) {
      final riderLat = order.riderLocation!.latitude;
      final riderLng = order.riderLocation!.longitude;

      // Clamp rider position between restaurant and customer
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

    // Minor roads (diagonal lines to make it look city-like)
    for (double i = -size.width; i < size.width * 2; i += size.width / 8) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        minorRoadPaint,
      );
    }

    // Add some "parks"
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

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.teal.shade100
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Inner line
    final innerPaint = Paint()
      ..color = Colors.teal.shade400
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dashed inner line
    final dashedPath = _dashPath(path, 10, 8);
    canvas.drawPath(dashedPath, innerPaint);

    // Draw progressed route if rider is out for delivery
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
    // Shadow
    canvas.drawCircle(
      pos,
      26,
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Pin body
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
    // Glow
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

    // "Rider" label
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
  bool shouldRepaint(covariant _DhakaMapPainter old) =>
      old.order != order || old.bounceOffset != bounceOffset;
}
