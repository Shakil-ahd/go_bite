import 'package:equatable/equatable.dart';
import 'product_category.dart';
import 'food_review.dart';

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
  final double averageRating;
  final int ratingCount;
  final List<FoodReview> reviews;

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
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.reviews = const [],
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
        'averageRating': averageRating,
        'ratingCount': ratingCount,
        'reviews': reviews.map((r) => r.toJson()).toList(),
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
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => FoodReview.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
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
        averageRating,
        ratingCount,
        reviews,
      ];
}
