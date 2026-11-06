import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/order.dart';
import '../../../core/app_theme.dart';
import '../../../core/category_label.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/product_card.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => HomeViewModel(
      CatalogRepository(context.read<ApiClient>()),
      OrdersRepository(context.read<ApiClient>()),
    )..load(),
    child: const _HomeContent(),
  );
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int? _addingId;

  Future<void> _addToCart(Product product) async {
    if (_addingId != null || !product.canPurchase) return;
    setState(() => _addingId = product.productId);
    try {
      final repository = CartRepository(context.read<ApiClient>());
      final cart = await repository.getCart();
      final current = cart.items
          .where((line) => line.productId == product.productId)
          .firstOrNull;
      await repository.setQuantity(
        productId: product.productId,
        quantity: (current?.quantity ?? 0) + 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng.')));
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thêm được sản phẩm. Hãy thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<HomeViewModel>(
    builder: (context, model, _) {
      final heroProduct =
          model.featured
              .where(
                (product) => product.canPurchase && product.hasVerifiedImage,
              )
              .firstOrNull ??
          model.products
              .where(
                (product) => product.canPurchase && product.hasVerifiedImage,
              )
              .firstOrNull;
      final extraProducts = model.products
          .where(
            (product) =>
                !model.featured.any(
                  (featured) => featured.productId == product.productId,
                ) &&
                product.productId != heroProduct?.productId,
          )
          .toList(growable: false);
      return Scaffold(
        body: SafeArea(
          child: model.isLoading && model.products.isEmpty
              ? const LoadingState()
              : model.errorMessage != null && model.products.isEmpty
              ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
              : RefreshIndicator(
                  onRefresh: model.load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _HomeHeader()),
                      SliverToBoxAdapter(child: _SearchShortcut()),
                      const SliverToBoxAdapter(child: _PetShortcuts()),
                      if (model.products.any((product) => product.isPreview))
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                            child: _CatalogReviewNotice(),
                          ),
                        ),
                      if (heroProduct != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: _SpotlightCard(product: heroProduct),
                          ),
                        ),
                      if (model.promotions.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: _PromotionStrip(
                              title: model.promotions.first.promotionName,
                              code: model.promotions.first.code,
                            ),
                          ),
                        ),
                      if (model.categories.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionTitle(
                            title: 'Mua theo danh mục',
                            action: 'Xem tất cả',
                            onTap: () => context.go('/customer/categories'),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: model.categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final category = model.categories[index];
                                return _CategoryCard(
                                  category: category,
                                  sample: model.products
                                      .where(
                                        (product) =>
                                            product.categoryId ==
                                                category.categoryId &&
                                            product.hasVerifiedImage,
                                      )
                                      .firstOrNull,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      if (model.featured.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionTitle(
                            title: 'Sản phẩm nổi bật',
                            action: 'Xem thêm',
                            onTap: () => context.go('/customer/categories'),
                          ),
                        ),
                        _ProductGrid(
                          products: model.featured.take(4).toList(),
                          addingId: _addingId,
                          onAdd: _addToCart,
                        ),
                      ],
                      if (extraProducts.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionTitle(
                            title: 'Khám phá thêm',
                            action: 'Tất cả sản phẩm',
                            onTap: () => context.go('/customer/categories'),
                          ),
                        ),
                        _ProductGrid(
                          products: extraProducts.take(6).toList(),
                          addingId: _addingId,
                          onAdd: _addToCart,
                        ),
                      ],
                      SliverToBoxAdapter(child: _ChatAiShortcut()),
                      if (model.products.isEmpty)
                        const SliverToBoxAdapter(
                          child: EmptyState(
                            title: 'Chưa có sản phẩm',
                            message: 'Hãy quay lại sau khi cửa hàng cập nhật sản phẩm.',
                          ),
                        ),
                      if (model.publicReviews?.items.isNotEmpty == true)
                        SliverToBoxAdapter(
                          child: _CustomerVoices(reviews: model.publicReviews!),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                    ],
                  ),
                ),
        ),
      );
    },
  );
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 12, 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: BrandLockup(compact: true)),
            IconButton(
              tooltip: 'Địa chỉ cửa hàng',
              onPressed: () => context.push('/stores'),
              icon: const Icon(Icons.storefront_outlined),
            ),
            IconButton(
              tooltip: 'Thông báo',
              onPressed: () => context.go('/customer/notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              tooltip: 'Giỏ hàng',
              onPressed: () => context.go('/customer/cart'),
              icon: const Icon(Icons.shopping_bag_outlined),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          'Chọn điều tốt cho bé.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 5),
        const Text(
          'Thức ăn, đồ chơi và chăm sóc mỗi ngày.',
          style: TextStyle(color: PawmartColors.muted, fontSize: 14),
        ),
      ],
    ),
  );
}

