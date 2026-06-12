import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../auth/bloc/auth_bloc.dart';
import 'bloc/customer_bloc.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state.activeOrder != null) {
          return const CustomerTrackingScreen();
        }
        if (state.selectedCategory != null) {
          return const CustomerMenuScreen();
        }
        return const CustomerCategoryHome();
      },
    );
  }
}

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
      userName = authState.profile.name;
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $userName 👋',
                              style: const TextStyle(
                                fontSize: 22,
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
                                  address,
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
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
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white70),
                              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
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
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10),
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

              // ─── Promo Banner ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange.shade400, Colors.orange.shade300],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🔥 Free Delivery',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'On your first 3 orders!\nOrder now & save ৳50',
                              style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      Text('🛵', style: TextStyle(fontSize: 48)),
                    ],
                  ),
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
                      boxShadow: [
                        BoxShadow(color: AppTheme.secondary.withOpacity(0.3), blurRadius: 10),
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
                          onPressed: () => _showCartSheet(context),
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: cat.gradientColors[0].withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background emoji
            Positioned(
              right: -8,
              bottom: -8,
              child: Text(
                cat.emoji,
                style: TextStyle(fontSize: 56, color: Colors.white.withOpacity(0.2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    cat.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _getCategorySubtitle(cat),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
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
                                context.read<CustomerBloc>().add(PlaceOrder(
                                      customerName: authState.profile.name,
                                      customerPhone: authState.profile.phone,
                                      deliveryAddress: authState.profile.deliveryAddress,
                                    ));
                              }
                              Navigator.pop(modalContext);
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
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: AppTheme.primary),
      ),
    );
  }
}


