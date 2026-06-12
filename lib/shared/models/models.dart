import 'package:equatable/equatable.dart';

enum UserRole {
  customer,
  restaurant,
  rider,
}

enum OrderStatus {
  pending,
  accepted,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  rejected,
}

extension OrderStatusExtension on OrderStatus {
  String get displayValue {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.accepted:
        return 'Accepted';
      case OrderStatus.preparing:
        return 'Preparing Food';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.rejected:
        return 'Rejected';
    }
  }
}

class UserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String timestamp;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
      };

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}

class FoodItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, imageUrl];
}

class CartItem extends Equatable {
  final FoodItem foodItem;
  final int quantity;

  const CartItem({
    required this.foodItem,
    required this.quantity,
  });

  double get totalPrice => foodItem.price * quantity;

  Map<String, dynamic> toJson() => {
        'foodItem': foodItem.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      foodItem: FoodItem.fromJson(json['foodItem'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  @override
  List<Object?> get props => [foodItem, quantity];
}

class Order extends Equatable {
  final String id;
  final String restaurantName;
  final String customerName;
  final List<CartItem> items;
  final OrderStatus status;
  final double totalAmount;
  final String? riderName;
  final UserLocation? riderLocation;
  final String deliveryAddress;

  const Order({
    required this.id,
    required this.restaurantName,
    required this.customerName,
    required this.items,
    required this.status,
    required this.totalAmount,
    this.riderName,
    this.riderLocation,
    required this.deliveryAddress,
  });

  Order copyWith({
    String? id,
    String? restaurantName,
    String? customerName,
    List<CartItem>? items,
    OrderStatus? status,
    double? totalAmount,
    String? riderName,
    UserLocation? riderLocation,
    String? deliveryAddress,
  }) {
    return Order(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      riderName: riderName ?? this.riderName,
      riderLocation: riderLocation ?? this.riderLocation,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'restaurantName': restaurantName,
        'customerName': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'status': status.name,
        'totalAmount': totalAmount,
        'riderName': riderName,
        'riderLocation': riderLocation?.toJson(),
        'deliveryAddress': deliveryAddress,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      restaurantName: json['restaurantName'] as String,
      customerName: json['customerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((i) => CartItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      riderName: json['riderName'] as String?,
      riderLocation: json['riderLocation'] != null
          ? UserLocation.fromJson(json['riderLocation'] as Map<String, dynamic>)
          : null,
      deliveryAddress: json['deliveryAddress'] as String,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantName,
        customerName,
        items,
        status,
        totalAmount,
        riderName,
        riderLocation,
        deliveryAddress,
      ];
}
