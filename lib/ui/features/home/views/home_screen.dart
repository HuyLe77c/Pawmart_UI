import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/order.dart';
import '../../../../domain/models/promotion.dart';
import '../../../core/app_theme.dart';
import '../../../core/category_label.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/brand_lockup.dart';
import '../../../core/widgets/pet_illustrations.dart';
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
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openSearch() {
    final query = _search.text.trim();
    context.go(
      Uri(
        path: '/customer/categories',
        queryParameters: query.isEmpty ? null : {'search': query},
      ).toString(),
    );
  }

  Future<void> _addToCart(Product product) async {
    if (_addingId != null || !product.canPurchase) return;
    setState(() => _addingId = product.productId);
    try {
      final repository = CartRepository(context.read<ApiClient>());
      final cart = await repository.getCart();
      if (!mounted) return;
      final current = cart.items
          .where((line) => line.productId == product.productId)
          .firstOrNull;
      await repository.setQuantity(
        productId: product.productId,
        quantity: (current?.quantity ?? 0) + 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã thêm vào giỏ hàng.'),
            action: SnackBarAction(
              label: 'Xem giỏ',
              onPressed: () => context.go('/customer/cart'),
            ),
          ),
        );
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
                (p) =>
                    p.canPurchase &&
                    p.hasVerifiedImage &&
                    p.primaryImageUrl != null,
              )
              .firstOrNull ??
          model.products
              .where(
                (p) =>
                    p.canPurchase &&
                    p.hasVerifiedImage &&
                    p.primaryImageUrl != null,
              )
              .firstOrNull;
      final featuredIds = model.featured
          .map((product) => product.productId)
          .toSet();
      final extraProducts = model.products
          .where((product) => !featuredIds.contains(product.productId))
          .take(6)
          .toList(growable: false);
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F0),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: model.isLoading && model.products.isEmpty
                  ? const LoadingState()
                  : model.errorMessage != null && model.products.isEmpty
                  ? ErrorPanel(
                      message: model.errorMessage!,
                      onRetry: model.load,
                    )
                  : RefreshIndicator(
                      onRefresh: model.load,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          const SliverToBoxAdapter(child: _HomeHeader()),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                              child: TextField(
                                controller: _search,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _openSearch(),
                                decoration: InputDecoration(
                                  labelText: 'Tìm sản phẩm cho bé',
                                  hintText: 'Thức ăn, đồ chơi, phụ kiện…',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Tìm kiếm',
                                        onPressed: _openSearch,
                                        icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Lọc sản phẩm',
                                        icon: const Icon(Icons.tune_rounded),
                                        onPressed: () => context.push(
                                          Uri(
                                            path: '/customer/categories',
                                            queryParameters: {
                                              'filters': '1',
                                              if (_search.text
                                                  .trim()
                                                  .isNotEmpty)
                                                'search': _search.text.trim(),
                                            },
                                          ).toString(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: _ShoppingHero(product: heroProduct),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: _PetShoppingShortcuts(),
                          ),
                          if (model.categories.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _SectionTitle(
                                title: 'Bạn đang tìm gì?',
                                subtitle: 'Chọn nhanh theo danh mục',
                                action: 'Tất cả',
                                onTap: () => context.go('/customer/categories'),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: _CategoryCollection(
                                categories: model.categories.take(4).toList(),
                              ),
                            ),
                          ],
                          if (model.products.any(
                            (product) => product.isPreview,
                          ))
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                                child: _CatalogReviewNotice(),
                              ),
                            ),
                          if (model.featured.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _SectionTitle(
                                title: 'Sản phẩm nổi bật',
                                subtitle: 'Khám phá những món đồ cho bé',
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
                          if (model.promotions.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  0,
                                ),
                                child: _PromotionStrip(
                                  promotion: model.promotions.first,
                                ),
                              ),
                            ),
                          const SliverToBoxAdapter(child: _ShoppingSupport()),
                          if (extraProducts.isNotEmpty) ...[
                            SliverToBoxAdapter(
                              child: _SectionTitle(
                                title: 'Khám phá thêm',
                                subtitle: 'Thêm lựa chọn cho cuộc sống của bé',
                                action: 'Xem tất cả',
                                onTap: () => context.go('/customer/categories'),
                              ),
                            ),
                            _ProductGrid(
                              products: extraProducts,
                              addingId: _addingId,
                              onAdd: _addToCart,
                            ),
                          ],
                          if (model.products.isEmpty)
                            SliverToBoxAdapter(
                              child: EmptyState(
                                title: 'Cửa hàng đang cập nhật',
                                message: 'Bạn có thể xem danh mục hoặc hỏi PawMart để được hỗ trợ.',
                                actionLabel: 'Hỏi PawMart',
                                onAction: () => context.go('/customer/chat-ai'),
                              ),
                            ),
                          if (model.publicReviews?.items.isNotEmpty == true)
                            SliverToBoxAdapter(
                              child: _CustomerVoices(
                                reviews: model.publicReviews!,
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                28,
                              ),
                              child: TextButton.icon(
                                onPressed: () => context.push('/stores'),
                                icon: const Icon(Icons.storefront_outlined),
                                label: const Text('Ghé thăm cửa hàng PawMart'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
    child: Row(
      children: [
        const Expanded(child: BrandLockup(compact: true)),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.go('/customer/notifications'),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          tooltip: 'Giỏ hàng',
          onPressed: () => context.go('/customer/cart'),
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    ),
  );
}

class _ShoppingHero extends StatelessWidget {
  const _ShoppingHero({this.product});
  final Product? product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFE7EEDC),
      borderRadius: BorderRadius.circular(28),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final large = constraints.maxWidth > 650;
        final illustration = product == null
            ? const PetFamilyArtwork()
            : ProductArtwork(
                imageUrl: product!.primaryImageUrl,
                height: large ? 220 : 155,
              );
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn điều tốt\ncho bé mỗi ngày.',
              style: TextStyle(
                fontSize: large ? 38 : 26,
                fontWeight: FontWeight.w800,
                color: PawmartColors.greenDark,
                height: 1.13,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Từ bữa ăn ngon đến những giờ chơi vui.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: PawmartColors.greenDark,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go('/customer/categories'),
              child: const Text('Khám phá cửa hàng'),
            ),
          ],
        );
        if (MediaQuery.textScalerOf(context).scale(14) > 20 ||
            constraints.maxWidth < 290) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chọn điều tốt cho bé mỗi ngày.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    height: 100,
                    child: Center(child: illustration),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/customer/categories'),
                child: const Text('Khám phá cửa hàng'),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: large ? 5 : 6, child: copy),
            const SizedBox(width: 8),
            Expanded(
              flex: large ? 4 : 4,
              child: SizedBox(
                height: large ? 240 : 170,
                child: Center(child: illustration),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PetShoppingShortcuts extends StatelessWidget {
  const _PetShoppingShortcuts();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final kind in const [
            ('DOG', 'Mua cho cún', Color(0xFFF7E6CE)),
            ('CAT', 'Mua cho mèo', Color(0xFFE8EEE5)),
          ])
            SizedBox(
              width:
                  constraints.maxWidth < 310 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2,
              child: Material(
                color: kind.$3,
                borderRadius: BorderRadius.circular(18),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      context.go('/customer/categories?petType=${kind.$1}'),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 48,
                          child: PetPortraitArtwork(petType: kind.$1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kind.$2,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: PawmartColors.greenDark,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: PawmartColors.greenDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 12, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: PawmartColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );
}

class _CategoryCollection extends StatelessWidget {
  const _CategoryCollection({required this.categories});
  final List<Category> categories;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 780
            ? 4
            : constraints.maxWidth < 310 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21
            ? 1
            : 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final category in categories)
              SizedBox(
                width: (constraints.maxWidth - 12 * (columns - 1)) / columns,
                child: _CategoryCard(category: category),
              ),
          ],
        );
      },
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final Category category;
  @override
  Widget build(BuildContext context) {
    final name = displayCategoryName(category.categoryName);
    final lower = name.toLowerCase();
    final icon = lower.contains('thức ăn')
        ? Icons.restaurant_outlined
        : lower.contains('chơi')
        ? Icons.sports_baseball_outlined
        : lower.contains('chăm sóc') || lower.contains('vệ sinh')
        ? Icons.spa_outlined
        : lower.contains('thưởng')
        ? Icons.cookie_outlined
        : Icons.shopping_bag_outlined;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: PawmartColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(
          '/customer/categories?categoryId=${category.categoryId}',
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 25, color: PawmartColors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
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
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final columns = constraints.crossAxisExtent < 300 || scale > 1.6
            ? 1
            : constraints.crossAxisExtent >= 1000
            ? 4
            : constraints.crossAxisExtent >= 700
            ? 3
            : 2;
        return SliverGrid.builder(
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 278 + (scale > 1 ? (scale - 1) * 110 : 0),
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(
              key: ValueKey('home-product-${product.productId}'),
              product: product,
              adding: addingId == product.productId,
              onTap: () => context.push('/products/${product.productId}'),
              onAdd: () => onAdd(product),
            );
          },
        );
      },
    ),
  );
}

