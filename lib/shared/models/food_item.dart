import 'package:equatable/equatable.dart';
import 'product_category.dart';

class FoodItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final ProductCategory category;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantAddress;
  final String? restaurantImageUrl;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantImageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category.name,
        if (restaurantId != null) 'restaurantId': restaurantId,
        if (restaurantName != null) 'restaurantName': restaurantName,
        if (restaurantAddress != null) 'restaurantAddress': restaurantAddress,
        if (restaurantImageUrl != null) 'restaurantImageUrl': restaurantImageUrl,
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
      restaurantId: json['restaurantId'] as String?,
      restaurantName: json['restaurantName'] as String?,
      restaurantAddress: json['restaurantAddress'] as String?,
      restaurantImageUrl: json['restaurantImageUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        imageUrl,
        category,
        restaurantId,
        restaurantName,
        restaurantAddress,
        restaurantImageUrl,
      ];
}
