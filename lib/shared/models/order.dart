import 'package:equatable/equatable.dart';
import 'order_status.dart';
import 'cart_item.dart';
import 'user_location.dart';

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
  final DateTime createdAt;
  final String? restaurantId;
  final String? restaurantAddress;

  Order({
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
    DateTime? createdAt,
    this.restaurantId,
    this.restaurantAddress,
  }) : createdAt = createdAt ?? DateTime.now();

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
    DateTime? createdAt,
    String? restaurantId,
    String? restaurantAddress,
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
      createdAt: createdAt ?? this.createdAt,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
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
        'createdAt': createdAt.toIso8601String(),
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (restaurantAddress != null) 'restaurantAddress': restaurantAddress,
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
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      restaurantId: json['restaurantId'] as String?,
      restaurantAddress: json['restaurantAddress'] as String?,
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
        createdAt,
        restaurantId,
        restaurantAddress,
      ];
}
