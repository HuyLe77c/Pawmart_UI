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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _CartItem(line: cart.items[index], viewModel: model),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Tạm tính')),
                              Text(
                                formatVnd(cart.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: model.isSaving
                                ? null
                                : () => context.go('/customer/checkout'),
                            child: Text(
                              'Tiếp tục đặt hàng · ${formatVnd(cart.subtotal)}',
                            ),
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

class _CartItem extends StatelessWidget {
  const _CartItem({required this.line, required this.viewModel});
  final CartLine line;
  final CartViewModel viewModel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: ProductArtwork(imageUrl: line.imageUrl, height: 74),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  formatVnd(line.unitPrice),
                  style: const TextStyle(
                    color: PawmartColors.greenDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Giảm số lượng',
                      visualDensity: VisualDensity.compact,
                      onPressed: viewModel.isSaving
                          ? null
                          : () => viewModel.setQuantity(
                              line.productId,
                              line.quantity - 1,
                            ),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${line.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Tăng số lượng',
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          viewModel.isSaving ||
                              line.quantity >= line.availableStock
                          ? null
                          : () => viewModel.setQuantity(
                              line.productId,
                              line.quantity + 1,
                            ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Bỏ sản phẩm',
                      onPressed: viewModel.isSaving
                          ? null
                          : () => viewModel.remove(line.productId),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: PawmartColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
