import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/web_socket_service.dart';
import '../../../shared/models/models.dart';

// ─── Events ───
abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurantMenu extends CustomerEvent {}

class SelectCategory extends CustomerEvent {
  final ProductCategory category;
  const SelectCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class GoBackToCategories extends CustomerEvent {}

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
  final String customerPhone;
  final String deliveryAddress;

  const PlaceOrder({
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
  });

  @override
  List<Object?> get props => [customerName, customerPhone, deliveryAddress];
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


// ─── State ───
class CustomerState extends Equatable {
  final List<FoodItem> allProducts;
  final List<FoodItem> menuItems;
  final List<CartItem> cart;
  final Order? activeOrder;
  final List<Order> orderHistory;
  final bool isPlacingOrder;
  final String? errorMessage;
  final ProductCategory? selectedCategory;

  const CustomerState({
    this.allProducts = const [],
    this.menuItems = const [],
    this.cart = const [],
    this.activeOrder,
    this.orderHistory = const [],
    this.isPlacingOrder = false,
    this.errorMessage,
    this.selectedCategory,
  });

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  CustomerState copyWith({
    List<FoodItem>? allProducts,
    List<FoodItem>? menuItems,
    List<CartItem>? cart,
    Order? activeOrder,
    List<Order>? orderHistory,
    bool? isPlacingOrder,
    String? errorMessage,
    ProductCategory? selectedCategory,
    bool clearActiveOrder = false,
    bool clearCategory = false,
  }) {
    return CustomerState(
      allProducts: allProducts ?? this.allProducts,
      menuItems: menuItems ?? this.menuItems,
      cart: cart ?? this.cart,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      orderHistory: orderHistory ?? this.orderHistory,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  List<Object?> get props => [allProducts, menuItems, cart, activeOrder, orderHistory, isPlacingOrder, errorMessage, selectedCategory];
}


// ─── Bangladeshi Product Catalog ───
const List<FoodItem> _bangladeshiCatalog = [
  // ═══ FOOD (8 items) ═══
  FoodItem(
    id: 'food_01', name: 'Kacchi Biryani',
    description: 'Authentic Dhaka-style Kacchi with tender goat meat, aromatic rice, potatoes & boiled eggs',
    price: 350, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_02', name: 'Chicken Biryani',
    description: 'Fragrant basmati rice with juicy chicken pieces, saffron & special spices',
    price: 280, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_03', name: 'Morog Polao',
    description: 'Classic Bengali chicken polao with ghee-flavored rice & whole spices',
    price: 300, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_04', name: 'Beef Tehari',
    description: 'Spicy beef tehari with fragrant rice, potatoes & traditional Puran Dhaka spices',
    price: 220, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_05', name: 'Khichuri + Dim Bhaji',
    description: 'Comfort food: Dal khichuri served with egg omelette & mixed vegetable bhaji',
    price: 150, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_06', name: 'Ilish Bhuna',
    description: 'Premium Hilsa fish slow-cooked in mustard paste & traditional Bengali spices',
    price: 450, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_07', name: 'Beef Bhuna Khichuri',
    description: 'Rich beef bhuna with aromatic khichuri, perfect for rainy days',
    price: 250, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_08', name: 'Shutki Bhorta + Bhat',
    description: 'Authentic dried fish bhorta served with steamed rice & dal',
    price: 180, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),

  // ═══ DRINKS (6 items) ═══
  FoodItem(
    id: 'drink_01', name: 'Borhani',
    description: 'Traditional Bangladeshi spicy yogurt drink, perfect with biryani',
    price: 40, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_02', name: 'Mango Lassi',
    description: 'Creamy mango yogurt smoothie made with fresh seasonal mangoes',
    price: 60, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_03', name: 'Doodh Cha',
    description: 'Rich milk tea with ginger, cardamom & cinnamon — Bangladeshi special',
    price: 25, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_04', name: 'Lemon Soda',
    description: 'Refreshing lemon soda with mint & a pinch of black salt',
    price: 35, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_05', name: 'Aam Panna',
    description: 'Tangy raw mango drink with cumin, mint & sugar — summer favorite',
    price: 45, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_06', name: 'Faluda',
    description: 'Colorful rose-flavored Faluda with vermicelli, basil seeds & ice cream',
    price: 80, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.drinks,
  ),

  // ═══ SNACKS (6 items) ═══
  FoodItem(
    id: 'snack_01', name: 'Fuchka (8 pcs)',
    description: 'Crispy hollow shells filled with spicy tamarind water, chickpeas & potatoes',
    price: 40, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_02', name: 'Chotpoti',
    description: 'Spicy chickpea curry topped with boiled egg, onion & tamarind sauce',
    price: 50, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_03', name: 'Jhalmuri',
    description: 'Puffed rice mixed with mustard oil, green chili, onion & chanachur',
    price: 30, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_04', name: 'Singara (4 pcs)',
    description: 'Crispy fried pastry filled with spiced potatoes & peas — classic Bengali snack',
    price: 40, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_05', name: 'Piyaju (6 pcs)',
    description: 'Crunchy onion fritters made with lentil batter — iftar staple',
    price: 30, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_06', name: 'Beguni (6 pcs)',
    description: 'Batter-fried eggplant slices — crispy outside, soft inside',
    price: 35, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.snacks,
  ),

  // ═══ MEDICINE (5 items) ═══
  FoodItem(
    id: 'med_01', name: 'Napa Extra',
    description: 'Paracetamol 500mg + Caffeine 65mg — for headache, fever & body pain',
    price: 12, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_02', name: 'Seclo 20mg',
    description: 'Omeprazole capsule for acidity, heartburn & gastric problems',
    price: 8, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_03', name: 'Ace Plus',
    description: 'Paracetamol + Caffeine tablet — fast relief from pain & fever',
    price: 10, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_04', name: 'Histacin',
    description: 'Chlorpheniramine maleate — for cold, allergies & runny nose',
    price: 6, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_05', name: 'Antacid Suspension',
    description: 'Liquid antacid for quick relief from gas, bloating & acidity',
    price: 65, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.medicine,
  ),

  // ═══ OTHERS (5 items) ═══
  FoodItem(
    id: 'other_01', name: 'Miniket Rice 5kg',
    description: 'Premium quality Miniket rice — best for daily cooking',
    price: 450, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_02', name: 'Soybean Oil 5L',
    description: 'Teer soybean oil — pure & healthy cooking oil',
    price: 800, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_03', name: 'Sugar 1kg',
    description: 'Refined white sugar for daily use',
    price: 120, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_04', name: 'Eggs (12 pcs)',
    description: 'Farm-fresh chicken eggs — protein-rich & nutritious',
    price: 160, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_05', name: 'Fresh Milk 1L',
    description: 'Pasteurized fresh cow milk — Farm Fresh brand',
    price: 85, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'food_09', name: 'Mutton Kala Bhuna',
    description: 'Famous Chittagong style slow-cooked dark mutton curry with aromatic spices',
    price: 450, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_10', name: 'Rupchanda Fry',
    description: 'Crispy fried pomfret fish served with onion and green chili salad',
    price: 350, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_11', name: 'Fuchka (10 pcs)',
    description: 'Crispy hollow puri filled with spicy tangy tamarind water and chickpeas',
    price: 60, imageUrl: 'https://loremflickr.com/400/400/food', category: ProductCategory.food,
  ),
  FoodItem(
    id: 'med_06', name: 'Alatrol 10mg',
    description: 'Cetirizine tablet for rapid allergy and cold relief',
    price: 5, imageUrl: 'https://loremflickr.com/400/400/medicine', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_07', name: 'Sergel 20mg',
    description: 'Esomeprazole capsule for severe gastric and ulcer protection',
    price: 10, imageUrl: 'https://loremflickr.com/400/400/medicine', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_08', name: 'Flexi 500mg',
    description: 'Ibuprofen tablet for muscle pain and joint inflammation',
    price: 8, imageUrl: 'https://loremflickr.com/400/400/medicine', category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'other_06', name: 'Radhuni Halim Mix',
    description: 'Ready to cook traditional halim mix powder',
    price: 55, imageUrl: 'https://loremflickr.com/400/400/grocery', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_07', name: 'Rupchanda Soybean Oil 2L',
    description: 'Premium fortified soybean oil',
    price: 340, imageUrl: 'https://loremflickr.com/400/400/grocery', category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_08', name: 'Aarong Dairy Butter 200g',
    description: 'Fresh salted butter made from pure cow milk',
    price: 210, imageUrl: 'https://loremflickr.com/400/400/grocery', category: ProductCategory.others,
  ),
];


// ─── Bloc ───
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
      emit(state.copyWith(allProducts: _bangladeshiCatalog));
    });

