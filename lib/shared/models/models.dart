import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ─── Product Categories ───
enum ProductCategory {
  food,
  drinks,
  snacks,
  medicine,
  others,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.food:
        return 'Food';
      case ProductCategory.drinks:
        return 'Drinks';
      case ProductCategory.snacks:
        return 'Snacks';
      case ProductCategory.medicine:
        return 'Medicine';
      case ProductCategory.others:
        return 'Others';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.food:
        return '🍛';
      case ProductCategory.drinks:
        return '🥤';
      case ProductCategory.snacks:
        return '🍢';
      case ProductCategory.medicine:
        return '💊';
      case ProductCategory.others:
        return '📦';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategory.food:
        return Icons.restaurant;
      case ProductCategory.drinks:
        return Icons.local_cafe;
      case ProductCategory.snacks:
        return Icons.fastfood;
      case ProductCategory.medicine:
        return Icons.medical_services;
      case ProductCategory.others:
        return Icons.shopping_basket;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case ProductCategory.food:
        return [const Color(0xFFFF5722), const Color(0xFFFF9800)];
      case ProductCategory.drinks:
        return [const Color(0xFF2196F3), const Color(0xFF00BCD4)];
      case ProductCategory.snacks:
        return [const Color(0xFFFFC107), const Color(0xFFFF9800)];
      case ProductCategory.medicine:
        return [const Color(0xFF4CAF50), const Color(0xFF009688)];
      case ProductCategory.others:
        return [const Color(0xFF7C4DFF), const Color(0xFF536DFE)];
    }
  }
}

// ─── Order Status ───
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
        return 'Preparing';
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

// ─── User Profile ───
class UserProfile extends Equatable {
  final String firstName;
  final String lastName;
  final String? phone;
  final String email;
  final String password;
  final String deliveryAddress;
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.email,
    this.password = '',
    required this.deliveryAddress,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? password,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'password': password,
        'deliveryAddress': deliveryAddress,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        firstName: json['firstName'] ?? '',
        lastName: json['lastName'] ?? '',
        phone: json['phone'],
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        deliveryAddress: json['deliveryAddress'] ?? '',
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );

  @override
  List<Object?> get props => [firstName, lastName, phone, email, password, deliveryAddress, latitude, longitude];
}

// ─── User Location ───
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

// ─── Food / Product Item ───
class FoodItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final ProductCategory category;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category.name,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: ProductCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ProductCategory.food,
      ),
    );
  }

  @override
  List<Object?> get props => [id, name, description, price, imageUrl, category];
}

// ─── Cart Item ───
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

// ─── Order ───
class Order extends Equatable {
  final String id;
  final String restaurantName;
  final String customerName;
  final String customerPhone;
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
    required this.customerPhone,
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
    String? customerPhone,
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
      customerPhone: customerPhone ?? this.customerPhone,
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
        'customerPhone': customerPhone,
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
      customerPhone: json['customerPhone'] as String? ?? '',
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
        customerPhone,
        items,
        status,
        totalAmount,
        riderName,
        riderLocation,
        deliveryAddress,
      ];
}
