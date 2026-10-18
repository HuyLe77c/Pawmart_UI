import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.path, required this.child, super.key});
  final String path;
  final Widget child;

  int get _index => switch (path) {
    '/admin/products' => 1,
    '/admin/orders' => 2,
    '/admin/more' => 3,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: PawmartColors.greenPale,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: _index,
      onDestinationSelected: (index) => context.go(switch (index) {
        0 => '/admin/overview',
        1 => '/admin/products',
        2 => '/admin/orders',
        _ => '/admin/more',
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: PawmartColors.green),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: PawmartColors.green),
          label: 'Sản phẩm',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: PawmartColors.green),
          label: 'Đơn hàng',
        ),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Quản lý'),
      ],
    ),
  );
}
