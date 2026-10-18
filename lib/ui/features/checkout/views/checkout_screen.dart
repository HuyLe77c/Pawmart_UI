import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_dependencies.dart';
import '../view_models/checkout_view_model.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        CheckoutViewModel(context.read<AppDependencies>().ordersRepository),
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
    appBar: AppBar(title: const Text('Địa chỉ giao hàng')),
    body: Consumer<CheckoutViewModel>(
      builder: (context, model, _) => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'Thông tin người nhận',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _locating ? null : _locate,
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Lấy tọa độ GPS'),
            ),
            if (_locationMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_locationMessage!),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Tọa độ giao hàng (tùy chọn)'),
              leading: const Icon(Icons.location_on_outlined),
              children: [
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
            const SizedBox(height: 20),
            Text(
              'Thanh toán',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Card(
              child: const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Thanh toán khi nhận hàng (COD)'),
                subtitle: Text('Đang khả dụng'),
              ),
            ),
            const ListTile(
              enabled: false,
              leading: Icon(Icons.lock_outline),
              title: Text('VNPAY / MoMo / ZaloPay'),
              subtitle: Text('Chưa cấu hình cổng thanh toán'),
            ),
            const ListTile(
              enabled: false,
              leading: Icon(Icons.map_outlined),
              title: Text('Bản đồ và phí theo khoảng cách'),
              subtitle: Text(
                'Chưa cấu hình nhà cung cấp bản đồ; phí giao hàng mặc định sẽ do API tính',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _promo,
              decoration: const InputDecoration(
                labelText: 'Mã khuyến mãi (không bắt buộc)',
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
              OutlinedButton(
                onPressed: model.isSubmitting ? null : () => _submit(model),
                child: const Text('Thử gửi lại'),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: model.isSubmitting ? null : () => _submit(model),
              icon: model.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                model.isSubmitting ? 'Đang đặt hàng…' : 'Xác nhận đặt hàng',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
