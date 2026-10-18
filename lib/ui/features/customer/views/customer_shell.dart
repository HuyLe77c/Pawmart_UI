import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.path, required this.child});
  final String path;
  final Widget child;

  static const _destinations = [
    ('Trang chủ', Icons.home_rounded, '/customer/home'),
    ('Danh mục', Icons.format_list_bulleted_rounded, '/customer/categories'),
    ('Tư vấn', Icons.chat_bubble_outline_rounded, '/customer/assistant'),
    ('Đơn hàng', Icons.shopping_bag_rounded, '/customer/orders'),
    ('Hồ sơ', Icons.person_rounded, '/customer/profile'),
  ];

  int get _selectedIndex {
    final index = _destinations.indexWhere(
      (item) => path == item.$3 || path.startsWith('${item.$3}/'),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: PawmartColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var index = 0; index < _destinations.length; index++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: index == _selectedIndex,
                    label: _destinations[index].$1,
                    child: InkWell(
                      onTap: () => context.go(_destinations[index].$3),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            width: 32,
                            color: index == _selectedIndex
                                ? PawmartColors.green
                                : Colors.transparent,
                          ),
                          const SizedBox(height: 9),
                          Icon(
                            _destinations[index].$2,
                            size: 22,
                            color: index == _selectedIndex
                                ? PawmartColors.green
                                : PawmartColors.muted,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _destinations[index].$1,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              color: index == _selectedIndex
                                  ? PawmartColors.green
                                  : PawmartColors.muted,
                              fontWeight: index == _selectedIndex
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
