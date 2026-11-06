import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/product_review_panel.dart';
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
    if (_adding || !product.canPurchase) return;
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
          title: const Text('Sản phẩm'),
          leading: IconButton.filledTonal(
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/catalog'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actions: [
            if (context.read<AuthViewModel>().isSignedIn)
              IconButton(
                tooltip: 'Tư vấn về sản phẩm',
                onPressed: () => context.go('/customer/assistant'),
                icon: const Icon(Icons.forum_outlined),
              ),
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
                onIncrement:
                    product.canPurchase && _quantity < product.stockQuantity
                    ? () => setState(() => _quantity++)
                    : null,
                signedIn: context.read<AuthViewModel>().isSignedIn,
              ),
        bottomNavigationBar: product == null
            ? null
            : product.isPreview
            ? const _PreviewBottomBar()
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: PawmartColors.line)),
                ),
                child: SafeArea(
                  minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tạm tính',
                              style: TextStyle(
                                color: PawmartColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              formatVnd(product.price * _quantity),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PawmartColors.greenDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: product.canPurchase && !_adding
                              ? () => _add(product)
                              : null,
                          icon: _adding
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_shopping_cart_rounded),
                          label: Text(
                            product.stockQuantity > 0
                                ? 'Thêm vào giỏ'
                                : 'Tạm hết hàng',
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

class _PreviewBottomBar extends StatelessWidget {
  const _PreviewBottomBar();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: PawmartColors.line)),
    ),
    child: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: PawmartColors.greenPale,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          'Sản phẩm chưa mở bán',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: PawmartColors.greenDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
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
    final hasPackageSize = product.packageSize?.trim().isNotEmpty == true;
    final hasLifeStage = product.lifeStage?.trim().isNotEmpty == true;
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
              if (product.brand?.trim().isNotEmpty == true) ...[
                _InfoChip(icon: Icons.sell_outlined, label: product.brand!),
                const SizedBox(height: 12),
              ],
              Text(
                product.productName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: PawmartColors.ink,
                ),
              ),
              if (product.sku?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 7),
                Text(
                  'Mã sản phẩm: ${product.sku}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PawmartColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
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
                            product.hasPublishedPrice
                                ? formatVnd(product.price)
                                : 'Giá chưa công bố',
                            style: TextStyle(
                              color: PawmartColors.green,
                              fontSize: product.hasPublishedPrice ? 25 : 18,
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
                        color: product.isPreview || product.stockQuantity > 0
                            ? PawmartColors.greenPale
                            : const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.isPreview
                            ? 'Chưa mở bán'
                            : product.stockQuantity > 0
                            ? 'Còn ${product.stockQuantity}'
                            : 'Hết hàng',
                        style: TextStyle(
                          color: product.isPreview || product.stockQuantity > 0
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
              if (product.isPreview) ...[
                const SizedBox(height: 14),
                Card(
                  color: PawmartColors.greenPale,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin sản phẩm',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.description?.trim().isNotEmpty == true
                              ? product.description!.trim()
                              : 'Mô tả sản phẩm đang được cập nhật.',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Giá bán và tồn kho sẽ hiển thị khi PawMart xác nhận.',
                        ),
                        if (product.catalogReview?.officialUrl.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Nguồn model: ${Uri.tryParse(product.catalogReview!.officialUrl)?.host ?? 'website hãng'}',
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: product.catalogReview!.officialUrl,
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Đã sao chép liên kết nguồn.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Sao chép liên kết nguồn'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ] else if (model.pets.isNotEmpty) ...[
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
              if (hasPackageSize || hasLifeStage) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasPackageSize)
                      _InfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Quy cách: ${product.packageSize!.trim()}',
                      ),
                    if (hasLifeStage)
                      _InfoChip(
                        icon: Icons.pets_outlined,
                        label: 'Độ tuổi: ${product.lifeStage!.trim()}',
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (!product.isPreview)
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
              const SizedBox(height: 30),
              _ProductInformation(product: product),
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
              height: widget.product.isPreview ? 220 : 300,
              child: images.isEmpty
                  ? widget.product.hasVerifiedImage
                        ? const ProductArtwork(height: 300)
                        : ProductReviewPanel(
                            product: widget.product,
                            height: 220,
                          )
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PawmartColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final description = product.description?.trim() ?? '';
    final facts = <_ProductFact>[
      if (product.brand?.trim().isNotEmpty == true)
        _ProductFact('Thương hiệu', product.brand!.trim()),
      if (product.targetPetType.trim().isNotEmpty)
        _ProductFact('Phù hợp', switch (product.targetPetType.toUpperCase()) {
          'DOG' => 'Chó',
          'CAT' => 'Mèo',
          'ALL' => 'Chó và mèo',
          _ => product.targetPetType,
        }),
      if (product.packageSize?.trim().isNotEmpty == true)
        _ProductFact('Quy cách', product.packageSize!.trim()),
      if (product.lifeStage?.trim().isNotEmpty == true)
        _ProductFact('Độ tuổi', product.lifeStage!.trim()),
      if (product.sku?.trim().isNotEmpty == true)
        _ProductFact('Mã sản phẩm', product.sku!.trim()),
    ];
    final sections = <({IconData icon, String title, String value})>[
      if (product.ingredients?.trim().isNotEmpty == true)
        (
          icon: Icons.grass_outlined,
          title: 'Thành phần',
          value: product.ingredients!.trim(),
        ),
      if (product.nutritionInfo?.trim().isNotEmpty == true)
        (
          icon: Icons.monitor_heart_outlined,
          title: 'Thông tin dinh dưỡng',
          value: product.nutritionInfo!.trim(),
        ),
      if (product.feedingGuide?.trim().isNotEmpty == true)
        (
          icon: Icons.menu_book_outlined,
          title: 'Hướng dẫn sử dụng',
          value: product.feedingGuide!.trim(),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TÌM HIỂU SẢN PHẨM',
          style: TextStyle(
            color: PawmartColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Thông tin sản phẩm',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: PawmartColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 23),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: PawmartColors.greenPale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            color: PawmartColors.green,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Text(
                          'Mô tả sản phẩm',
                          style: TextStyle(
                            color: PawmartColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Text(
                      description.isNotEmpty
                          ? description
                          : product.isPreview
                          ? 'Mô tả chi tiết đang được đối chiếu với nhà sản xuất.'
                          : 'Cửa hàng chưa cập nhật mô tả sản phẩm.',
                      style: const TextStyle(
                        color: PawmartColors.ink,
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (facts.isNotEmpty) ...[
                const Divider(height: 1),
                Container(
                  width: double.infinity,
                  color: PawmartColors.greenPale,
                  padding: const EdgeInsets.fromLTRB(20, 19, 20, 21),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THÔNG SỐ CƠ BẢN',
                        style: TextStyle(
                          color: PawmartColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth < 280 ? 1 : 2;
                          final width =
                              (constraints.maxWidth - (columns == 2 ? 12 : 0)) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 16,
                            children: [
                              for (final fact in facts)
                                SizedBox(
                                  width: width,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fact.label,
                                        style: const TextStyle(
                                          color: PawmartColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fact.value,
                                        style: const TextStyle(
                                          color: PawmartColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        for (final section in sections) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PawmartColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(section.icon, color: PawmartColors.green, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          color: PawmartColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  section.value,
                  style: const TextStyle(
                    color: PawmartColors.ink,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductFact {
  const _ProductFact(this.label, this.value);

  final String label;
  final String value;
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
