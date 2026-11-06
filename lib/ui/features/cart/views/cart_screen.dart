import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/cart.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_artwork.dart';
import '../view_models/cart_view_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        CartViewModel(CartRepository(context.read<ApiClient>()))..load(),
    child: const _CartContent(),
  );
}

class _CartContent extends StatelessWidget {
  const _CartContent();

  @override
  Widget build(BuildContext context) => Consumer<CartViewModel>(
    builder: (context, model, _) {
      final cart = model.cart;
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Giỏ hàng',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: model.isLoading && cart == null
            ? const LoadingState()
            : model.errorMessage != null && cart == null
            ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
            : cart == null || cart.items.isEmpty
            ? RefreshIndicator(
                onRefresh: model.load,
                child: ListView(
                  children: [
                    const SizedBox(height: 110),
                    EmptyState(
                      title: 'Giỏ hàng đang trống',
                      message: 'Chọn sản phẩm phù hợp cho bé để bắt đầu nhé.',
                      icon: Icons.shopping_bag_outlined,
                      actionLabel: 'Xem sản phẩm',
                      onAction: () => context.go('/customer/categories'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (model.errorMessage != null)
                    MaterialBanner(
                      content: Text(model.errorMessage!),
                      actions: [
                        TextButton(
                          onPressed: model.load,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: model.load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                        itemCount: cart.items.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => index == 0
                            ? _CartHeading(itemCount: cart.totalQuantity)
                            : _CartItem(
                                line: cart.items[index - 1],
                                viewModel: model,
                              ),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: PawmartColors.line),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Tạm tính',
                                  style: TextStyle(
                                    color: PawmartColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                formatVnd(cart.subtotal),
                                style: const TextStyle(
                                  color: PawmartColors.greenDark,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Phí giao hàng và tổng tiền sẽ hiện ở bước tiếp theo.',
                              style: TextStyle(
                                color: PawmartColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: model.isSaving
                                ? null
                                : () => context.go('/customer/checkout'),
                            icon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Tiếp tục thanh toán'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class _CartHeading extends StatelessWidget {
  const _CartHeading({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Sản phẩm đã chọn',
            style: TextStyle(
              color: PawmartColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: PawmartColors.greenPale,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$itemCount món',
            style: const TextStyle(
              color: PawmartColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CartItem extends StatelessWidget {
  const _CartItem({required this.line, required this.viewModel});
  final CartLine line;
  final CartViewModel viewModel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ProductArtwork(imageUrl: line.imageUrl, height: 76),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.productName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PawmartColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatVnd(line.unitPrice),
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
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 9),
          Row(
            children: [
              _QuantityControl(line: line, viewModel: viewModel),
              const Spacer(),
              IconButton(
                tooltip: 'Bỏ sản phẩm',
                onPressed: viewModel.isSaving
                    ? null
                    : () => viewModel.remove(line.productId),
                icon: const Icon(Icons.delete_outline_rounded, size: 21),
                color: PawmartColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(color: PawmartColors.muted, fontSize: 12),
              ),
              const SizedBox(width: 9),
              Text(
                formatVnd(line.lineTotal),
                style: const TextStyle(
                  color: PawmartColors.greenDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.line, required this.viewModel});
  final CartLine line;
  final CartViewModel viewModel;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: PawmartColors.cream,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: PawmartColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Giảm số lượng',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: viewModel.isSaving
              ? null
              : () => viewModel.setQuantity(line.productId, line.quantity - 1),
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        Text(
          '${line.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'Tăng số lượng',
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: viewModel.isSaving || line.quantity >= line.availableStock
              ? null
              : () => viewModel.setQuantity(line.productId, line.quantity + 1),
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    ),
  );
}
