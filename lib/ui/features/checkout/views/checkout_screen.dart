import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/shopping_action_bar.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/checkout_view_model.dart';
import '../../maps/delivery_address_map_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        CheckoutViewModel(OrdersRepository(context.read<ApiClient>()))
          ..loadQuote()
          ..loadPaymentMethods(),
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
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().user;
    _name.text = user?.fullName ?? '';
    _phone.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _note.dispose();
    _promo.dispose();
    super.dispose();
  }

  Future<void> _chooseOnMap() async {
    final place = await context.push<DeliveryPlace>(
      '/delivery-map',
      extra: DeliveryMapInput(
        address: _address.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
    if (place == null || !mounted) return;
    _address.text = place.address;
    setState(() {
      _latitude = place.latitude;
      _longitude = place.longitude;
    });
  }

  Future<void> _submit(CheckoutViewModel model) async {
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      final field = invalid.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (field.mounted) {
          Scrollable.ensureVisible(field.context, alignment: .15);
        }
      });
      return;
    }
    final order = await model.submit(
      recipientName: _name.text.trim(),
      recipientPhone: _phone.text.replaceAll(RegExp(r'[\s.-]'), ''),
      address: _address.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      promotionCode: _promo.text.trim(),
      note: _note.text.trim(),
    );
    if (order != null && mounted) {
      context.go(
        '/customer/orders/${Uri.encodeComponent(order.orderId)}?placed=1',
      );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<CheckoutViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(title: const Text('Xác nhận đơn hàng')),
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : ShoppingActionBar(
              label: 'Tổng thanh toán',
              value: model.quote == null ? '—' : formatVnd(model.quote!.total),
              action: FilledButton.icon(
                onPressed:
                    model.isSubmitting ||
                        model.isLoadingQuote ||
                        model.quote == null
                    ? null
                    : () => _submit(model),
                icon: model.isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  model.isSubmitting
                      ? 'Đang đặt hàng…'
                      : model.selectedPaymentMethod == 'BANK_QR'
                      ? 'Tạo đơn và lấy mã QR'
                      : 'Đặt hàng',
                ),
              ),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: PawmartColors.greenDark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          color: Color(0xFFF2D7A4),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Sắp đến tay bé!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Kiểm tra địa chỉ giao hàng và phương thức thanh toán trước khi đặt.',
                          style: TextStyle(
                            color: Color(0xFFC9E9D8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const _CheckoutSectionTitle('01', 'Giao hàng'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Họ tên người nhận',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Nhập họ tên hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '0xxxxxxxxx hoặc +84xxxxxxxxx',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final phone =
                          value?.replaceAll(RegExp(r'[\s.-]'), '') ?? '';
                      return RegExp(r'^(0[0-9]{9}|\+84[0-9]{9})$')
                              .hasMatch(phone)
                          ? null
                          : 'Nhập số điện thoại Việt Nam hợp lệ';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    onChanged: (_) {
                      if (_latitude != null) {
                        setState(() {
                          _latitude = null;
                          _longitude = null;
                        });
                      }
                    },
                    minLines: 2,
                    maxLines: 3,
                    autofillHints: const [AutofillHints.streetAddressLine1],
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ chi tiết',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 5
                        ? 'Địa chỉ cần ít nhất 5 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: PawmartColors.greenPale,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _chooseOnMap,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: PawmartColors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chọn trên bản đồ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _latitude == null
                                        ? 'Tìm địa chỉ, lấy GPS hoặc chạm chọn điểm giao'
                                        : 'Đã lưu ghim giao hàng · Chạm để chỉnh lại',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: PawmartColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: PawmartColors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _CheckoutSectionTitle('02', 'Thanh toán'),
                  const SizedBox(height: 12),
                  _PaymentChoice(
                    icon: Icons.payments_outlined,
                    title: 'Thanh toán khi nhận hàng',
                    subtitle: 'Trả tiền mặt sau khi nhận và kiểm tra hàng',
                    selected: model.selectedPaymentMethod == 'COD',
                    enabled: !model.isSubmitting,
                    onTap: () => model.selectPaymentMethod('COD'),
                  ),
                  const SizedBox(height: 10),
                  _PaymentChoice(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Chuyển khoản bằng mã QR',
                    subtitle: model.paymentMethods?.bankQrAvailable == true
                        ? 'Tạo QR theo đúng số tiền và mã của đơn hàng'
                        : model.isLoadingPaymentMethods
                        ? 'Đang kiểm tra phương thức thanh toán…'
                        : 'Tạm thời chưa khả dụng',
                    selected: model.selectedPaymentMethod == 'BANK_QR',
                    enabled:
                        model.paymentMethods?.bankQrAvailable == true &&
                        !model.isSubmitting,
                    onTap: () => model.selectPaymentMethod('BANK_QR'),
                  ),
                  if (model.selectedPaymentMethod == 'BANK_QR') ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Sau khi đặt hàng, mã QR sẽ xuất hiện trong chi tiết đơn. Trạng thái sẽ tự cập nhật khi hệ thống nhận và đối soát giao dịch ngân hàng.',
                      style: TextStyle(
                        color: PawmartColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
                          : () => model.loadQuote(
                              promotionCode: _promo.text.trim(),
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                _PriceRow(
                                  'Phí giao hàng',
                                  model.quote!.shippingFee,
                                ),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: selected ? PawmartColors.greenPale : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: selected ? PawmartColors.green : PawmartColors.line,
        width: selected ? 1.5 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? PawmartColors.greenDark : PawmartColors.muted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: PawmartColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? PawmartColors.green : PawmartColors.muted,
            ),
          ],
        ),
      ),
    ),
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
