import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/web_socket_service.dart';
import '../../../shared/models/models.dart';

// --- Events ---
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurantMenu extends CustomerEvent {}

class AddToCart extends CustomerEvent {
  final FoodItem item;
  const AddToCart(this.item);

  @override
  List<Object?> get props => [item];
}

class RemoveFromCart extends CustomerEvent {
  final FoodItem item;
  const RemoveFromCart(this.item);

  @override
  List<Object?> get props => [item];
}

class ClearCart extends CustomerEvent {}

class PlaceOrder extends CustomerEvent {
  final String customerName;
  final String deliveryAddress;

  const PlaceOrder({
    required this.customerName,
    required this.deliveryAddress,
  });

  @override
  List<Object?> get props => [customerName, deliveryAddress];
}

class WebSocketOrderUpdateReceived extends CustomerEvent {
  final Map<String, dynamic> payload;
  const WebSocketOrderUpdateReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class WebSocketRiderLocationReceived extends CustomerEvent {
  final Map<String, dynamic> payload;
  const WebSocketRiderLocationReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class ResetCustomerFlow extends CustomerEvent {}


// --- State ---
class CustomerState extends Equatable {
  final List<FoodItem> menuItems;
  final List<CartItem> cart;
  final Order? activeOrder;
  final bool isPlacingOrder;
  final String? errorMessage;

  const CustomerState({
    this.menuItems = const [],
    this.cart = const [],
    this.activeOrder,
    this.isPlacingOrder = false,
    this.errorMessage,
  });

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  CustomerState copyWith({
    List<FoodItem>? menuItems,
    List<CartItem>? cart,
    Order? activeOrder,
    bool? isPlacingOrder,
    String? errorMessage,
    bool clearActiveOrder = false,
  }) {
    return CustomerState(
      menuItems: menuItems ?? this.menuItems,
      cart: cart ?? this.cart,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [menuItems, cart, activeOrder, isPlacingOrder, errorMessage];
}


// --- Bloc ---
class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final WebSocketService _webSocketService;
  StreamSubscription? _wsSubscription;

  CustomerBloc(this._webSocketService) : super(const CustomerState()) {
    // Listen to real-time events from WebSocket
    _wsSubscription = _webSocketService.messages.listen((message) {
      final event = message['event'] as String?;
      final data = message['data'] as Map<String, dynamic>?;

      if (event != null && data != null) {
        if (event == 'order_status_updated') {
          add(WebSocketOrderUpdateReceived(data));
        } else if (event == 'rider_location_updated') {
          add(WebSocketRiderLocationReceived(data));
        }
      }
    });

    on<LoadRestaurantMenu>((event, emit) {
      // Load static dummy menu items
      final menu = [
        const FoodItem(
          id: 'food_1',
          name: 'Classic Cheeseburger',
          description: 'Juicy beef patty, melted cheddar, lettuce, tomato & secret sauce',
          price: 8.99,
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
        ),
        const FoodItem(
          id: 'food_2',
          name: 'Pepperoni Pizza',
          description: 'Spicy pepperoni, mozzarella, tomato sauce & fresh basil',
          price: 12.49,
          imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=500',
        ),
        const FoodItem(
          id: 'food_3',
          name: 'Spicy Buffalo Wings',
          description: 'Crispy chicken wings tossed in tangy buffalo hot sauce with ranch dip',
          price: 9.99,
          imageUrl: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=500',
        ),
        const FoodItem(
          id: 'food_4',
          name: 'Chocolate Fudge Shake',
          description: 'Rich chocolate shake topped with whipped cream and chocolate drizzle',
          price: 4.99,
          imageUrl: 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=500',
        ),
      ];
      emit(state.copyWith(menuItems: menu));
    });

    on<AddToCart>((event, emit) {
      final index = state.cart.indexWhere((i) => i.foodItem.id == event.item.id);
      List<CartItem> updatedCart;
      if (index >= 0) {
        final existingItem = state.cart[index];
        updatedCart = List.from(state.cart)
          ..[index] = CartItem(
            foodItem: existingItem.foodItem,
            quantity: existingItem.quantity + 1,
          );
      } else {
        updatedCart = List.from(state.cart)..add(CartItem(foodItem: event.item, quantity: 1));
      }
      emit(state.copyWith(cart: updatedCart));
    });

    on<RemoveFromCart>((event, emit) {
      final index = state.cart.indexWhere((i) => i.foodItem.id == event.item.id);
      if (index < 0) return;
      
      final existingItem = state.cart[index];
      List<CartItem> updatedCart = List.from(state.cart);
      if (existingItem.quantity > 1) {
        updatedCart[index] = CartItem(
          foodItem: existingItem.foodItem,
          quantity: existingItem.quantity - 1,
        );
      } else {
        updatedCart.removeAt(index);
      }
      emit(state.copyWith(cart: updatedCart));
    });

    on<ClearCart>((event, emit) {
      emit(state.copyWith(cart: const []));
    });

    on<PlaceOrder>((event, emit) {
      if (state.cart.isEmpty) {
        emit(state.copyWith(errorMessage: 'Cart is empty. cannot place order.'));
        return;
      }

      emit(state.copyWith(isPlacingOrder: true, errorMessage: null));

      final newOrder = Order(
        id: const Uuid().v4(),
        restaurantName: 'GoBite Kitchen',
        customerName: event.customerName,
        items: state.cart,
        status: OrderStatus.pending,
        totalAmount: state.cartTotal,
        deliveryAddress: event.deliveryAddress,
      );

      // Send the place_order event to the server
      _webSocketService.send('place_order', newOrder.toJson());

      emit(state.copyWith(
        activeOrder: newOrder,
        isPlacingOrder: false,
        cart: const [], // Clear cart after placing order
      ));
    });

    on<WebSocketOrderUpdateReceived>((event, emit) {
      final orderJson = event.payload;
      try {
        final updatedOrder = Order.fromJson(orderJson);
        // Ensure this update corresponds to our active order
        if (state.activeOrder != null && state.activeOrder!.id == updatedOrder.id) {
          emit(state.copyWith(activeOrder: updatedOrder));
        }
      } catch (e) {
        print('Error parsing order update in CustomerBloc: $e');
      }
    });

    on<WebSocketRiderLocationReceived>((event, emit) {
      final locationData = event.payload;
      final orderId = locationData['orderId'] as String?;
      final riderName = locationData['riderName'] as String?;
      final latitude = locationData['latitude'] as double?;
      final longitude = locationData['longitude'] as double?;

      if (state.activeOrder != null &&
          state.activeOrder!.id == orderId &&
          latitude != null &&
          longitude != null) {
        
        final updatedLocation = UserLocation(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now().toIso8601String(),
        );

        final updatedOrder = state.activeOrder!.copyWith(
          riderName: riderName ?? state.activeOrder!.riderName,
          riderLocation: updatedLocation,
        );

        emit(state.copyWith(activeOrder: updatedOrder));
      }
    });

    on<ResetCustomerFlow>((event, emit) {
      emit(state.copyWith(clearActiveOrder: true));
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