    on<SelectCategory>((event, emit) {
      final filtered = state.allProducts
          .where((item) => item.category == event.category)
          .toList();
      emit(state.copyWith(
        selectedCategory: event.category,
        menuItems: filtered,
      ));
    });

    on<GoBackToCategories>((event, emit) {
      emit(state.copyWith(clearCategory: true, menuItems: const []));
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
        emit(state.copyWith(errorMessage: 'Cart is empty. Cannot place order.'));
        return;
      }

      emit(state.copyWith(isPlacingOrder: true, errorMessage: null));

      final newOrder = Order(
        id: const Uuid().v4(),
        restaurantName: 'GoBite Store',
        customerName: event.customerName,
        customerPhone: event.customerPhone,
        items: state.cart,
        status: OrderStatus.pending,
        totalAmount: state.cartTotal,
        deliveryAddress: event.deliveryAddress,
      );

      emit(state.copyWith(
        activeOrder: newOrder,
        isPlacingOrder: false,
        cart: const [], // Clear cart after placing order
      ));

      // ─── START MOCK SIMULATION ───
      // Since Restaurant and Rider apps are separated, we simulate their responses here 
      // so the Customer can see the live tracking UI working immediately.
      _startMockOrderSimulation(newOrder);
    });

    on<WebSocketOrderUpdateReceived>((event, emit) {
      final orderJson = event.payload;
      try {
        final updatedOrder = Order.fromJson(orderJson);
        if (state.activeOrder != null && state.activeOrder!.id == updatedOrder.id) {
          if (updatedOrder.status == OrderStatus.delivered || updatedOrder.status == OrderStatus.rejected) {
            // Order is finished, move to history
            final updatedHistory = List<Order>.from(state.orderHistory)..add(updatedOrder);
            emit(state.copyWith(
              activeOrder: updatedOrder,
              orderHistory: updatedHistory,
            ));
          } else {
            emit(state.copyWith(activeOrder: updatedOrder));
          }
        }
      } catch (e) {
        // print('Error parsing order update in CustomerBloc: $e');
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

  void _startMockOrderSimulation(Order order) async {
    // Wait 2s -> Accepted
    await Future.delayed(const Duration(seconds: 2));
    if (state.activeOrder?.id != order.id) return;
    add(WebSocketOrderUpdateReceived(
      state.activeOrder!.copyWith(status: OrderStatus.accepted).toJson(),
    ));

    // Wait 2s -> Preparing
    await Future.delayed(const Duration(seconds: 2));
    if (state.activeOrder?.id != order.id) return;
    add(WebSocketOrderUpdateReceived(
      state.activeOrder!.copyWith(status: OrderStatus.preparing).toJson(),
    ));

    // Wait 3s -> Ready
    await Future.delayed(const Duration(seconds: 3));
    if (state.activeOrder?.id != order.id) return;
    add(WebSocketOrderUpdateReceived(
      state.activeOrder!.copyWith(status: OrderStatus.readyForPickup).toJson(),
    ));

    // Wait 2s -> Out for Delivery
    await Future.delayed(const Duration(seconds: 2));
    if (state.activeOrder?.id != order.id) return;
    
    // Simulate rider picking it up. We assume customer location is from auth profile,
    // but the Order doesn't store Lat/Lng directly right now (it's in UserProfile).
    // Let's just create a mock route moving from 0.0 to 1.0 progress.
    add(WebSocketOrderUpdateReceived(
      state.activeOrder!.copyWith(
        status: OrderStatus.outForDelivery,
        riderName: 'Rahim (Mock Rider)',
      ).toJson(),
    ));

    // Send location updates (progress 0.0 to 1.0)
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (state.activeOrder?.id != order.id) return;
      
      add(WebSocketRiderLocationReceived({
        'orderId': order.id,
        'riderName': 'Rahim (Mock Rider)',
        'latitude': i.toDouble(), // We use latitude as generic "progress" 0-100 for the UI to read
        'longitude': 0.0,
      }));
    }

    // Delivered
    await Future.delayed(const Duration(seconds: 1));
    if (state.activeOrder?.id != order.id) return;
    add(WebSocketOrderUpdateReceived(
      state.activeOrder!.copyWith(status: OrderStatus.delivered).toJson(),
    ));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
