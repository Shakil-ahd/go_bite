import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/auth_interceptor.dart';
import '../../bloc/customer_bloc.dart';
import '../../profile_screen.dart';
import 'checkout_screen.dart';
import '../../../auth/login_screen.dart';

// ═══════════════════════════════════════════
// ──── Category Home Screen ────
// ═══════════════════════════════════════════
class CustomerCategoryHome extends StatefulWidget {
  const CustomerCategoryHome({super.key});

  @override
  State<CustomerCategoryHome> createState() => _CustomerCategoryHomeState();
}

class _CustomerCategoryHomeState extends State<CustomerCategoryHome> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerBloc>().add(LoadRestaurantMenu());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    String userName = 'Customer';
    String address = 'Dhaka';
    if (authState is AuthAuthenticated) {
      userName = authState.profile.fullName;
      address = authState.profile.deliveryAddress;
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Header ───
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, Colors.orange.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (authState is AuthAuthenticated)
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerProfileScreen())),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    authState.profile.firstName.isNotEmpty ? authState.profile.firstName[0].toUpperCase() : 'C',
                                    style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hi, ${authState.profile.firstName} 👋',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        authState.profile.deliveryAddress.length > 25 
                                            ? '${authState.profile.deliveryAddress.substring(0, 25)}...' 
                                            : authState.profile.deliveryAddress,
                                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome to GoBite 🍔',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Sign in to set your location',
                                style: TextStyle(fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            // Cart badge
                            BlocBuilder<CustomerBloc, CustomerState>(
                              builder: (context, state) {
                                final itemCount = state.cart.fold(0, (sum, i) => sum + i.quantity);
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 26),
                                      onPressed: () => _showCartSheet(context),
                                    ),
                                    if (itemCount > 0)
                                      Positioned(
                                        right: 4,
                                        top: 4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '$itemCount',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Search bar (visual only)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          Text(
                            'Search for food, medicine, snacks...',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Promo Banner Carousel ───
              SizedBox(
                height: 130,
                child: PageView(
                  controller: PageController(viewportFraction: 0.9),
                  children: [
                    _buildPromoCard(
                      title: '🔥 Free Delivery',
                      subtitle: 'On your first 3 orders!\nOrder now & save ৳50',
                      emoji: '🛵',
                      colors: [Colors.deepOrange.shade400, Colors.orange.shade300],
                    ),
                    _buildPromoCard(
                      title: '🎉 20% Discount',
                      subtitle: 'Use code GOBITE20\nValid on all food items',
                      emoji: '🍔',
                      colors: [Colors.purple.shade400, Colors.pink.shade300],
                    ),
                    _buildPromoCard(
                      title: '🌙 Midnight Offer',
                      subtitle: 'Craving at night?\nGet flat ৳100 off after 12 AM',
                      emoji: '🦉',
                      colors: [Colors.blue.shade800, Colors.indigo.shade400],
                    ),
                    _buildPromoCard(
                      title: '💊 Stay Healthy',
                      subtitle: '10% off on all medicines\nFree delivery on prescriptions',
                      emoji: '🏥',
                      colors: [Colors.teal.shade500, Colors.green.shade300],
                    ),
                    _buildPromoCard(
                      title: '🥦 Fresh Grocery',
                      subtitle: 'Weekly Bazar Offer\nSave ৳200 on cart above ৳1000',
                      emoji: '🛒',
                      colors: [Colors.red.shade400, Colors.deepOrange.shade300],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Categories Title ───
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'What do you need?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select a category to browse products',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Category Grid ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: ProductCategory.values.map((cat) {
                    return _buildCategoryCard(context, cat);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Cart Summary Bar ───
              BlocBuilder<CustomerBloc, CustomerState>(
                builder: (context, state) {
                  if (state.cart.isEmpty) return const SizedBox.shrink();
                  final itemCount = state.cart.fold(0, (sum, i) => sum + i.quantity);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$itemCount items in cart',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            Text(
                              '৳${state.cartTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () => requireLogin(context, () => _showCartSheet(context)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.shopping_cart, size: 18),
                          label: const Text('View Cart', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard({required String title, required String subtitle, required String emoji, required List<Color> colors}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 48)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ProductCategory cat) {
    return GestureDetector(
      onTap: () => context.read<CustomerBloc>().add(SelectCategory(cat)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cat.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: cat.gradientColors.last.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background emoji
            Positioned(
              right: -12,
              bottom: -12,
              child: Text(
                cat.emoji,
                style: const TextStyle(fontSize: 70, color: Colors.white24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Icon(cat.icon, color: cat.gradientColors.first, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    cat.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getCategorySubtitle(cat),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategorySubtitle(ProductCategory cat) {
    switch (cat) {
      case ProductCategory.food:
        return 'Biryani, Kacchi & more';
      case ProductCategory.drinks:
        return 'Borhani, Lassi, Cha';
      case ProductCategory.snacks:
        return 'Fuchka, Chotpoti';
      case ProductCategory.medicine:
        return 'Napa, Seclo & more';
      case ProductCategory.others:
        return 'Rice, Oil, Eggs';
    }
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return BlocProvider.value(
          value: context.read<CustomerBloc>(),
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: BlocBuilder<CustomerBloc, CustomerState>(
                  builder: (context, state) {
                    if (state.cart.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Your cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Order',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            TextButton(
                              onPressed: () => context.read<CustomerBloc>().add(ClearCart()),
                              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.cart.length,
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Category icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: item.foodItem.category.gradientColors),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(item.foodItem.category.icon, color: Colors.white, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.foodItem.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          Text(
                                            '৳${item.foodItem.price.toStringAsFixed(0)} x ${item.quantity}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _cartButton(
                                          Icons.remove,
                                          () => context.read<CustomerBloc>().add(RemoveFromCart(item.foodItem)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        _cartButton(
                                          Icons.add,
                                          () => context.read<CustomerBloc>().add(AddToCart(item.foodItem)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                              '৳${state.cartTotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              final authState = context.read<AuthBloc>().state;
                              if (authState is AuthAuthenticated) {
                                Navigator.pop(modalContext);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                              } else {
                                Navigator.pop(modalContext);
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text(
                              'Confirm & Place Order',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _cartButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.black12,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}
