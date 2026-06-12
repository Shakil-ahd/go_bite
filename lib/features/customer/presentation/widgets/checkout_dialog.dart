import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/models.dart';
import '../../bloc/customer_bloc.dart';

// ═══════════════════════════════════════════
// ──── Checkout Location Helper ────
// ═══════════════════════════════════════════
void processCheckout(BuildContext context, UserProfile profile) {
  final TextEditingController addressController = TextEditingController(text: profile.deliveryAddress);
  
  // Use a small delay to ensure the calling context's modal (like a bottom sheet)
  // has completely closed before we push a new dialog. This prevents navigation crashes.
  Future.delayed(const Duration(milliseconds: 150), () {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Delivery Location', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Where should we deliver this order?', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Pickup/Delivery Point',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.home),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                final newAddress = addressController.text.trim();
                if (newAddress.isNotEmpty) {
                  Navigator.pop(dialogContext); // Close dialog
                  // Dispatch PlaceOrder using the root context
                  context.read<CustomerBloc>().add(PlaceOrder(
                    customerName: profile.fullName,
                    customerPhone: profile.phone,
                    deliveryAddress: newAddress,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Order', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  });
}
