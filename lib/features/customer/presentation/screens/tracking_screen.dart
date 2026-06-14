import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../bloc/customer_bloc.dart';

// Fixed Dhaka coordinates
const _restaurantLat = 23.8103;
const _restaurantLng = 90.4125;
const _customerLat = 23.7461;
const _customerLng = 90.3742;

class CustomerTrackingScreen extends StatefulWidget {
  const CustomerTrackingScreen({super.key});

  @override
  State<CustomerTrackingScreen> createState() => _CustomerTrackingScreenState();
}

class _CustomerTrackingScreenState extends State<CustomerTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
    final markers = <Marker>[
      Marker(
        point: const LatLng(_restaurantLat, _restaurantLng),
        width: 60,
        height: 60,
        child: _buildLocationPin(Icons.storefront, const Color(0xFFE53935)),
      ),
      Marker(
        point: const LatLng(_customerLat, _customerLng),
        width: 60,
        height: 60,
        child: _buildLocationPin(Icons.home, const Color(0xFF43A047)),
      ),
    ];

    if (order.riderLocation != null) {
      markers.add(
        Marker(
          point: LatLng(order.riderLocation!.latitude, order.riderLocation!.longitude),
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) => Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade100.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.motorcycle, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng((_restaurantLat + _customerLat) / 2, (_restaurantLng + _customerLng) / 2),
            initialZoom: 12.5,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.gobite.customer',
            ),
            PolylineLayer(
              polylines: <Polyline<Object>>[
                Polyline<Object>(
                  points: const [
                    LatLng(_restaurantLat, _restaurantLng),
                    LatLng(_customerLat, _customerLng),
                  ],
                  color: Colors.teal.shade400,
                  strokeWidth: 4,
                ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
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

        // ETA chip
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
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
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

  Widget _buildLocationPin(IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        Container(width: 2, height: 10, color: color),
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

            // Steps
            _buildSteps(order),
            const Divider(height: 40),

            // Rider Info
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your Rider',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling rider...')),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps(Order order) {
    final steps = [
      const _StepInfo(OrderStatus.accepted, 'Order Confirmed', Icons.check_circle),
      const _StepInfo(OrderStatus.preparing, 'Preparing your food', Icons.restaurant),
      const _StepInfo(OrderStatus.readyForPickup, 'Ready for Pickup', Icons.shopping_bag),
      const _StepInfo(OrderStatus.outForDelivery, 'Out for Delivery', Icons.motorcycle),
      const _StepInfo(OrderStatus.delivered, 'Delivered', Icons.home),
    ];

    int currentIndex = steps.indexWhere((s) => s.status == order.status);
    if (order.status == OrderStatus.pending) currentIndex = -1;
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
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? _getStatusColor(step.status) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: isCurrent ? Border.all(color: _getStatusColor(step.status).withOpacity(0.3), width: 4) : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (idx < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted ? _getStatusColor(step.status) : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
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
    final destLat = _customerLat;
    final destLng = _customerLng;
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
