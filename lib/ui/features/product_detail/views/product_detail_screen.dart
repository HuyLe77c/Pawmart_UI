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
          title: const Text('Chi tiết sản phẩm'),
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
                              product.hasPublishedPrice
                                  ? formatVnd(product.price * _quantity)
                                  : 'Chưa công bố',
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
    final information = GlobalKey();
    final theme = Theme.of(context);
    final stockLabel = product.isPreview
        ? 'Sắp mở bán'
        : product.canPurchase
        ? 'Còn ${product.stockQuantity} sản phẩm'
        : product.stockQuantity <= 0
        ? 'Hết hàng'
        : 'Tạm ngừng bán';
    final target = switch (product.targetPetType.toUpperCase()) {
      'DOG' => 'Dành cho chó',
      'CAT' => 'Dành cho mèo',
      'ALL' => 'Dành cho chó và mèo',
      _ => 'Dành cho thú cưng',
    };
    final gallery = _ProductGallery(
      key: ValueKey(product.productId),
      product: product,
    );
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(icon: Icons.pets_outlined, label: target),
            if (product.brand?.trim().isNotEmpty == true)
              _InfoChip(
                icon: Icons.sell_outlined,
                label: product.brand!.trim(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          product.productName,
          style: theme.textTheme.headlineMedium?.copyWith(
            height: 1.12,
            letterSpacing: -.65,
            fontWeight: FontWeight.w800,
            color: PawmartColors.greenDark,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PawmartColors.greenDark,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giá bán',
                style: TextStyle(color: Color(0xFFC9E9D8), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                product.hasPublishedPrice
                    ? formatVnd(product.price)
                    : 'Giá chưa công bố',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: product.hasPublishedPrice ? 29 : 19,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    product.canPurchase
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: const Color(0xFFF2D7A4),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      stockLabel,
                      style: const TextStyle(
                        color: Color(0xFFF2D7A4),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (product.packageSize?.trim().isNotEmpty == true ||
            product.lifeStage?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (product.packageSize?.trim().isNotEmpty == true)
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: product.packageSize!.trim(),
                ),
              if (product.lifeStage?.trim().isNotEmpty == true)
                _InfoChip(
                  icon: Icons.timelapse_rounded,
                  label: product.lifeStage!.trim(),
                ),
            ],
          ),
        ],
        if (product.canPurchase) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số lượng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.outlined(
                tooltip: 'Giảm số lượng',
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  '$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Tăng số lượng',
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              if (information.currentContext case final target?) {
                Scrollable.ensureVisible(
                  target,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                );
              }
            },
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
            label: const Text('Xem thông tin chi tiết'),
          ),
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1060),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 690) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: gallery),
                        const SizedBox(width: 28),
                        Expanded(flex: 5, child: summary),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [gallery, const SizedBox(height: 22), summary],
                  );
                },
              ),
              if (product.isPreview) ...[
                const SizedBox(height: 14),
                _PreviewNotice(product: product),
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
              const SizedBox(height: 26),
              _ProductInformation(key: information, product: product),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final source = product.catalogReview?.officialUrl;
    return Card(
      color: PawmartColors.amberPale,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sản phẩm đang được cập nhật',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text('Giá bán và tồn kho sẽ hiển thị khi PawMart xác nhận.'),
            if (source != null && source.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: source));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép liên kết nguồn.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Sao chép liên kết nguồn'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({super.key, required this.product});
  final Product product;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.hasVerifiedImage
        ? [...product.images]
        : <ProductImage>[];
    images.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.displayOrder.compareTo(b.displayOrder);
    });
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * .77).clamp(210.0, 390.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: ColoredBox(
                color: const Color(0xFFF1F4EB),
                child: SizedBox(
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (images.isEmpty)
                        if (product.hasVerifiedImage)
                          ProductArtwork(height: height)
                        else
                          ProductReviewPanel(product: product, height: height)
                      else ...[
                        PageView.builder(
                          controller: _pages,
                          itemCount: images.length,
                          onPageChanged: (index) =>
                              setState(() => _index = index),
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(22),
                            child: ProductArtwork(
                              imageUrl: images[index].imageUrl,
                              height: height,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: IconButton.filledTonal(
                            tooltip: 'Xem ảnh lớn',
                            onPressed: () {
                              final client = context.read<ApiClient>();
                              final url = client.resolveMediaUri(
                                images[_index].imageUrl,
                              );
                              showDialog<void>(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.white,
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            url.toString(),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, _, _) =>
                                                const SizedBox(
                                                  height: 160,
                                                  child: Center(
                                                    child: Text(
                                                      'Không tải được ảnh.',
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Đóng ảnh',
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.open_in_full_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                        if (images.length > 1)
                          Positioned(
                            left: 16,
                            bottom: 14,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  '${_index + 1} / ${images.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => Semantics(
                      selected: index == _index,
                      button: true,
                      label: 'Ảnh sản phẩm ${index + 1}',
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _pages.jumpToPage(index),
                          child: Container(
                            width: 58,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: index == _index
                                    ? PawmartColors.green
                                    : PawmartColors.line,
                                width: index == _index ? 2 : 1,
                              ),
                            ),
                            child: ProductArtwork(
                              imageUrl: images[index].imageUrl,
                              height: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
  const _ProductInformation({super.key, required this.product});

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
        Text(
          'Thông tin sản phẩm',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Những điều cần biết trước khi chọn cho bé.',
          style: Theme.of(context).textTheme.bodySmall,
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
                        const Expanded(
                          child: Text(
                            'Mô tả sản phẩm',
                            style: TextStyle(
                              color: PawmartColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
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
                        'Thông số cơ bản',
                        style: TextStyle(
                          color: PawmartColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: section.icon == Icons.menu_book_outlined
                            ? PawmartColors.amberPale
                            : PawmartColors.greenPale,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        section.icon,
                        color: PawmartColors.greenDark,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
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
