import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/web_socket_service.dart';
import '../../../shared/models/models.dart';

// --- Events ---
abstract class RiderEvent extends Equatable {
  const RiderEvent();

  @override
  List<Object?> get props => [];
}

class RiderStartListening extends RiderEvent {
  final String riderName;
  const RiderStartListening(this.riderName);

  @override
  List<Object?> get props => [riderName];
}

class WebSocketRiderOrderUpdateReceived extends RiderEvent {
  final Map<String, dynamic> payload;
  const WebSocketRiderOrderUpdateReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class AcceptDelivery extends RiderEvent {
  final String orderId;
  const AcceptDelivery(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class PickupOrder extends RiderEvent {
  final String orderId;
  const PickupOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class DeliverOrder extends RiderEvent {
  final String orderId;
  const DeliverOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class StartSimulatedRoute extends RiderEvent {
  final String orderId;
  const StartSimulatedRoute(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class StopSimulatedRoute extends RiderEvent {}

class UpdateRiderLocation extends RiderEvent {
  final double latitude;
  final double longitude;

  const UpdateRiderLocation(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];
}


// --- State ---
class RiderState extends Equatable {
  final String riderName;
  final List<Order> availableOrders;
  final Order? activeDelivery;
  final UserLocation? currentLocation;
  final bool isSimulatingRoute;

  const RiderState({
    this.riderName = 'Rider 1',
    this.availableOrders = const [],
    this.activeDelivery,
    this.currentLocation,
    this.isSimulatingRoute = false,
  });

  RiderState copyWith({
    String? riderName,
    List<Order>? availableOrders,
    Order? activeDelivery,
    UserLocation? currentLocation,
    bool? isSimulatingRoute,
    bool clearActiveDelivery = false,
  }) {
    return RiderState(
      riderName: riderName ?? this.riderName,
      availableOrders: availableOrders ?? this.availableOrders,
      activeDelivery: clearActiveDelivery ? null : (activeDelivery ?? this.activeDelivery),
      currentLocation: currentLocation ?? this.currentLocation,
      isSimulatingRoute: isSimulatingRoute ?? this.isSimulatingRoute,
    );
  }

  @override
  List<Object?> get props => [
        riderName,
        availableOrders,
        activeDelivery,
        currentLocation,
        isSimulatingRoute,
      ];
}


// --- Bloc ---
class RiderBloc extends Bloc<RiderEvent, RiderState> {
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;
  Timer? _simulationTimer;

  // Predefined route waypoints for simulating rider movement (from Restaurant to Customer)
  static const List<Map<String, double>> _simulationWaypoints = [
    {'lat': 37.7749, 'lng': -122.4194}, // Start at Restaurant
    {'lat': 37.7765, 'lng': -122.4170},
    {'lat': 37.7785, 'lng': -122.4145},
    {'lat': 37.7805, 'lng': -122.4115},
    {'lat': 37.7825, 'lng': -122.4085},
    {'lat': 37.7845, 'lng': -122.4060},
    {'lat': 37.7865, 'lng': -122.4035},
    {'lat': 37.7885, 'lng': -122.4015},
    {'lat': 37.7892, 'lng': -122.4014}, // Arrive at Customer
  ];

  RiderBloc(this._webSocketService) : super(const RiderState()) {
    
    on<RiderStartListening>((event, emit) {
      emit(state.copyWith(
        riderName: event.riderName,
        currentLocation: const UserLocation(
          latitude: 37.7749,
          longitude: -122.4194,
          timestamp: '',
        ),
      ));

      _wsSubscription?.cancel();
      _wsSubscription = _webSocketService.messages.listen((message) {
        final eventName = message['event'] as String?;
        final data = message['data'] as Map<String, dynamic>?;

        if (eventName != null && data != null) {
          if (eventName == 'place_order' || eventName == 'order_status_updated') {
            add(WebSocketRiderOrderUpdateReceived(data));
          }
        }
      });
    });

    on<WebSocketRiderOrderUpdateReceived>((event, emit) {
      try {
        final order = Order.fromJson(event.payload);

        // Update list of available orders.
        // Riders can accept orders that are preparing or ready for pickup.
        List<Order> updatedAvailable = List.from(state.availableOrders);
        final index = updatedAvailable.indexWhere((o) => o.id == order.id);

        if (order.status == OrderStatus.delivered || order.status == OrderStatus.rejected) {
          // Remove from available lists if completed or rejected
          if (index >= 0) updatedAvailable.removeAt(index);
          if (state.activeDelivery?.id == order.id) {
            emit(state.copyWith(clearActiveDelivery: true, isSimulatingRoute: false));
            _simulationTimer?.cancel();
          }
        } else {
          // Add or update order in available list
          if (index >= 0) {
            updatedAvailable[index] = order;
          } else {
            updatedAvailable.add(order);
          }

          // If it is our active order, keep it updated
          if (state.activeDelivery?.id == order.id) {
            emit(state.copyWith(activeDelivery: order));
          }
        }

        emit(state.copyWith(availableOrders: updatedAvailable));
      } catch (e) {
        print('Error processing order status inside RiderBloc: $e');
      }
    });

    on<AcceptDelivery>((event, emit) {
      final index = state.availableOrders.indexWhere((o) => o.id == event.orderId);
      if (index >= 0) {
        final order = state.availableOrders[index];
        final updatedOrder = order.copyWith(
          status: OrderStatus.preparing, // Rider accepted delivery, restaurant still prepping/readying
          riderName: state.riderName,
        );

        // Inform server
        _webSocketService.send('order_status_updated', updatedOrder.toJson());

        emit(state.copyWith(
          activeDelivery: updatedOrder,
        ));
      }
    });

    on<PickupOrder>((event, emit) {
      if (state.activeDelivery?.id == event.orderId) {
        final updatedOrder = state.activeDelivery!.copyWith(
          status: OrderStatus.outForDelivery,
          riderLocation: state.currentLocation,
        );

        // Inform server
        _webSocketService.send('order_status_updated', updatedOrder.toJson());
        
        emit(state.copyWith(activeDelivery: updatedOrder));

        // Auto-start route simulation when picked up
        add(StartSimulatedRoute(event.orderId));
      }
    });

    on<DeliverOrder>((event, emit) {
      if (state.activeDelivery?.id == event.orderId) {
        final updatedOrder = state.activeDelivery!.copyWith(status: OrderStatus.delivered);

        // Stop simulation
        _simulationTimer?.cancel();

        // Inform server
        _webSocketService.send('order_status_updated', updatedOrder.toJson());

        emit(state.copyWith(
          clearActiveDelivery: true,
          isSimulatingRoute: false,
        ));
      }
    });

    on<StartSimulatedRoute>((event, emit) {
      _simulationTimer?.cancel();
      emit(state.copyWith(isSimulatingRoute: true));

      int step = 0;
      _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (step >= _simulationWaypoints.length) {
          timer.cancel();
          add(DeliverOrder(event.orderId));
          return;
        }

        final waypoint = _simulationWaypoints[step];
        add(UpdateRiderLocation(waypoint['lat']!, waypoint['lng']!));
        step++;
      });
    });

    on<StopSimulatedRoute>((event, emit) {
      _simulationTimer?.cancel();
      emit(state.copyWith(isSimulatingRoute: false));
    });

    on<UpdateRiderLocation>((event, emit) {
      final newLoc = UserLocation(
        latitude: event.latitude,
        longitude: event.longitude,
        timestamp: DateTime.now().toIso8601String(),
      );

      emit(state.copyWith(currentLocation: newLoc));

      // Broadcast location updates through WebSocket
      if (state.activeDelivery != null) {
        _webSocketService.send('rider_location_updated', {
          'orderId': state.activeDelivery!.id,
          'riderName': state.riderName,
          'latitude': event.latitude,
          'longitude': event.longitude,
        });
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _simulationTimer?.cancel();
    return super.close();
  }
}