class _SearchShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/customer/categories'),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: PawmartColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: PawmartColors.muted),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tìm thức ăn, phụ kiện...',
                  style: TextStyle(color: PawmartColors.muted),
                ),
              ),
              Icon(Icons.tune_rounded, color: PawmartColors.green, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PetShortcuts extends StatelessWidget {
  const _PetShortcuts();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
    child: Row(
      children: [
        Expanded(
          child: _PetShortcut(
            label: 'Mua cho cún',
            icon: Icons.pets_rounded,
            tint: const Color(0xFFFFEBDC),
            onTap: () => context.go('/customer/categories?petType=DOG'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PetShortcut(
            label: 'Mua cho mèo',
            icon: Icons.pets_rounded,
            tint: const Color(0xFFE6E8FC),
            onTap: () => context.go('/customer/categories?petType=CAT'),
          ),
        ),
      ],
    ),
  );
}

class _PetShortcut extends StatelessWidget {
  const _PetShortcut({
    required this.label,
    required this.icon,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: tint,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 49,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: PawmartColors.greenDark),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PawmartColors.greenDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: PawmartColors.greenDark,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ChatAiShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.go('/customer/chat-ai'),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: PawmartColors.greenPale,
                child: Icon(
                  Icons.forum_outlined,
                  color: PawmartColors.greenDark,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hỏi PawMart AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: PawmartColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sản phẩm, đơn hàng và chăm sóc thú cưng',
                      style: TextStyle(
                        fontSize: 12,
                        color: PawmartColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: PawmartColors.green,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFE3F2DA),
    borderRadius: BorderRadius.circular(24),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/products/${product.productId}'),
      child: SizedBox(
        height: 218,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DÀNH CHO BÉ CƯNG',
                      style: TextStyle(
                        color: PawmartColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      product.productName,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PawmartColors.greenDark,
                        fontSize: 17,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.hasPublishedPrice
                          ? formatVnd(product.price)
                          : 'Xem chi tiết',
                      style: const TextStyle(
                        color: PawmartColors.greenDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        Text(
                          'Xem sản phẩm',
                          style: TextStyle(
                            color: PawmartColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 7),
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: PawmartColors.amber,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: Colors.white,
                    child: ProductArtwork(
                      imageUrl: product.primaryImageUrl,
                      height: 182,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PromotionStrip extends StatelessWidget {
  const _PromotionStrip({required this.title, required this.code});
  final String title;
  final String code;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDDA),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.local_offer_outlined, color: PawmartColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          code,
          style: const TextStyle(
            color: PawmartColors.green,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _CatalogReviewNotice extends StatelessWidget {
  const _CatalogReviewNotice();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PawmartColors.line),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catalog mới tại PawMart',
          style: TextStyle(
            color: PawmartColors.greenDark,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Bạn có thể xem sản phẩm mới. Ảnh và giá đang được kiểm tra; các mẫu này chưa mở bán.',
          style: TextStyle(color: PawmartColors.ink, height: 1.35),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 22, 12, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, this.sample});
  final Category category;
  final Product? sample;

  @override
  Widget build(BuildContext context) {
    final name = displayCategoryName(category.categoryName);
    final lower = name.toLowerCase();
    final (icon, tint, accent) = lower.contains('thức ăn')
        ? (
            Icons.restaurant_rounded,
            const Color(0xFFFFEBD9),
            PawmartColors.amber,
          )
        : lower.contains('đồ chơi')
        ? (Icons.toys_rounded, const Color(0xFFE9E5FF), const Color(0xFF7253A5))
        : lower.contains('chăm sóc')
        ? (Icons.spa_rounded, const Color(0xFFE0F2ED), PawmartColors.green)
        : lower.contains('bổ sung')
        ? (
            Icons.medical_services_outlined,
            const Color(0xFFFFE9E7),
            const Color(0xFFB95B50),
          )
        : (
            Icons.pets_rounded,
            const Color(0xFFE7EFFB),
            const Color(0xFF4B7299),
          );
    final imageUrl = category.imageUrl?.isNotEmpty == true
        ? category.imageUrl
        : sample?.primaryImageUrl;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go(
          '/customer/categories?categoryId=${category.categoryId}',
        ),
        child: Container(
          width: 138,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: PawmartColors.line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 62,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl == null
                    ? Icon(icon, color: accent, size: 28)
                    : ProductArtwork(imageUrl: imageUrl, height: 62),
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  color: PawmartColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.addingId,
    required this.onAdd,
  });
  final List<Product> products;
  final int? addingId;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    sliver: SliverGrid.builder(
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 258,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          adding: addingId == product.productId,
          onTap: () => context.push('/products/${product.productId}'),
          onAdd: () => onAdd(product),
        );
      },
    ),
  );
}

class _CustomerVoices extends StatelessWidget {
  const _CustomerVoices({required this.reviews});
  final PublicOrderReviews reviews;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khách hàng chia sẻ',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: PawmartColors.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${reviews.averageRating.toStringAsFixed(1)}/5 · ${reviews.total} đánh giá từ đơn hàng đã hoàn tất',
                style: const TextStyle(
                  color: PawmartColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: reviews.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final review = reviews.items[index];
              return SizedBox(
                width: 270,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${review.rating}/5 ★',
                              style: const TextStyle(
                                color: Color(0xFFB67B20),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Text(
                            review.comment?.isNotEmpty == true
                                ? review.comment!
                                : 'Đánh giá bằng số sao',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (review.shopReply?.isNotEmpty == true)
                          Text(
                            'PawMart: ${review.shopReply}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: PawmartColors.greenDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
