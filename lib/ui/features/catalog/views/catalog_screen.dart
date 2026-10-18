import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/product.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/cart_actions.dart';
import '../../../core/app_theme.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../../core/formatters.dart';
import '../view_models/catalog_view_model.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, this.initialSearch, this.initialCategoryId});

  final String? initialSearch;
  final int? initialCategoryId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) {
      final viewModel = CatalogViewModel(
        CatalogRepository(context.read<ApiClient>()),
      );
      viewModel.search = initialSearch ?? '';
      viewModel.categoryId = initialCategoryId;
      viewModel.load();
      return viewModel;
    },
    child: const _CatalogContent(),
  );
}

class _CatalogContent extends StatefulWidget {
  const _CatalogContent();

  @override
  State<_CatalogContent> createState() => _CatalogContentState();
}

class _CatalogContentState extends State<_CatalogContent> {
  late final TextEditingController _searchController;
  int? _addingId;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<CatalogViewModel>().search,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _searchAsYouType(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (mounted) context.read<CatalogViewModel>().setSearch(value.trim());
    });
  }

  void _showSort(CatalogViewModel model) {
    const options = [
      ('newest', 'Mới nhất', Icons.schedule_rounded),
      ('price_asc', 'Giá thấp trước', Icons.south_rounded),
      ('price_desc', 'Giá cao trước', Icons.north_rounded),
      ('name', 'Tên A–Z', Icons.sort_by_alpha_rounded),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sắp xếp sản phẩm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final option in options)
                ListTile(
                  minTileHeight: 52,
                  leading: Icon(option.$3, color: PawmartColors.green),
                  title: Text(option.$2),
                  trailing: model.sort == option.$1
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: PawmartColors.green,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    model.setSort(option.$1);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAdd(Product product) async {
    if (_addingId != null) return;
    setState(() => _addingId = product.productId);
    final added = await addProductToCart(context, productId: product.productId);
    if (mounted) {
      setState(() => _addingId = null);
      if (added)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng.')));
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<CatalogViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        leading: IconButton.filledTonal(
          tooltip: 'Quay lại',
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (context.read<AuthViewModel>().isSignedIn) {
              context.go('/customer/home');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: _searchAsYouType,
          onSubmitted: (value) {
            _searchDebounce?.cancel();
            model.setSearch(value.trim());
          },
          decoration: InputDecoration(
            hintText: 'Tìm tên, thương hiệu…',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: PawmartColors.green,
            ),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: () {
                      _searchController.clear();
                      _searchDebounce?.cancel();
                      model.setSearch('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
            fillColor: Colors.white,
          ),
        ),
        actions: [
          if (!context.read<AuthViewModel>().isSignedIn)
            IconButton(
              tooltip: 'Đăng nhập',
              onPressed: () => context.go('/sign-in'),
              icon: const Icon(Icons.person_outline),
            ),
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () => context.go('/customer/cart'),
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CatalogSectionLabel('DÀNH CHO THÚ CƯNG'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _PetChoice(
                        'Tất cả',
                        Icons.pets_rounded,
                        model.petType == 'ALL',
                        () => model.setPetType('ALL'),
                      ),
                      const SizedBox(width: 8),
                      _PetChoice(
                        'Chó',
                        Icons.cruelty_free_rounded,
                        model.petType == 'DOG',
                        () => model.setPetType('DOG'),
                      ),
                      const SizedBox(width: 8),
                      _PetChoice(
                        'Mèo',
                        Icons.pets_outlined,
                        model.petType == 'CAT',
                        () => model.setPetType('CAT'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CatalogSectionLabel('DANH MỤC'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _FilterChip(
                        label: 'Tất cả danh mục',
                        selected: model.categoryId == null,
                        onSelected: () => model.setCategory(null),
                      ),
                      for (final category in model.categories)
                        _FilterChip(
                          label: category.categoryName,
                          selected: model.categoryId == category.categoryId,
                          onSelected: () =>
                              model.setCategory(category.categoryId),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 9),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.categories
                                .where((c) => c.categoryId == model.categoryId)
                                .firstOrNull
                                ?.categoryName ??
                            'Tất cả sản phẩm',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        model.isLoading
                            ? 'Đang tìm…'
                            : '${model.totalItems} sản phẩm phù hợp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PawmartColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showSort(model),
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: Text(switch (model.sort) {
                    'price_asc' => 'Giá thấp',
                    'price_desc' => 'Giá cao',
                    'name' => 'Tên A–Z',
                    _ => 'Mới nhất',
                  }),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: model.isLoading && model.products.isEmpty
                ? const _CatalogLoadingGrid()
                : model.errorMessage != null && model.products.isEmpty
                ? ErrorPanel(
                    message: model.errorMessage!,
                    onRetry: () => model.load(refresh: true),
                  )
                : model.products.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => model.load(refresh: true),
                    child: ListView(
                      children: const [
                        SizedBox(height: 100),
                        EmptyState(
                          title: 'Chưa có sản phẩm phù hợp',
                          message: 'Thử đổi bộ lọc hoặc quay lại sau nhé.',
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => model.load(refresh: true),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 240)
                          model.loadMore();
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            sliver: SliverGrid.builder(
                              itemCount: model.products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 278,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: (context, index) {
                                final product = model.products[index];
                                return _CatalogProductCard(
                                  product: product,
                                  categoryName: model.categories
                                      .where(
                                        (c) =>
                                            c.categoryId == product.categoryId,
                                      )
                                      .firstOrNull
                                      ?.categoryName,
                                  adding: _addingId == product.productId,
                                  onTap: () => context.push(
                                    '/products/${product.productId}',
                                  ),
                                  onAdd: () => _quickAdd(product),
                                );
                              },
                            ),
                          ),
                          if (model.isLoadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                          if (model.errorMessage != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  model.errorMessage!,
                                  style: const TextStyle(
                                    color: PawmartColors.error,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class _CatalogLoadingGrid extends StatelessWidget {
  const _CatalogLoadingGrid();
  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisExtent: 278,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: 4,
    itemBuilder: (context, index) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PawmartColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 156,
            decoration: const BoxDecoration(
              color: PawmartColors.greenPale,
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: _CatalogSkeletonLine(width: 70, height: 10),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 11, 12, 0),
            child: _CatalogSkeletonLine(width: 130, height: 13),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 15),
            child: _CatalogSkeletonLine(width: 90, height: 13),
          ),
        ],
      ),
    ),
  );
}

class _CatalogSkeletonLine extends StatelessWidget {
  const _CatalogSkeletonLine({required this.width, required this.height});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

class _CatalogSectionLabel extends StatelessWidget {
  const _CatalogSectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w800,
      color: PawmartColors.muted,
    ),
  );
}

class _PetChoice extends StatelessWidget {
  const _PetChoice(this.label, this.icon, this.selected, this.onTap);
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? PawmartColors.green : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: selected ? PawmartColors.green : PawmartColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : PawmartColors.green,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : PawmartColors.ink,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFFFE5BD) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: BorderSide(
        color: selected ? const Color(0xFFE6BF85) : PawmartColors.line,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? const Color(0xFF754909) : PawmartColors.ink,
          ),
        ),
      ),
    ),
  );
}

class _CatalogProductCard extends StatefulWidget {
  const _CatalogProductCard({
    required this.product,
    required this.categoryName,
    required this.adding,
    required this.onTap,
    required this.onAdd,
  });
  final Product product;
  final String? categoryName;
  final bool adding;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  @override
  State<_CatalogProductCard> createState() => _CatalogProductCardState();
}

class _CatalogProductCardState extends State<_CatalogProductCard> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final brand = product.brand?.trim();
    final eyebrow = brand != null && brand.isNotEmpty
        ? '${widget.categoryName ?? 'Sản phẩm'} · $brand'
        : widget.categoryName ?? 'Sản phẩm';
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: pressed && !reduceMotion ? 0.975 : 1,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 110),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: PawmartColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ColoredBox(
                    color: const Color(0xFFF2F4EF),
                    child: ProductArtwork(
                      imageUrl: product.primaryImageUrl,
                      height: 156,
                    ),
                  ),
                  if (product.stockQuantity <= 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: PawmartColors.error,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'Hết hàng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (product.isFeatured && product.stockQuantity > 0)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5BD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Nổi bật',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF754909),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: product.stockQuantity > 0
                          ? Colors.white
                          : const Color(0xFFE8E9E6),
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: product.stockQuantity > 0 && !widget.adding
                            ? widget.onAdd
                            : null,
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                            child: widget.adding
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_rounded,
                                    color: product.stockQuantity > 0
                                        ? PawmartColors.green
                                        : PawmartColors.muted,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: PawmartColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatVnd(product.price),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: PawmartColors.greenDark,
                        ),
                      ),
                    ],
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
