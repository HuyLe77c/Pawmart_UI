import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/repositories/pets_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/product.dart';
import '../../../core/cart_actions.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../view_models/product_detail_view_model.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => ProductDetailViewModel(
      CatalogRepository(context.read<ApiClient>()),
      PetsRepository(context.read<ApiClient>()),
      context.read<AuthViewModel>().isSignedIn,
    )..load(productId),
    child: const _ProductDetailContent(),
  );
}

class _ProductDetailContent extends StatefulWidget {
  const _ProductDetailContent();
  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {
  int _quantity = 1;
  bool _adding = false;

  Future<void> _add(Product product) async {
    if (_adding || product.stockQuantity < 1) return;
    setState(() => _adding = true);
    final added = await addProductToCart(
      context,
      productId: product.productId,
      quantity: _quantity,
    );
    if (mounted) {
      setState(() => _adding = false);
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<ProductDetailViewModel>(
    builder: (context, model, _) {
      final product = model.product;
      return Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            IconButton(
              tooltip: 'Giỏ hàng',
              onPressed: () => context.go('/customer/cart'),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ],
        ),
        body: model.isLoading && product == null
            ? const LoadingState()
            : model.errorMessage != null && product == null
            ? ErrorPanel(
                message: model.errorMessage!,
                onRetry: () => model.load(
                  int.tryParse(
                        GoRouterState.of(context).pathParameters['id'] ?? '',
                      ) ??
                      0,
                ),
              )
            : product == null
            ? const SizedBox.shrink()
            : _ProductBody(
                product: product,
                model: model,
                quantity: _quantity,
                onDecrement: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                onIncrement: _quantity < product.stockQuantity
                    ? () => setState(() => _quantity++)
                    : null,
                signedIn: context.read<AuthViewModel>().isSignedIn,
              ),
        bottomNavigationBar: product == null
            ? null
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: PawmartColors.line)),
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Tư vấn AI',
                        onPressed: () => context.go('/customer/assistant'),
                        icon: const Icon(Icons.chat_bubble_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Giỏ hàng',
                        onPressed: () => context.go('/customer/cart'),
                        icon: const Icon(Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: product.stockQuantity > 0 && !_adding
                              ? () => _add(product)
                              : null,
                          child: _adding
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  product.stockQuantity > 0
                                      ? 'Thêm vào giỏ · ${formatVnd(product.price * _quantity)}'
                                      : 'Tạm hết hàng',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.product,
    required this.model,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.signedIn,
  });

  final Product product;
  final ProductDetailViewModel model;
  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = product.description?.trim().isNotEmpty == true;
    final hasIngredients = product.ingredients?.trim().isNotEmpty == true;
    final hasNutrition = product.nutritionInfo?.trim().isNotEmpty == true;
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: _ProductGallery(product: product),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (product.brand?.trim().isNotEmpty == true)
                    Flexible(
                      child: _InfoChip(
                        icon: Icons.verified_outlined,
                        label: product.brand!,
                      ),
                    ),
                  const Spacer(),
                  if (product.sku?.trim().isNotEmpty == true)
                    Text(
                      'Mã: ${product.sku}',
                      style: const TextStyle(
                        color: PawmartColors.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.productName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: PawmartColors.ink,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PawmartColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá bán',
                            style: TextStyle(
                              color: PawmartColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formatVnd(product.price),
                            style: const TextStyle(
                              color: PawmartColors.green,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: product.stockQuantity > 0
                            ? PawmartColors.greenPale
                            : const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.stockQuantity > 0
                            ? 'Còn ${product.stockQuantity}'
                            : 'Hết hàng',
                        style: TextStyle(
                          color: product.stockQuantity > 0
                              ? PawmartColors.greenDark
                              : PawmartColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (model.pets.isNotEmpty) ...[
                const SizedBox(height: 14),
                _PetFitCard(
                  product: product,
                  petName: model.pets.first.petName,
                  petType: model.pets.first.petType,
                ),
              ] else if (signedIn) ...[
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.pets_rounded,
                      color: PawmartColors.green,
                    ),
                    title: const Text('Thêm hồ sơ thú cưng'),
                    subtitle: const Text(
                      'Xem sản phẩm dành cho loại thú cưng nào.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/customer/profile'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Số lượng',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Giảm số lượng',
                    onPressed: onDecrement,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Tăng số lượng',
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Thông tin sản phẩm',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasDescription)
                        _DetailBlock(
                          icon: Icons.description_outlined,
                          title: 'Mô tả',
                          value: product.description!.trim(),
                        ),
                      if (hasIngredients) ...[
                        if (hasDescription) const Divider(height: 28),
                        _DetailBlock(
                          icon: Icons.grass_outlined,
                          title: 'Thành phần',
                          value: product.ingredients!.trim(),
                        ),
                      ],
                      if (hasNutrition) ...[
                        if (hasDescription || hasIngredients)
                          const Divider(height: 28),
                        _DetailBlock(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Thông tin dinh dưỡng',
                          value: product.nutritionInfo!.trim(),
                        ),
                      ],
                      if (!hasDescription && !hasIngredients && !hasNutrition)
                        const Text(
                          'Cửa hàng chưa cập nhật thông tin chi tiết.',
                          style: TextStyle(color: PawmartColors.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.product});
  final Product product;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = [...widget.product.images]
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.displayOrder.compareTo(b.displayOrder);
      });
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PawmartColors.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: images.isEmpty
                  ? const ProductArtwork(height: 300)
                  : PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => _index = index),
                      itemBuilder: (context, index) => ProductArtwork(
                        imageUrl: images[index].imageUrl,
                        height: 300,
                      ),
                    ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: i == _index ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _index
                              ? PawmartColors.green
                              : PawmartColors.line,
                          borderRadius: BorderRadius.circular(8),
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: PawmartColors.green, size: 14),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PawmartColors.greenDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: PawmartColors.greenPale,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: PawmartColors.green, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(color: PawmartColors.ink, height: 1.45),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PetFitCard extends StatelessWidget {
  const _PetFitCard({
    required this.product,
    required this.petName,
    required this.petType,
  });
  final Product product;
  final String petName;
  final String petType;

  @override
  Widget build(BuildContext context) {
    final target = product.targetPetType.toUpperCase();
    final fits = target == 'ALL' || target == petType.toUpperCase();
    return Card(
      color: fits ? PawmartColors.greenPale : const Color(0xFFFFF1E0),
      child: ListTile(
        leading: Icon(
          fits ? Icons.check_circle : Icons.info_outline,
          color: fits ? PawmartColors.green : Colors.orange,
        ),
        title: Text(
          fits
              ? 'Có thể phù hợp với $petName'
              : 'Sản phẩm hướng tới thú cưng khác',
        ),
        subtitle: const Text('Gợi ý theo loại thú cưng trong hồ sơ.'),
      ),
    );
  }
}