class _PromotionStrip extends StatelessWidget {
  const _PromotionStrip({required this.promotion});
  final Promotion promotion;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF9E6CE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 18,
              color: PawmartColors.greenDark,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Ưu đãi dành cho bạn',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PawmartColors.greenDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          promotion.promotionName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        if (promotion.minOrderAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Đơn hàng từ ${formatVnd(promotion.minOrderAmount)}',
              style: const TextStyle(fontSize: 12, color: PawmartColors.muted),
            ),
          ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            Text(
              promotion.code,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: PawmartColors.greenDark,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: promotion.code));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép mã ưu đãi.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_outlined, size: 16),
              label: const Text('Sao chép mã'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ShoppingSupport extends StatelessWidget {
  const _ShoppingSupport();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
    child: Material(
      color: PawmartColors.greenDark,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/customer/chat-ai'),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.forum_outlined, color: Color(0xFFF2D7A4), size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chưa biết chọn gì cho bé?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Hỏi PawMart về sản phẩm và cách chăm sóc.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFFC9E9D8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CatalogReviewNotice extends StatelessWidget {
  const _CatalogReviewNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 20, color: PawmartColors.green),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Các sản phẩm có nhãn “Sắp mở bán” hiện chỉ để tham khảo và chưa thể thêm vào giỏ.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: PawmartColors.greenDark,
            ),
          ),
        ),
      ],
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
