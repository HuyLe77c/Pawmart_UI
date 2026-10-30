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
import '../../../core/category_label.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_card.dart';
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
        leading: !context.canPop() && !context.read<AuthViewModel>().isSignedIn
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: PawmartColors.greenDark,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.pets_rounded, color: Colors.white),
                ),
              )
            : IconButton.filledTonal(
                tooltip: 'Quay lại',
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
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
            hintText: 'Tìm trong PawMart…',
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
                        Icons.pets_outlined,
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
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: model.categories.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _FilterChip(
                            label: 'Tất cả danh mục',
                            selected: model.categoryId == null,
                            onSelected: () => model.setCategory(null),
                          );
                        }
                        final category = model.categories[index - 1];
                        return _FilterChip(
                          label: displayCategoryName(category.categoryName),
                          selected: model.categoryId == category.categoryId,
                          onSelected: () =>
                              model.setCategory(category.categoryId),
                        );
                      },
                    ),
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
                        displayCategoryName(
                          model.categories
                                  .where(
                                    (c) => c.categoryId == model.categoryId,
                                  )
                                  .firstOrNull
                                  ?.categoryName ??
                              'Tất cả sản phẩm',
                        ),
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
                                    mainAxisExtent: 258,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                              itemBuilder: (context, index) {
                                final product = model.products[index];
                                return ProductCard(
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
      mainAxisExtent: 258,
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
    color: selected ? PawmartColors.greenPale : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: BorderSide(
        color: selected ? PawmartColors.greenPale : PawmartColors.line,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? PawmartColors.greenDark : PawmartColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
