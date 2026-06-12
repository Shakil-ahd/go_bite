import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/web_socket_service.dart';
import '../../../shared/models/models.dart';

// --- Events ---
abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => [];
}

class RestaurantStartListening extends RestaurantEvent {}

class WebSocketNewOrderPlaced extends RestaurantEvent {
  final Map<String, dynamic> payload;
  const WebSocketNewOrderPlaced(this.payload);

  @override
  List<Object?> get props => [payload];
}

class WebSocketRestaurantOrderUpdateReceived extends RestaurantEvent {
  final Map<String, dynamic> payload;
  const WebSocketRestaurantOrderUpdateReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class AcceptOrder extends RestaurantEvent {
  final String orderId;
  const AcceptOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class RejectOrder extends RestaurantEvent {
  final String orderId;
  const RejectOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class UpdateOrderStatus extends RestaurantEvent {
  final String orderId;
  final OrderStatus status;
  const UpdateOrderStatus(this.orderId, this.status);

  @override
  List<Object?> get props => [orderId, status];
}

class ClearNewOrderAlert extends RestaurantEvent {}


// --- State ---
class RestaurantState extends Equatable {
  final List<Order> orders;
  final Order? newOrderAlert;

  const RestaurantState({
    this.orders = const [],
    this.newOrderAlert,
  });

  RestaurantState copyWith({
    List<Order>? orders,
    Order? newOrderAlert,
    bool clearAlert = false,
  }) {
    return RestaurantState(
      orders: orders ?? this.orders,
      newOrderAlert: clearAlert ? null : (newOrderAlert ?? this.newOrderAlert),
    );
  }

  @override
  List<Object?> get props => [orders, newOrderAlert];
}


// --- Bloc ---
class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;

  RestaurantBloc(this._webSocketService) : super(const RestaurantState()) {
    
    on<RestaurantStartListening>((event, emit) {
      _wsSubscription?.cancel();
      _wsSubscription = _webSocketService.messages.listen((message) {
        final eventName = message['event'] as String?;
        final data = message['data'] as Map<String, dynamic>?;

        if (eventName != null && data != null) {
          if (eventName == 'place_order') {
            add(WebSocketNewOrderPlaced(data));
          } else if (eventName == 'order_status_updated') {
            add(WebSocketRestaurantOrderUpdateReceived(data));
          }
        }
      });
    });

    on<WebSocketNewOrderPlaced>((event, emit) {
      try {
        final order = Order.fromJson(event.payload);
        
        // Add to order list if not already present
        final exists = state.orders.any((o) => o.id == order.id);
        if (!exists) {
          final updatedOrders = List<Order>.from(state.orders)..insert(0, order);
          emit(state.copyWith(
            orders: updatedOrders,
            newOrderAlert: order, // Set the alert for notification screen popup
          ));
        }
      } catch (e) {
        print('Error processing new order in RestaurantBloc: $e');
      }
    });

    on<WebSocketRestaurantOrderUpdateReceived>((event, emit) {
      try {
        final updatedOrder = Order.fromJson(event.payload);
        final index = state.orders.indexWhere((o) => o.id == updatedOrder.id);
        
        if (index >= 0) {
          final updatedOrders = List<Order>.from(state.orders)..[index] = updatedOrder;
          emit(state.copyWith(orders: updatedOrders));
        } else {
          // If Rider/Customer updated status first, add it to list
          final updatedOrders = List<Order>.from(state.orders)..add(updatedOrder);
          emit(state.copyWith(orders: updatedOrders));
        }
      } catch (e) {
        print('Error updating restaurant order status: $e');
      }
    });

    on<AcceptOrder>((event, emit) {
      final index = state.orders.indexWhere((o) => o.id == event.orderId);
      if (index >= 0) {
        final order = state.orders[index];
        final updatedOrder = order.copyWith(status: OrderStatus.accepted);
        
        // Send state change to WS
        _webSocketService.send('order_status_updated', updatedOrder.toJson());
        
        final updatedOrders = List<Order>.from(state.orders)..[index] = updatedOrder;
        emit(state.copyWith(orders: updatedOrders, clearAlert: true));
      }
    });

    on<RejectOrder>((event, emit) {
      final index = state.orders.indexWhere((o) => o.id == event.orderId);
      if (index >= 0) {
        final order = state.orders[index];
        final updatedOrder = order.copyWith(status: OrderStatus.rejected);

        // Send state change to WS
        _webSocketService.send('order_status_updated', updatedOrder.toJson());

        final updatedOrders = List<Order>.from(state.orders)..[index] = updatedOrder;
        emit(state.copyWith(orders: updatedOrders, clearAlert: true));
      }
    });

    on<UpdateOrderStatus>((event, emit) {
      final index = state.orders.indexWhere((o) => o.id == event.orderId);
      if (index >= 0) {
        final order = state.orders[index];
        final updatedOrder = order.copyWith(status: event.status);

        // Send state change to WS
        _webSocketService.send('order_status_updated', updatedOrder.toJson());

        final updatedOrders = List<Order>.from(state.orders)..[index] = updatedOrder;
        emit(state.copyWith(orders: updatedOrders));
      }
    });

    on<ClearNewOrderAlert>((event, emit) {
      emit(state.copyWith(clearAlert: true));
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
