import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/customer_bloc.dart';
import 'payment_screen.dart';
import 'tracking_screen.dart';

enum PaymentMethod { cashOnDelivery, bkash }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _paymentMethod = PaymentMethod.cashOnDelivery;
  String? _customPhone;
  String? _customAddress;

  void _showEditDialog(String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _onConfirmOrder(UserProfile profile) {
    final phoneToUse = _customPhone ?? profile.phone ?? 'N/A';
    final addressToUse = _customAddress ?? profile.deliveryAddress;

    if (_paymentMethod == PaymentMethod.bkash) {
      // Navigate to bKash mock screen
      // We also need to pass the custom phone and address if they changed it!
      // But PaymentScreen takes profile. Let's create a temporary modified profile.
      final modifiedProfile = profile.copyWith(
        phone: phoneToUse,
        deliveryAddress: addressToUse,
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaymentScreen(profile: modifiedProfile)),
      );
    } else {
      // Cash on Delivery - Place order immediately
      context.read<CustomerBloc>().add(
        PlaceOrder(
          customerName: profile.fullName,
          customerPhone: phoneToUse,
          deliveryAddress: addressToUse,
        ),
      );

      // Ensure we pop everything except the dashboard, then push tracking
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerTrackingScreen()),
        (route) => route.isFirst,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final profile = authState.profile;

            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                foregroundColor: AppTheme.textPrimary,
              ),
              backgroundColor: Colors.grey.shade50,
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // User Details
                          const Text(
                            'Delivery Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  Icons.person,
                                  'Name',
                                  profile.fullName,
                                ),
                                const Divider(height: 24),
                                _buildDetailRow(
                                  Icons.phone,
                                  'Phone',
                                  _customPhone ?? profile.phone ?? 'N/A',
                                  onEdit: () {
                                    _showEditDialog(
                                      'Phone Number',
                                      _customPhone ?? profile.phone ?? '',
                                      (newVal) => setState(() => _customPhone = newVal),
                                    );
                                  },
                                ),
                                const Divider(height: 24),
                                _buildDetailRow(
                                  Icons.location_on,
                                  'Address',
                                  _customAddress ?? profile.deliveryAddress,
                                  onEdit: () {
                                    _showEditDialog(
                                      'Delivery Address',
                                      _customAddress ?? profile.deliveryAddress,
                                      (newVal) => setState(() => _customAddress = newVal),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Order Summary
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              children: [
                                ...customerState.cart.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.quantity}x ${item.foodItem.name}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          '৳${item.totalPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 24, thickness: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '৳${customerState.cartTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Payment Options
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Column(
                              children: [
                                RadioListTile<PaymentMethod>(
                                  title: const Text(
                                    'Cash on Delivery',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Pay when you receive the order',
                                  ),
                                  value: PaymentMethod.cashOnDelivery,
                                  groupValue: _paymentMethod,
                                  onChanged: (val) =>
                                      setState(() => _paymentMethod = val!),
                                  activeColor: AppTheme.primary,
                                  secondary: const Icon(
                                    Icons.money,
                                    color: Colors.green,
                                  ),
                                ),
                                const Divider(height: 1),
                                RadioListTile<PaymentMethod>(
                                  title: const Text(
                                    'bKash Payment',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Pay securely via bKash',
                                  ),
                                  value: PaymentMethod.bkash,
                                  groupValue: _paymentMethod,
                                  onChanged: (val) =>
                                      setState(() => _paymentMethod = val!),
                                  activeColor: AppTheme.primary,
                                  secondary: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Confirm Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _onConfirmOrder(profile),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _paymentMethod == PaymentMethod.bkash
                                  ? 'Proceed to Pay'
                                  : 'Confirm Order',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, {VoidCallback? onEdit}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade400, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit, size: 20, color: AppTheme.primary),
            onPressed: onEdit,
            tooltip: 'Edit $title',
          ),
      ],
    );
  }
}
