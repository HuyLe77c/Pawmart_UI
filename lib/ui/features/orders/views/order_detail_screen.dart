import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../view_models/orders_view_model.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => OrderDetailViewModel(
      OrdersRepository(context.read<ApiClient>()),
      orderId,
    )..load(),
    child: const _OrderDetailContent(),
  );
}

class _OrderDetailContent extends StatelessWidget {
  const _OrderDetailContent();

  Future<void> _cancel(BuildContext context, OrderDetailViewModel model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text(
          'Đơn hàng sẽ được hủy theo trạng thái hiện tại của hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final cancelled = await model.cancel();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cancelled
              ? 'Đã hủy đơn hàng.'
              : model.errorMessage ?? 'Không thể hủy đơn.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<OrderDetailViewModel>(
    builder: (context, model, _) {
      final order = model.order;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            order == null ? 'Chi tiết đơn hàng' : 'Theo dõi #${order.orderId}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: model.isLoading && order == null
            ? const LoadingState()
            : model.errorMessage != null && order == null
            ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
            : order == null
            ? const SizedBox.shrink()
            : RefreshIndicator(
                onRefresh: model.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _TrackingMapCard(order: order),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: PawmartColors.greenPale,
                          child: Icon(
                            Icons.location_on_outlined,
                            color: PawmartColors.green,
                          ),
                        ),
                        title: const Text('Địa chỉ nhận hàng'),
                        subtitle: Text(
                          '${order.recipientName} · ${order.recipientPhone}\n${order.shippingAddress}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Trạng thái đơn hàng',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (var i = 0; i < order.history.length; i++)
                              _HistoryStep(
                                item: order.history[i],
                                isLast: i == order.history.length - 1,
                                current: i == order.history.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Sản phẩm trong đơn',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Column(
                        children: [
                          for (final item in order.items)
                            ListTile(
                              title: Text(item.productName),
                              subtitle: Text('Số lượng: ${item.quantity}'),
                              trailing: Text(
                                formatVnd(item.lineTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _MoneyRow(label: 'Tạm tính', value: order.subtotal),
                            if (order.discount > 0)
                              _MoneyRow(
                                label: 'Giảm giá',
                                value: -order.discount,
                              ),
                            _MoneyRow(
                              label: 'Phí giao hàng',
                              value: order.shippingFee,
                            ),
                            const Divider(height: 20),
                            _MoneyRow(
                              label: 'Tổng cộng',
                              value: order.total,
                              bold: true,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Thanh toán: ${order.paymentMethod == 'COD' ? 'Khi nhận hàng' : order.paymentMethod}',
                                style: const TextStyle(
                                  color: PawmartColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (model.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        model.errorMessage!,
                        style: const TextStyle(color: PawmartColors.error),
                      ),
                    ],
                    if (order.status == 'PENDING') ...[
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: model.isCancelling
                            ? null
                            : () => _cancel(context, model),
                        icon: const Icon(
                          Icons.close,
                          color: PawmartColors.error,
                        ),
                        label: const Text(
                          'Hủy đơn hàng',
                          style: TextStyle(color: PawmartColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      );
    },
  );
}

class _TrackingMapCard extends StatelessWidget {
  const _TrackingMapCard({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final label = switch (order.status) {
      'PENDING' => 'Đơn hàng đang chờ xác nhận',
      'CONFIRMED' => 'Đơn hàng đang được xử lý',
      'SHIPPING' => 'Đơn hàng đang được giao',
      'DELIVERED' => 'Đơn hàng đã giao',
      'CANCELLED' => 'Đơn hàng đã hủy',
      _ => 'Theo dõi đơn hàng',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawmartColors.greenPale,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.local_shipping_outlined,
              color: PawmartColors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cập nhật theo trạng thái đơn từ cửa hàng.',
                  style: TextStyle(color: PawmartColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryStep extends StatelessWidget {
  const _HistoryStep({
    required this.item,
    required this.isLast,
    required this.current,
  });
  final OrderStatusHistory item;
  final bool isLast;
  final bool current;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: current
                      ? PawmartColors.green
                      : PawmartColors.greenPale,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  current ? Icons.check : Icons.check,
                  size: 14,
                  color: current ? Colors.white : PawmartColors.green,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: PawmartColors.greenPale),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _status(item.status),
                  style: TextStyle(
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: current
                        ? PawmartColors.greenDark
                        : PawmartColors.ink,
                  ),
                ),
                Text(
                  DateFormat('dd/MM · HH:mm').format(item.createdAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: PawmartColors.muted,
                  ),
                ),
                if (item.note?.isNotEmpty ?? false)
                  Text(
                    item.note!,
                    style: const TextStyle(color: PawmartColors.muted),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  static String _status(String value) => switch (value) {
    'PENDING' => 'Đã đặt hàng',
    'CONFIRMED' => 'Đang xử lý',
    'SHIPPING' => 'Đang giao hàng',
    'DELIVERED' => 'Đã giao thành công',
    'CANCELLED' => 'Đã hủy',
    _ => value,
  };
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          formatVnd(value),
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
            color: bold ? PawmartColors.greenDark : null,
          ),
        ),
      ],
    ),
  );
}
