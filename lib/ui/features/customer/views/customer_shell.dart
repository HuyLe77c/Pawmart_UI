import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  static const _destinations = [
    ('Trang chủ', '/customer/home'),
    ('Cửa hàng', '/customer/categories'),
    ('Tư vấn', '/customer/assistant'),
    ('Đơn hàng', '/customer/orders'),
    ('Hồ sơ', '/customer/profile'),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (item) => path == item.$2 || path.startsWith('${item.$2}/'),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PawmartColors.line)),
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => context.go(_destinations[index].$2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Cửa hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Tư vấn',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Đơn hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    ),
  );
}
