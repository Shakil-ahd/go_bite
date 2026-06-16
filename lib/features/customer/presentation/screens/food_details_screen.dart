import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/login_screen.dart';
import '../../bloc/customer_bloc.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String foodId;
  const FoodDetailsScreen({super.key, required this.foodId});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  int _userRating = 5;
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitReview(FoodItem food, String userName) {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment for your review.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<CustomerBloc>().add(
          RateFoodItem(
            foodId: food.id,
            rating: _userRating,
            review: _commentController.text.trim(),
            userName: userName,
          ),
        );

    _commentController.clear();
    setState(() {
      _userRating = 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your review has been submitted.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final foodIndex = state.allProducts.indexWhere((item) => item.id == widget.foodId);
        if (foodIndex < 0) {
          return Scaffold(
            appBar: AppBar(title: const Text('Food Details')),
            body: const Center(child: Text('Food item not found')),
          );
        }

        final food = state.allProducts[foodIndex];
        final cartItem = state.cart.where((c) => c.foodItem.id == food.id).firstOrNull;
        final qty = cartItem?.quantity ?? 0;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ─── Big Image Header ───
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      food.imageUrl.isNotEmpty
                          ? Image.network(
                              food.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: food.category.gradientColors),
                                ),
                                child: Icon(food.category.icon, color: Colors.white, size: 80),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: food.category.gradientColors),
                              ),
                              child: Icon(food.category.icon, color: Colors.white, size: 80),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black35, Colors.transparent, Colors.black60],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Food Info Card ───
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: food.category.gradientColors.first.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          food.category.displayName,
                          style: TextStyle(
                            color: food.category.gradientColors.first,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Food name and price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '৳${food.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Average Rating Summary
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            food.ratingCount > 0
                                ? food.averageRating.toStringAsFixed(1)
                                : '0.0',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${food.ratingCount} reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        food.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),

                      // Restaurant info
                      if (food.restaurantName != null) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            if (food.restaurantImageUrl != null && food.restaurantImageUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(food.restaurantImageUrl!),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.storefront, size: 20, color: AppTheme.primary),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    food.restaurantName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (food.restaurantAddress != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      food.restaurantAddress!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── Add/Remove Cart Section ───
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      qty == 0
                          ? ElevatedButton.icon(
                              onPressed: () => context.read<CustomerBloc>().add(AddToCart(food)),
                              icon: const Icon(Icons.add_shopping_cart, size: 18),
                              label: const Text('Add to Cart'),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            )
                          : Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                                  onPressed: () => context.read<CustomerBloc>().add(RemoveFromCart(food)),
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                  onPressed: () => context.read<CustomerBloc>().add(AddToCart(food)),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              // ─── Rating and Review Input Form ───
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rate this Food',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      if (authState is AuthAuthenticated) ...[
                        Row(
                          children: List.generate(5, (index) {
                            return IconButton(
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                index < _userRating ? Icons.star : Icons.star_border,
                                color: Colors.orange,
                                size: 28,
                              ),
                              onPressed: () => setState(() => _userRating = index + 1),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your review about this food...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              final name = '${authState.profile.firstName} ${authState.profile.lastName}'.trim();
                              _submitReview(food, name.isNotEmpty ? name : 'User');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Submit Review',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'You must be logged in to rate and review this item.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Login / Sign Up',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── Reviews List Section ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Customer Reviews',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${food.reviews.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              food.reviews.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final review = food.reviews[food.reviews.length - 1 - index]; // latest reviews first
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      review.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        return Icon(
                                          starIdx < review.rating ? Icons.star : Icons.star_border,
                                          color: Colors.orange,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review.comment,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: food.reviews.length,
                      ),
                    ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          ),
        );
      },
    );
  }
}
