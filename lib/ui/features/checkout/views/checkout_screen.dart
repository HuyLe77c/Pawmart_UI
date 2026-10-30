import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_dependencies.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../view_models/checkout_view_model.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        CheckoutViewModel(context.read<AppDependencies>().ordersRepository)
          ..loadQuote(),
    child: const _CheckoutBody(),
  );
}

class _CheckoutBody extends StatefulWidget {
  const _CheckoutBody();

  @override
  State<_CheckoutBody> createState() => _CheckoutBodyState();
}

class _CheckoutBodyState extends State<_CheckoutBody> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _promo = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  bool _locating = false;
  String? _locationMessage;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _promo.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled())
        throw Exception(
          'Dịch vụ vị trí đang tắt. Bạn vẫn có thể nhập địa chỉ thủ công.',
        );
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        throw Exception(
          'Chưa có quyền vị trí. Bạn vẫn có thể nhập địa chỉ thủ công.',
        );
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _lat.text = position.latitude.toStringAsFixed(6);
      _lon.text = position.longitude.toStringAsFixed(6);
      if (mounted)
        setState(
          () => _locationMessage =
              'Đã lấy tọa độ GPS. Vui lòng nhập địa chỉ giao hàng cụ thể.',
        );
    } catch (error) {
      if (mounted)
        setState(
          () => _locationMessage = error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
        );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit(CheckoutViewModel model) async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    if ((lat == null) != (lon == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hãy nhập đủ cả vĩ độ và kinh độ, hoặc để trống cả hai.',
          ),
        ),
      );
      return;
    }
    final order = await model.submit(
      recipientName: _name.text.trim(),
      recipientPhone: _phone.text.trim(),
      address: _address.text.trim(),
      latitude: lat,
      longitude: lon,
      promotionCode: _promo.text.trim(),
      note: _note.text.trim(),
    );
    if (order != null && mounted)
      context.go('/customer/orders/${Uri.encodeComponent(order.orderId)}');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
    body: Consumer<CheckoutViewModel>(
      builder: (context, model, _) => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const Text(
              'Kiểm tra thông tin để hoàn tất đơn hàng.',
              style: TextStyle(color: PawmartColors.muted),
            ),
            const SizedBox(height: 22),
            const _CheckoutSectionTitle('01', 'Giao hàng'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Họ tên người nhận'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 2 ? 'Nhập họ tên hợp lệ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              textInputAction: TextInputAction.next,
              validator: (v) => (v?.trim().length ?? 0) < 7
                  ? 'Nhập số điện thoại hợp lệ'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ chi tiết',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v?.trim().length ?? 0) < 5
                  ? 'Địa chỉ cần ít nhất 5 ký tự'
                  : null,
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Thêm vị trí giao hàng'),
              subtitle: const Text('Tùy chọn nếu địa chỉ khó tìm'),
              leading: const Icon(Icons.location_on_outlined),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _locating ? null : _locate,
                    icon: _locating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Dùng vị trí hiện tại'),
                  ),
                ),
                if (_locationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_locationMessage!),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Vĩ độ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lon,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Kinh độ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _CheckoutSectionTitle('02', 'Thanh toán'),
            const SizedBox(height: 12),
            Card(
              child: const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Thanh toán khi nhận hàng (COD)'),
                subtitle: Text('Đang khả dụng'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _promo,
              enabled: !model.isSubmitting,
              onChanged: (_) => model.invalidateQuote(),
              decoration: const InputDecoration(
                labelText: 'Mã khuyến mãi (không bắt buộc)',
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: model.isLoadingQuote || model.isSubmitting
                    ? null
                    : () => model.loadQuote(promotionCode: _promo.text.trim()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Cập nhật tổng tiền'),
              ),
            ),
            const SizedBox(height: 12),
            const _CheckoutSectionTitle('03', 'Đơn hàng của bạn'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: model.isLoadingQuote
                    ? const Center(child: CircularProgressIndicator())
                    : model.quote == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.quoteError ??
                                'Cập nhật tổng tiền để tiếp tục.',
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: () => model.loadQuote(
                              promotionCode: _promo.text.trim(),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in model.quote!.items) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.productName),
                                      Text(
                                        '${item.quantity} × ${formatVnd(item.unitPrice)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(formatVnd(item.lineTotal)),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          const Divider(),
                          _PriceRow('Tạm tính', model.quote!.subtotal),
                          if (model.quote!.discount > 0)
                            _PriceRow('Giảm giá', -model.quote!.discount),
                          _PriceRow('Phí giao hàng', model.quote!.shippingFee),
                          const Divider(),
                          _PriceRow(
                            'Tổng thanh toán',
                            model.quote!.total,
                            prominent: true,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: 'Ghi chú cho cửa hàng (không bắt buộc)',
              ),
            ),
            if (model.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                model.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  model.isSubmitting ||
                      model.isLoadingQuote ||
                      model.quote == null
                  ? null
                  : () => _submit(model),
              icon: model.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                model.isSubmitting
                    ? 'Đang đặt hàng…'
                    : 'Đặt hàng · ${model.quote == null ? '—' : formatVnd(model.quote!.total)}',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CheckoutSectionTitle extends StatelessWidget {
  const _CheckoutSectionTitle(this.number, this.title);

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: PawmartColors.greenPale,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: PawmartColors.greenDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, {this.prominent = false});

  final String label;
  final double amount;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: prominent ? FontWeight.w800 : null),
          ),
        ),
        Text(
          formatVnd(amount),
          style: TextStyle(fontWeight: prominent ? FontWeight.w800 : null),
        ),
      ],
    ),
  );
}
