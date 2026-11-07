import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../view_models/orders_view_model.dart';
import '../../maps/map_widgets.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.justPlaced = false,
  });
  final String orderId;
  final bool justPlaced;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => OrderDetailViewModel(
      OrdersRepository(context.read<ApiClient>()),
      orderId,
    )..load(),
    child: _OrderDetailContent(justPlaced: justPlaced),
  );
}

class _OrderDetailContent extends StatefulWidget {
  const _OrderDetailContent({required this.justPlaced});
  final bool justPlaced;

  @override
  State<_OrderDetailContent> createState() => _OrderDetailContentState();
}

class _OrderDetailContentState extends State<_OrderDetailContent> {
  Timer? _paymentRefresh;

  @override
  void initState() {
    super.initState();
    _paymentRefresh = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted ||
          ModalRoute.of(context)?.isCurrent != true ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      context.read<OrderDetailViewModel>().refreshPaymentStatus();
    });
  }

  @override
  void dispose() {
    _paymentRefresh?.cancel();
    super.dispose();
  }

  Future<void> _review(BuildContext context, OrderDetailViewModel model) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewSheet(model: model),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá đơn hàng!')),
      );
    }
  }

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
            order == null
                ? 'Chi tiết đơn hàng'
                : 'Đơn #${order.orderId.length > 8 ? order.orderId.substring(0, 8).toUpperCase() : order.orderId}',
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
                    if (widget.justPlaced && order.status == 'PENDING') ...[
                      _OrderPlacedCard(order: order),
                      const SizedBox(height: 12),
                    ],
                    _TrackingMapCard(order: order),
                    const SizedBox(height: 12),
                    if (order.paymentMethod == 'COD') ...[
                      _CodPaymentCard(order: order),
                      const SizedBox(height: 12),
                    ] else if (order.paymentMethod == 'BANK_QR') ...[
                      _BankQrPaymentCard(
                        order: order,
                        instructions: model.bankQr,
                        error: model.bankQrError,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (order.status != 'CANCELLED') ...[
                      _OrderReviewCard(
                        order: order,
                        onReview: () => _review(context, model),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                    if (order.latitude != null && order.longitude != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 175,
                          child: IgnorePointer(
                            child: PawMap(
                              center: LatLng(order.latitude!, order.longitude!),
                              marker: LatLng(order.latitude!, order.longitude!),
                              zoom: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Điểm giao bạn đã chọn khi đặt hàng',
                        style: TextStyle(
                          fontSize: 12,
                          color: PawmartColors.muted,
                        ),
                      ),
                    ],
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
                                'Thanh toán: ${order.paymentMethod == 'COD'
                                    ? 'Khi nhận hàng'
                                    : order.paymentMethod == 'BANK_QR'
                                    ? 'Chuyển khoản QR'
                                    : order.paymentMethod}',
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

class _OrderPlacedCard extends StatelessWidget {
  const _OrderPlacedCard({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) => Card(
    color: PawmartColors.greenPale,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: PawmartColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đã tiếp nhận đơn hàng',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  order.paymentMethod == 'BANK_QR'
                      ? 'Bước tiếp theo: quét mã QR bên dưới. Trạng thái thanh toán sẽ tự cập nhật sau khi hệ thống nhận giao dịch.'
                      : 'Bước tiếp theo: chờ cửa hàng xác nhận đơn. Bạn thanh toán khi nhận hàng.',
                  style: const TextStyle(
                    color: PawmartColors.muted,
                    fontSize: 13,
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

class _OrderReviewCard extends StatelessWidget {
  const _OrderReviewCard({required this.order, required this.onReview});
  final OrderDetail order;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final review = order.review;
    final eligible =
        order.status == 'DELIVERED' && order.paymentStatus == 'SUCCESS';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars_rounded, color: PawmartColors.green),
                SizedBox(width: 10),
                Text(
                  'Trải nghiệm của bạn',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (review != null) ...[
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 22,
                      color: const Color(0xFFE7A33B),
                    ),
                  const SizedBox(width: 8),
                  const Text('Đã đánh giá'),
                ],
              ),
              if (review.comment?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(review.comment!),
              ],
              if (review.shopReply?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: PawmartColors.greenPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PAWMART PHẢN HỒI',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: PawmartColors.greenDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(review.shopReply!),
                    ],
                  ),
                ),
              ],
            ] else if (eligible) ...[
              const Text(
                'Đơn đã hoàn tất. Chia sẻ cảm nhận để PawMart chăm sóc bạn tốt hơn.',
                style: TextStyle(color: PawmartColors.muted),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Đánh giá đơn hàng'),
              ),
            ] else
              Text(
                order.status == 'DELIVERED'
                    ? 'Bạn có thể đánh giá sau khi cửa hàng xác nhận đã thu tiền.'
                    : 'Đánh giá sẽ mở khi đơn được giao và thanh toán đã xác nhận.',
                style: const TextStyle(
                  color: PawmartColors.muted,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.model});
  final OrderDetailViewModel model;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _sharePublicly = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || _rating == 0) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.model.submitReview(
      rating: _rating,
      comment: _comment.text,
      sharePublicly: _sharePublicly,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = widget.model.errorMessage ?? 'Không gửi được đánh giá.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      22,
      4,
      22,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đánh giá đơn hàng',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Chọn số sao và chia sẻ trải nghiệm thật của bạn.',
            style: TextStyle(color: PawmartColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  tooltip: '$star sao',
                  onPressed: _saving
                      ? null
                      : () => setState(() => _rating = star),
                  icon: AnimatedScale(
                    scale: _rating == star ? 1.14 : 1,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFE7A33B),
                      size: 34,
                    ),
                  ),
                ),
            ],
          ),
          Center(
            child: Text(switch (_rating) {
              1 => 'Chưa hài lòng',
              2 => 'Cần cải thiện',
              3 => 'Ổn',
              4 => 'Rất tốt',
              5 => 'Tuyệt vời',
              _ => 'Chạm để chọn mức hài lòng',
            }, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _comment,
            enabled: !_saving,
            maxLines: 4,
            maxLength: 600,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Nhận xét (không bắt buộc)',
              hintText: 'Sản phẩm, đóng gói, giao hàng…',
              alignLabelWithHint: true,
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _sharePublicly,
            onChanged: _saving
                ? null
                : (value) => setState(() => _sharePublicly = value ?? false),
            title: const Text(
              'Cho phép hiển thị trên PawMart',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Tên gọi, số sao, nhận xét và phản hồi cửa hàng có thể được chia sẻ.',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: PawmartColors.error)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  _rating == 0 || _saving || _comment.text.trim().length == 1
                  ? null
                  : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_saving ? 'Đang gửi…' : 'Gửi đánh giá'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _CodPaymentCard extends StatelessWidget {
  const _CodPaymentCard({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: PawmartColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentStatus == 'SUCCESS'
                      ? 'Đã thu tiền khi giao hàng'
                      : 'Thanh toán khi nhận hàng',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  order.paymentStatus == 'SUCCESS'
                      ? 'Cửa hàng đã ghi nhận khoản thanh toán.'
                      : 'Chuẩn bị ${formatVnd(order.total)}. Cửa hàng xác nhận sau khi giao và thu tiền.',
                  style: const TextStyle(
                    color: PawmartColors.muted,
                    fontSize: 12,
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

class _BankQrPaymentCard extends StatelessWidget {
  const _BankQrPaymentCard({
    required this.order,
    this.instructions,
    this.error,
  });
  final OrderDetail order;
  final BankQrInstructions? instructions;
  final String? error;

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: PawmartColors.green),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Chuyển khoản cho PawMart Pet Store',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (order.status == 'CANCELLED')
            const Text('Đơn đã hủy. Không chuyển khoản cho đơn này.')
          else if (order.paymentStatus == 'SUCCESS')
            const Row(
              children: [
                Icon(Icons.verified_rounded, color: PawmartColors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Đã thanh toán thành công',
                    style: TextStyle(
                      color: PawmartColors.greenDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            )
          else if (error != null)
            Text(error!, style: const TextStyle(color: PawmartColors.error))
          else if (instructions == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            if (instructions!.receivedAmount > 0) ...[
              Text(
                'Đã nhận ${formatVnd(instructions!.receivedAmount)} / ${formatVnd(instructions!.amount)}',
                style: const TextStyle(
                  color: PawmartColors.greenDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Quét bằng ứng dụng ngân hàng hoặc sao chép thông tin bên dưới.',
              style: TextStyle(color: PawmartColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Center(
              child: Image.network(
                instructions!.qrImageUrl,
                width: 260,
                height: 300,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 260,
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, _, _) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Không tải được ảnh QR. Hãy dùng thông tin chuyển khoản bên dưới.',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _QrLine('Ngân hàng', instructions!.bankName),
            _QrLine('Chủ tài khoản', instructions!.bankAccountName),
            _QrLine('Số tài khoản', instructions!.bankAccountNo),
            _QrLine(
              instructions!.receivedAmount > 0 ? 'Còn cần chuyển' : 'Số tiền',
              formatVnd(instructions!.amount - instructions!.receivedAmount),
            ),
            _QrLine('Nội dung', instructions!.transferContent),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copy(
                    context,
                    instructions!.bankAccountNo,
                    'số tài khoản',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao chép STK'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _copy(context, instructions!.transferContent, 'nội dung'),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao chép nội dung'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Kiểm tra đúng tên người nhận trong ứng dụng ngân hàng. Giữ nguyên nội dung chuyển khoản. Hệ thống sẽ tự cập nhật khi nhận được giao dịch; nếu đã chuyển mà trạng thái chưa đổi, hãy liên hệ cửa hàng.',
              style: TextStyle(color: PawmartColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
  );
}

class _QrLine extends StatelessWidget {
  const _QrLine(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: const TextStyle(color: PawmartColors.muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
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
    final description = switch (order.status) {
      'PENDING'
          when order.paymentMethod == 'BANK_QR' &&
              order.paymentStatus == 'SUCCESS' =>
        'Đã nhận thanh toán. Cửa hàng sẽ xác nhận và chuẩn bị hàng.',
      'PENDING' when order.paymentMethod == 'BANK_QR' =>
        'Chờ xác nhận chuyển khoản trước khi chuẩn bị hàng.',
      'PENDING' => 'Cửa hàng sẽ xác nhận và chuẩn bị đơn của bạn.',
      'CONFIRMED' => 'Cửa hàng đang chuẩn bị hàng để bàn giao vận chuyển.',
      'SHIPPING' => 'Đơn đang trên đường giao đến bạn.',
      'DELIVERED' when order.paymentStatus == 'SUCCESS' =>
        'Đã giao và thanh toán hoàn tất. Bạn có thể đánh giá.',
      'DELIVERED' => 'Đã giao; đang chờ cửa hàng ghi nhận thanh toán.',
      'CANCELLED' => 'Đơn đã ngừng xử lý.',
      _ => 'Theo dõi tiến độ đơn tại đây.',
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
                Text(
                  description,
                  style: const TextStyle(
                    color: PawmartColors.muted,
                    fontSize: 12,
                  ),
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
