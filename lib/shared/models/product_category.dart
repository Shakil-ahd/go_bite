import 'package:flutter/material.dart';

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
