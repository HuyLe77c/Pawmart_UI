import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../view_models/orders_view_model.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        OrdersViewModel(OrdersRepository(context.read<ApiClient>()))..load(),
    child: const _OrdersContent(),
  );
}

class _OrdersContent extends StatelessWidget {
  const _OrdersContent();

  static const _filters = [
    ('ALL', 'Tất cả'),
    ('PENDING', 'Chờ xác nhận'),
    ('CONFIRMED', 'Đang xử lý'),
    ('SHIPPING', 'Đang giao'),
    ('DELIVERED', 'Đã giao'),
    ('CANCELLED', 'Đã hủy'),
  ];

  @override
  Widget build(BuildContext context) => Consumer<OrdersViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đơn hàng của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter.$2),
                      selected: model.filter == filter.$1,
                      onSelected: (_) => model.load(status: filter.$1),
                      selectedColor: PawmartColors.green,
                      labelStyle: TextStyle(
                        color: model.filter == filter.$1
                            ? Colors.white
                            : PawmartColors.ink,
                      ),
                      showCheckmark: false,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: model.isLoading && model.orders.isEmpty
                ? const LoadingState()
                : model.errorMessage != null && model.orders.isEmpty
                ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
                : model.orders.isEmpty
                ? RefreshIndicator(
                    onRefresh: model.load,
                    child: ListView(
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          title: model.filter == 'ALL'
                              ? 'Bạn chưa có đơn hàng'
                              : 'Chưa có đơn hàng phù hợp',
                          message: model.filter == 'ALL'
                              ? 'Đơn hàng đã đặt sẽ xuất hiện tại đây.'
                              : 'Thử chọn trạng thái khác để xem đơn hàng.',
                          icon: Icons.inventory_2_outlined,
                          actionLabel: model.filter == 'ALL'
                              ? 'Khám phá sản phẩm'
                              : null,
                          onAction: model.filter == 'ALL'
                              ? () => context.go('/customer/categories')
                              : null,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: model.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      itemCount: model.orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _OrderCard(order: model.orders[index]),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderListItem order;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push(
        '/customer/orders/${Uri.encodeComponent(order.orderId)}',
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đơn #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: PawmartColors.ink,
                    ),
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy · HH:mm')
                  .format(order.createdAt.toLocal()),
              style: const TextStyle(color: PawmartColors.muted, fontSize: 12),
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _payment(order.paymentMethod),
                    style: const TextStyle(color: PawmartColors.muted),
                  ),
                ),
                Text(
                  formatVnd(order.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PawmartColors.greenDark,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: PawmartColors.muted),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  static String _payment(String value) => value == 'COD'
      ? 'Thanh toán khi nhận hàng'
      : 'Thanh toán ${value.toUpperCase()}';
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'PENDING' => ('Chờ xác nhận', Colors.orange),
      'CONFIRMED' => ('Đang xử lý', PawmartColors.green),
      'SHIPPING' => ('Đang giao', Colors.blue),
      'DELIVERED' => ('Đã giao', PawmartColors.greenDark),
      'CANCELLED' => ('Đã hủy', PawmartColors.error),
      _ => (status, PawmartColors.muted),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
