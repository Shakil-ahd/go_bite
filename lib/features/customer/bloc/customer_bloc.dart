import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

class WebSocketRiderStatsReceived extends CustomerEvent {
  final Map<String, dynamic> payload;
  const WebSocketRiderStatsReceived(this.payload);

  @override
  List<Object?> get props => [payload];
}

class ResetCustomerFlow extends CustomerEvent {}

class SearchProducts extends CustomerEvent {
  final String query;
  const SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}

class InitializeUser extends CustomerEvent {
  final String email;
  const InitializeUser(this.email);

  @override
  List<Object?> get props => [email];
}

class DeleteOrderHistory extends CustomerEvent {
  final String orderId;
  const DeleteOrderHistory(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CancelOrder extends CustomerEvent {
  final String orderId;
  const CancelOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// ─── State ───
class RateRider extends CustomerEvent {
  final String riderName;
  final int rating;
  const RateRider(this.riderName, this.rating);

  @override
  List<Object?> get props => [riderName, rating];
}

class CustomerState extends Equatable {
  final List<FoodItem> allProducts;
  final List<FoodItem> menuItems;
  final List<CartItem> cart;
  final List<Order> activeOrders;
  final List<Order> orderHistory;
  final bool isPlacingOrder;
  final String? errorMessage;
  final ProductCategory? selectedCategory;
  final String? searchQuery;
  final String? userEmail;
  final Map<String, dynamic> riderStats;

  const CustomerState({
    this.allProducts = _bangladeshiCatalog,
    this.menuItems = _bangladeshiCatalog,
    this.cart = const [],
    this.activeOrders = const [],
    this.orderHistory = const [],
    this.isPlacingOrder = false,
    this.errorMessage,
    this.selectedCategory,
    this.searchQuery,
    this.userEmail,
    this.riderStats = const {},
  });

  double get cartTotal => cart.fold(0, (total, item) => total + item.totalPrice);

  CustomerState copyWith({
    List<FoodItem>? allProducts,
    List<FoodItem>? menuItems,
    List<CartItem>? cart,
    List<Order>? activeOrders,
    List<Order>? orderHistory,
    bool? isPlacingOrder,
    String? errorMessage,
    ProductCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    String? userEmail,
    Map<String, dynamic>? riderStats,
  }) {
    return CustomerState(
      allProducts: allProducts ?? this.allProducts,
      menuItems: menuItems ?? this.menuItems,
      cart: cart ?? this.cart,
      activeOrders: activeOrders ?? this.activeOrders,
      orderHistory: orderHistory ?? this.orderHistory,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      userEmail: userEmail ?? this.userEmail,
      riderStats: riderStats ?? this.riderStats,
    );
  }

  @override
  List<Object?> get props => [allProducts, menuItems, cart, activeOrders, orderHistory, isPlacingOrder, errorMessage, selectedCategory, searchQuery, userEmail, riderStats];
}


// ─── Bangladeshi Product Catalog with Reliable Unsplash Images ───
const List<FoodItem> _bangladeshiCatalog = [
  // ═══ FOOD ═══
  FoodItem(
    id: 'food_01', name: 'Kacchi Biryani',
    description: 'Authentic Dhaka-style Kacchi with tender goat meat, aromatic rice, potatoes & boiled eggs',
    price: 350,
    imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_02', name: 'Chicken Biryani',
    description: 'Fragrant basmati rice with juicy chicken pieces, saffron & special spices',
    price: 280,
    imageUrl: 'https://images.unsplash.com/photo-1589302168068-964664d93dc0?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_03', name: 'Morog Polao',
    description: 'Classic Bengali chicken polao with ghee-flavored rice & whole spices',
    price: 300,
    imageUrl: 'https://images.unsplash.com/photo-1596797038530-2c107229654b?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_04', name: 'Beef Tehari',
    description: 'Spicy beef tehari with fragrant rice, potatoes & traditional Puran Dhaka spices',
    price: 220,
    imageUrl: 'https://images.unsplash.com/photo-1574653853027-5382a3d23a15?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_05', name: 'Khichuri + Dim Bhaji',
    description: 'Comfort food: Dal khichuri served with egg omelette & mixed vegetable bhaji',
    price: 150,
    imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_06', name: 'Ilish Bhuna',
    description: 'Premium Hilsa fish slow-cooked in mustard paste & traditional Bengali spices',
    price: 450,
    imageUrl: 'https://images.unsplash.com/photo-1535399831218-d5bd36d1a6b3?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_07', name: 'Beef Bhuna Khichuri',
    description: 'Rich beef bhuna with aromatic khichuri, perfect for rainy days',
    price: 250,
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_08', name: 'Shutki Bhorta + Bhat',
    description: 'Authentic dried fish bhorta served with steamed rice & dal',
    price: 180,
    imageUrl: 'https://images.unsplash.com/photo-1548943487-a2e4e43b4853?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_09', name: 'Mutton Kala Bhuna',
    description: 'Famous Chittagong style slow-cooked dark mutton curry with aromatic spices',
    price: 450,
    imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_10', name: 'Rupchanda Fry',
    description: 'Crispy fried pomfret fish served with onion and green chili salad',
    price: 350,
    imageUrl: 'https://images.unsplash.com/photo-1562802378-063ec186a863?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),
  FoodItem(
    id: 'food_11', name: 'Dal Makhani',
    description: 'Creamy black lentils slow-cooked overnight with butter and cream',
    price: 160,
    imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.food,
  ),

  // ═══ DRINKS ═══
  FoodItem(
    id: 'drink_01', name: 'Borhani',
    description: 'Traditional Bangladeshi spicy yogurt drink, perfect with biryani',
    price: 40,
    imageUrl: 'https://images.unsplash.com/photo-1553361371-9b22f78e8b1d?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_02', name: 'Mango Lassi',
    description: 'Creamy mango yogurt smoothie made with fresh seasonal mangoes',
    price: 60,
    imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_03', name: 'Doodh Cha',
    description: 'Rich milk tea with ginger, cardamom & cinnamon — Bangladeshi special',
    price: 25,
    imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_04', name: 'Lemon Soda',
    description: 'Refreshing lemon soda with mint & a pinch of black salt',
    price: 35,
    imageUrl: 'https://images.unsplash.com/photo-1544145945-f90425340c7e?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_05', name: 'Aam Panna',
    description: 'Tangy raw mango drink with cumin, mint & sugar — summer favorite',
    price: 45,
    imageUrl: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),
  FoodItem(
    id: 'drink_06', name: 'Faluda',
    description: 'Colorful rose-flavored Faluda with vermicelli, basil seeds & ice cream',
    price: 80,
    imageUrl: 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.drinks,
  ),

  // ═══ SNACKS ═══
  FoodItem(
    id: 'snack_01', name: 'Fuchka (8 pcs)',
    description: 'Crispy hollow shells filled with spicy tamarind water, chickpeas & potatoes',
    price: 40,
    imageUrl: 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_02', name: 'Chotpoti',
    description: 'Spicy chickpea curry topped with boiled egg, onion & tamarind sauce',
    price: 50,
    imageUrl: 'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_03', name: 'Jhalmuri',
    description: 'Puffed rice mixed with mustard oil, green chili, onion & chanachur',
    price: 30,
    imageUrl: 'https://images.unsplash.com/photo-1555126634-323283e090fa?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_04', name: 'Singara (4 pcs)',
    description: 'Crispy fried pastry filled with spiced potatoes & peas — classic Bengali snack',
    price: 40,
    imageUrl: 'https://images.unsplash.com/photo-1630383249896-483b8fbfe782?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_05', name: 'Piyaju (6 pcs)',
    description: 'Crunchy onion fritters made with lentil batter — iftar staple',
    price: 30,
    imageUrl: 'https://images.unsplash.com/photo-1626132647523-66c6df867b7c?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),
  FoodItem(
    id: 'snack_06', name: 'Beguni (6 pcs)',
    description: 'Batter-fried eggplant slices — crispy outside, soft inside',
    price: 35,
    imageUrl: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.snacks,
  ),

  // ═══ MEDICINE ═══
  FoodItem(
    id: 'med_01', name: 'Napa Extra',
    description: 'Paracetamol 500mg + Caffeine 65mg — for headache, fever & body pain',
    price: 12,
    imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_02', name: 'Seclo 20mg',
    description: 'Omeprazole capsule for acidity, heartburn & gastric problems',
    price: 8,
    imageUrl: 'https://images.unsplash.com/photo-1550572017-edd951b55104?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_03', name: 'Ace Plus',
    description: 'Paracetamol + Caffeine tablet — fast relief from pain & fever',
    price: 10,
    imageUrl: 'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_04', name: 'Histacin',
    description: 'Chlorpheniramine maleate — for cold, allergies & runny nose',
    price: 6,
    imageUrl: 'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_05', name: 'Antacid Suspension',
    description: 'Liquid antacid for quick relief from gas, bloating & acidity',
    price: 65,
    imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_06', name: 'Alatrol 10mg',
    description: 'Cetirizine tablet for rapid allergy and cold relief',
    price: 5,
    imageUrl: 'https://images.unsplash.com/photo-1576671081837-49000212a370?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),
  FoodItem(
    id: 'med_07', name: 'Sergel 20mg',
    description: 'Esomeprazole capsule for severe gastric and ulcer protection',
    price: 10,
    imageUrl: 'https://images.unsplash.com/photo-1512069772995-ec65ed45afd6?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.medicine,
  ),

  // ═══ OTHERS ═══
  FoodItem(
    id: 'other_01', name: 'Miniket Rice 5kg',
    description: 'Premium quality Miniket rice — best for daily cooking',
    price: 450,
    imageUrl: 'https://images.unsplash.com/photo-1536304929831-ee1ca9d44906?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_02', name: 'Soybean Oil 5L',
    description: 'Teer soybean oil — pure & healthy cooking oil',
    price: 800,
    imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_03', name: 'Sugar 1kg',
    description: 'Refined white sugar for daily use',
    price: 120,
    imageUrl: 'https://images.unsplash.com/photo-1558642891-54be180ea339?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_04', name: 'Eggs (12 pcs)',
    description: 'Farm-fresh chicken eggs — protein-rich & nutritious',
    price: 160,
    imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_05', name: 'Fresh Milk 1L',
    description: 'Pasteurized fresh cow milk — Farm Fresh brand',
    price: 85,
    imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_06', name: 'Radhuni Halim Mix',
    description: 'Ready to cook traditional halim mix powder',
    price: 55,
    imageUrl: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_07', name: 'Rupchanda Soybean Oil 2L',
    description: 'Premium fortified soybean oil',
    price: 340,
    imageUrl: 'https://images.unsplash.com/photo-1625937286074-9ca519d5d9df?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
  ),
  FoodItem(
    id: 'other_08', name: 'Aarong Dairy Butter 200g',
    description: 'Fresh salted butter made from pure cow milk',
    price: 210,
    imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=400&q=80',
    category: ProductCategory.others,
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
        } else if (event == 'rider_stats_updated') {
          add(WebSocketRiderStatsReceived(data));
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

    on<SearchProducts>((event, emit) {
      final q = event.query.toLowerCase();
      final filtered = state.allProducts
          .where((item) =>
              item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q))
          .toList();
      emit(state.copyWith(menuItems: filtered, searchQuery: event.query));
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

      final updatedActiveOrders = List<Order>.from(state.activeOrders)..add(newOrder);

      emit(state.copyWith(
        activeOrders: updatedActiveOrders,
        isPlacingOrder: false,
        cart: const [],
      ));

      if (state.userEmail != null) {
        _saveActiveOrders(state.userEmail!, updatedActiveOrders);
      }

      // Send new order to Restaurant App via WebSocket
      _webSocketService.send('new_order', newOrder.toJson());
    });

    on<RateRider>((event, emit) {
      _webSocketService.send('rate_rider', {
        'riderName': event.riderName,
        'rating': event.rating,
      });
    });

    on<CancelOrder>((event, emit) async {
      final index = state.activeOrders.indexWhere((o) => o.id == event.orderId);
      if (index < 0) return;

      final order = state.activeOrders[index];
      // Only allow cancel if not yet accepted by restaurant
      if (order.status != OrderStatus.pending) return;

      final cancelledOrder = order.copyWith(status: OrderStatus.rejected);
      final updatedHistory = List<Order>.from(state.orderHistory)..add(cancelledOrder);
      final updatedActiveOrders = List<Order>.from(state.activeOrders)..removeAt(index);

      emit(state.copyWith(
        activeOrders: updatedActiveOrders,
        orderHistory: updatedHistory,
      ));

      if (state.userEmail != null) {
        await _saveOrderHistory(state.userEmail!, updatedHistory);
        await _saveActiveOrders(state.userEmail!, updatedActiveOrders);
      }

      // Notify restaurant that order was cancelled
      _webSocketService.send('order_status_updated', cancelledOrder.toJson());
    });

    on<InitializeUser>((event, emit) async {
      emit(state.copyWith(userEmail: event.email));
      await _loadOrderHistory(event.email, emit);
    });

    on<DeleteOrderHistory>((event, emit) async {
      final updatedHistory = state.orderHistory.where((o) => o.id != event.orderId).toList();
      emit(state.copyWith(orderHistory: updatedHistory));
      if (state.userEmail != null) {
        await _saveOrderHistory(state.userEmail!, updatedHistory);
      }
    });

    on<WebSocketOrderUpdateReceived>((event, emit) async {
      final orderJson = event.payload;
      try {
        final updatedOrder = Order.fromJson(orderJson);
        final index = state.activeOrders.indexWhere((o) => o.id == updatedOrder.id);
        
        if (index >= 0) {
          if (updatedOrder.status == OrderStatus.delivered || updatedOrder.status == OrderStatus.rejected) {
            final updatedHistory = List<Order>.from(state.orderHistory)..add(updatedOrder);
            final updatedActiveOrders = List<Order>.from(state.activeOrders)..removeAt(index);
            emit(state.copyWith(
              activeOrders: updatedActiveOrders,
              orderHistory: updatedHistory,
            ));
            if (state.userEmail != null) {
              await _saveOrderHistory(state.userEmail!, updatedHistory);
              await _saveActiveOrders(state.userEmail!, updatedActiveOrders);
            }
          } else {
            final updatedActiveOrders = List<Order>.from(state.activeOrders)..[index] = updatedOrder;
            emit(state.copyWith(activeOrders: updatedActiveOrders));
            if (state.userEmail != null) {
              await _saveActiveOrders(state.userEmail!, updatedActiveOrders);
            }
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    });

    on<WebSocketRiderLocationReceived>((event, emit) async {
      final locationData = event.payload;
      final orderId = locationData['orderId'] as String?;
      final riderName = locationData['riderName'] as String?;
      final latitude = (locationData['latitude'] as num?)?.toDouble();
      final longitude = (locationData['longitude'] as num?)?.toDouble();

      final index = state.activeOrders.indexWhere((o) => o.id == orderId);

      if (index >= 0 && latitude != null && longitude != null) {
        final updatedLocation = UserLocation(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now().toIso8601String(),
        );

        final updatedOrder = state.activeOrders[index].copyWith(
          riderName: riderName ?? state.activeOrders[index].riderName,
          riderLocation: updatedLocation,
        );

        final updatedActiveOrders = List<Order>.from(state.activeOrders)..[index] = updatedOrder;

        emit(state.copyWith(activeOrders: updatedActiveOrders));
        if (state.userEmail != null) {
          await _saveActiveOrders(state.userEmail!, updatedActiveOrders);
        }
      }
    });

    on<WebSocketRiderStatsReceived>((event, emit) {
      final stats = event.payload;
      final riderName = stats['riderName'] as String?;
      if (riderName != null) {
        final newStats = Map<String, dynamic>.from(state.riderStats);
        newStats[riderName] = stats;
        emit(state.copyWith(riderStats: newStats));
      }
    });

    on<ResetCustomerFlow>((event, emit) async {
      emit(state.copyWith(activeOrders: const []));
      if (state.userEmail != null) {
        await _saveActiveOrders(state.userEmail!, const []);
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _loadOrderHistory(String email, Emitter<CustomerState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load History
      final key = 'orderHistory_$email';
      final jsonList = prefs.getStringList(key);
      if (jsonList != null) {
        final history = jsonList.map((jsonStr) {
          return Order.fromJson(jsonDecode(jsonStr));
        }).toList();
        emit(state.copyWith(orderHistory: history));
      }

      // Load Active Orders
      final activeOrdersJson = prefs.getStringList('activeOrders_$email');
      if (activeOrdersJson != null) {
        final activeList = activeOrdersJson.map((jsonStr) => Order.fromJson(jsonDecode(jsonStr))).toList();
        // Filter out completed ones just in case
        final validActive = activeList.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.rejected).toList();
        emit(state.copyWith(activeOrders: validActive));
      } else {
        // Fallback for previous single activeOrder
        final singleActiveJson = prefs.getString('activeOrder_$email');
        if (singleActiveJson != null) {
           final o = Order.fromJson(jsonDecode(singleActiveJson));
           if (o.status != OrderStatus.delivered && o.status != OrderStatus.rejected) {
             emit(state.copyWith(activeOrders: [o]));
           }
           prefs.remove('activeOrder_$email');
        }
      }
    } catch (e) {
      print('Error loading order history: $e');
    }
  }

  Future<void> _saveOrderHistory(String email, List<Order> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'orderHistory_$email';
      final jsonList = history.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(key, jsonList);
    } catch (e) {
      print('Error saving order history: $e');
    }
  }

  Future<void> _saveActiveOrders(String email, List<Order> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'activeOrders_$email';
      if (orders.isEmpty) {
        await prefs.remove(key);
      } else {
        final jsonList = orders.map((o) => jsonEncode(o.toJson())).toList();
        await prefs.setStringList(key, jsonList);
      }
    } catch (e) {
      print('Error saving active orders: $e');
    }
  }
}