// ═══════════════════════════════════════════
// ──── Menu Screen (Category Filtered) ────
// ═══════════════════════════════════════════
class CustomerMenuScreen extends StatelessWidget {
  const CustomerMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final cat = state.selectedCategory!;
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => context.read<CustomerBloc>().add(GoBackToCategories()),
            ),
            title: Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(cat.displayName),
              ],
            ),
            actions: [
              BlocBuilder<CustomerBloc, CustomerState>(
                builder: (ctx, s) {
                  final count = s.cart.fold(0, (sum, i) => sum + i.quantity);
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: () => _showCartFromMenu(context),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: Text(
                              '$count',
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
          body: state.menuItems.isEmpty
              ? const Center(child: Text('No items in this category'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.menuItems.length,
                  itemBuilder: (context, index) {
                    final food = state.menuItems[index];
                    return _buildMenuItem(context, food);
                  },
                ),
          bottomNavigationBar: BlocBuilder<CustomerBloc, CustomerState>(
            builder: (context, state) {
              if (state.cart.isEmpty) return const SizedBox.shrink();
              final itemCount = state.cart.fold(0, (sum, i) => sum + i.quantity);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -5)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemCount items',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '৳${state.cartTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCartFromMenu(context),
                      icon: const Icon(Icons.shopping_cart, size: 18),
                      label: const Text('View Cart'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, FoodItem food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Category colored icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: food.category.gradientColors),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(food.category.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    food.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '৳${food.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => context.read<CustomerBloc>().add(AddToCart(food)),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartFromMenu(BuildContext context) {
    // Reuse the same cart sheet from CustomerCategoryHome
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
                      return const Center(child: Text('Your cart is empty'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Your Order', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: state.cart.length,
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: item.foodItem.category.gradientColors),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.foodItem.category.icon, color: Colors.white, size: 20),
                                ),
                                title: Text(item.foodItem.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('৳${item.foodItem.price.toStringAsFixed(0)} x ${item.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
                                      onPressed: () => context.read<CustomerBloc>().add(RemoveFromCart(item.foodItem)),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                      onPressed: () => context.read<CustomerBloc>().add(AddToCart(item.foodItem)),
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
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary),
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
                                context.read<CustomerBloc>().add(PlaceOrder(
                                      customerName: authState.profile.name,
                                      customerPhone: authState.profile.phone,
                                      deliveryAddress: authState.profile.deliveryAddress,
                                    ));
                              }
                              Navigator.pop(modalContext);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Confirm & Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
}


// ═══════════════════════════════════════════
// ──── Enhanced Live Tracking Screen ────
// ═══════════════════════════════════════════
class CustomerTrackingScreen extends StatelessWidget {
  const CustomerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
        ),
      ),
      body: BlocBuilder<CustomerBloc, CustomerState>(
        builder: (context, state) {
          final order = state.activeOrder;
          if (order == null) return const Center(child: Text('No active order'));

          return Column(
            children: [
              // Enhanced Map
              Expanded(
                child: Container(
                  color: const Color(0xFFE8F5E9),
                  child: Stack(
                    children: [
                      // Enhanced canvas map
                      Positioned.fill(
                        child: CustomPaint(
                          painter: EnhancedMapPainter(
                            riderLocation: order.riderLocation,
                            orderStatus: order.status,
                          ),
                        ),
                      ),

                      // Status overlay card
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(order.status),
                                    color: _getStatusColor(order.status),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Status',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      Text(
                                        order.status.displayValue,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Rider location info
                      if (order.riderLocation != null)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🏍️ Lat: ${order.riderLocation!.latitude.toStringAsFixed(4)}, Lng: ${order.riderLocation!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '৳${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.motorcycle, color: Colors.white),
                      ),
                      title: Text(order.riderName ?? 'Searching for Rider...'),
                      subtitle: const Text('Your GoBite Delivery Partner'),
                      trailing: order.riderName != null
                          ? IconButton(
                              icon: const Icon(Icons.phone, color: Colors.green),
                              onPressed: () {},
                            )
                          : null,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(order.deliveryAddress, style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.read<CustomerBloc>().add(ResetCustomerFlow()),
                        child: const Text('Back to Home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.accepted: return Colors.blue;
      case OrderStatus.preparing: return Colors.amber;
      case OrderStatus.readyForPickup: return Colors.teal;
      case OrderStatus.outForDelivery: return Colors.indigo;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.rejected: return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.hourglass_top;
      case OrderStatus.accepted: return Icons.check_circle;
      case OrderStatus.preparing: return Icons.restaurant;
      case OrderStatus.readyForPickup: return Icons.shopping_bag;
      case OrderStatus.outForDelivery: return Icons.motorcycle;
      case OrderStatus.delivered: return Icons.home;
      case OrderStatus.rejected: return Icons.cancel;
    }
  }
}


// ═══════════════════════════════════════════
// ──── Enhanced Map Painter (Dhaka) ────
// ═══════════════════════════════════════════
class EnhancedMapPainter extends CustomPainter {
  final UserLocation? riderLocation;
  final OrderStatus orderStatus;

  EnhancedMapPainter({this.riderLocation, required this.orderStatus});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFF1F8E9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw grid streets
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Horizontal streets
    for (int i = 1; i < 8; i++) {
      double y = size.height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), streetPaint);
    }
    // Vertical streets
    for (int i = 1; i < 6; i++) {
      double x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), streetPaint);
    }

    // Draw main roads (thicker)
    final mainRoadPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 6;
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.4),
      mainRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, 0),
      Offset(size.width * 0.35, size.height),
      mainRoadPaint,
    );

    // Landmark labels
    _drawLandmarkLabel(canvas, 'Gulshan-2', Offset(size.width * 0.12, size.height * 0.12));
    _drawLandmarkLabel(canvas, 'Banani', Offset(size.width * 0.55, size.height * 0.2));
    _drawLandmarkLabel(canvas, 'Farmgate', Offset(size.width * 0.3, size.height * 0.55));
    _drawLandmarkLabel(canvas, 'Dhanmondi', Offset(size.width * 0.65, size.height * 0.75));

    // Green areas (parks)
    final parkPaint = Paint()..color = const Color(0xFFC8E6C9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width * 0.75, size.height * 0.45), width: 40, height: 30),
        const Radius.circular(6),
      ),
      parkPaint,
    );

    // Route path
    final restaurantPoint = Offset(size.width * 0.15, size.height * 0.2);
    final customerPoint = Offset(size.width * 0.8, size.height * 0.8);

    // Draw route dotted line
    final routePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final routePath = Path()
      ..moveTo(restaurantPoint.dx, restaurantPoint.dy)
      ..cubicTo(
        size.width * 0.2, size.height * 0.5,
        size.width * 0.6, size.height * 0.5,
        customerPoint.dx, customerPoint.dy,
      );

    // Dashed effect
    final dashPath = _createDashedPath(routePath, 8, 5);
    canvas.drawPath(dashPath, routePaint);

    // Draw Restaurant marker
    _drawEnhancedMarker(canvas, restaurantPoint, const Color(0xFFE53935), '🍳', 'Restaurant');
    // Draw Customer marker
    _drawEnhancedMarker(canvas, customerPoint, const Color(0xFF43A047), '🏠', 'You');

    // Draw Rider if available
    if (riderLocation != null) {
      // Dhaka coordinates:
      // Restaurant: 23.7925, 90.4078 (Gulshan-2)
      // Customer: 23.7461, 90.3742 (Dhanmondi)
      const startLat = 23.7925;
      const endLat = 23.7461;

      final latDiff = endLat - startLat; // negative
      double progress = (riderLocation!.latitude - startLat) / latDiff;
      progress = progress.clamp(0.0, 1.0);

      final riderPoint = _getPointOnBezier(
        restaurantPoint,
        Offset(size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.6, size.height * 0.5),
        customerPoint,
        progress,
      );

      // Rider trail (colored portion of route)
      final trailPaint = Paint()
        ..color = const Color(0xFF1565C0)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      final trailPath = Path()
        ..moveTo(restaurantPoint.dx, restaurantPoint.dy)
        ..cubicTo(
          size.width * 0.2, size.height * 0.5,
          size.width * 0.6, size.height * 0.5,
          customerPoint.dx, customerPoint.dy,
        );

      // Only draw up to rider position
      final trailMetrics = trailPath.computeMetrics().first;
      final trailLength = trailMetrics.length * progress;
      if (trailLength > 0) {
        final extractedPath = trailMetrics.extractPath(0, trailLength);
        canvas.drawPath(extractedPath, trailPaint);
      }

      // Rider glow effect
      final glowPaint = Paint()
        ..color = const Color(0xFF1565C0).withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(riderPoint, 20, glowPaint);

      _drawEnhancedMarker(canvas, riderPoint, const Color(0xFF1565C0), '🏍️', 'Rider');

      // Progress percentage
      final progressText = '${(progress * 100).toInt()}%';
      final progressPainter = TextPainter(textDirection: TextDirection.ltr);
      progressPainter.text = TextSpan(
        text: progressText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      );
      progressPainter.layout();
      progressPainter.paint(canvas, riderPoint + const Offset(20, -8));
    }
  }

  void _drawLandmarkLabel(Canvas canvas, String text, Offset pos) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: 10,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
      ),
    );
    tp.layout();
    tp.paint(canvas, pos);
  }

  void _drawEnhancedMarker(Canvas canvas, Offset pos, Color color, String emoji, String label) {
    // Shadow
    final shadowPaint = Paint()..color = color.withOpacity(0.2);
    canvas.drawCircle(pos, 24, shadowPaint);

    // Outer ring
    final outerPaint = Paint()..color = color;
    canvas.drawCircle(pos, 18, outerPaint);

    // White inner ring
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 14, innerPaint);

    // Emoji text
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(text: emoji, style: const TextStyle(fontSize: 14));
    tp.layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

    // Label below marker
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    labelPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(pos.dx - labelPainter.width / 2, pos.dy + 22));
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = min(distance + dashLength, metric.length);
        dashedPath.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gapLength;
      }
    }
    return dashedPath;
  }

  Offset _getPointOnBezier(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;
    final double uuu = uu * u;
    final double ttt = tt * t;

    double x = uuu * p0.dx;
    x += 3 * uu * t * p1.dx;
    x += 3 * u * tt * p2.dx;
    x += ttt * p3.dx;

    double y = uuu * p0.dy;
    y += 3 * uu * t * p1.dy;
    y += 3 * u * tt * p2.dy;
    y += ttt * p3.dy;

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(covariant EnhancedMapPainter oldDelegate) {
    return oldDelegate.riderLocation != riderLocation ||
        oldDelegate.orderStatus != orderStatus;
  }
}
