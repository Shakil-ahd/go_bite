import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/customer_bloc.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'tracking_screen.dart';

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
