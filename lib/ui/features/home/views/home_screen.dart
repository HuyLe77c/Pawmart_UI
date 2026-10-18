import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/product.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/widgets/product_card.dart';
import '../view_models/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        HomeViewModel(CatalogRepository(context.read<ApiClient>()))..load(),
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
    if (_addingId != null) return;
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
      final extraProducts = model.products
          .where(
            (product) => !model.featured.any(
              (featured) => featured.productId == product.productId,
            ),
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
                      if (model.featured.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                            child: _SpotlightCard(
                              product: model.featured.first,
                            ),
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
                            height: 52,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: model.categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) => _CategoryCard(
                                category: model.categories[index],
                              ),
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
                      if (model.products.isEmpty)
                        const SliverToBoxAdapter(
                          child: EmptyState(
                            title: 'Chưa có sản phẩm',
                            message: 'Hãy quay lại sau khi cửa hàng cập nhật sản phẩm.',
                          ),
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
    padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
    child: Row(
      children: [
        const Icon(Icons.pets_rounded, color: PawmartColors.green, size: 25),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'PawMart',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
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
  );
}

class _SearchShortcut extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go('/customer/categories'),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: PawmartColors.line),
            borderRadius: BorderRadius.circular(14),
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
              Icon(
                Icons.arrow_forward_rounded,
                color: PawmartColors.ink,
                size: 20,
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
    color: const Color(0xFFF0EDE5),
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/products/${product.productId}'),
      child: SizedBox(
        height: 188,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SẢN PHẨM NỔI BẬT',
                      style: TextStyle(
                        color: PawmartColors.greenDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      product.productName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PawmartColors.ink,
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatVnd(product.price),
                      style: const TextStyle(
                        color: PawmartColors.greenDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Text(
                          'Xem sản phẩm',
                          style: TextStyle(
                            color: PawmartColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: PawmartColors.ink,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColoredBox(
                    color: Colors.white,
                    child: ProductArtwork(
                      imageUrl: product.primaryImageUrl,
                      height: 156,
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
  const _CategoryCard({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(26),
    child: InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: () =>
          context.go('/customer/categories?categoryId=${category.categoryId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: Border.all(color: PawmartColors.line),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.imageUrl?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(right: 9),
                child: SizedBox(
                  width: 30,
                  child: ProductArtwork(
                    imageUrl: category.imageUrl,
                    height: 30,
                  ),
                ),
              ),
            Text(
              category.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: PawmartColors.green,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
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
