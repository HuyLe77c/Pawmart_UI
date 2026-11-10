import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/catalog_filters.dart';
import '../../../core/formatters.dart';
import 'catalog_filter_sheet.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/cart_actions.dart';
import '../../../core/app_theme.dart';
import '../../../core/category_label.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_card.dart';
import '../view_models/catalog_view_model.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({
    super.key,
    this.initialSearch,
    this.initialCategoryId,
    this.initialPetType,
    this.initialShowFilters = false,
  });

  final String? initialSearch;
  final int? initialCategoryId;
  final String? initialPetType;
  final bool initialShowFilters;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) {
      final viewModel = CatalogViewModel(
        CatalogRepository(context.read<ApiClient>()),
      );
      viewModel.search = initialSearch ?? '';
      viewModel.categoryId = initialCategoryId;
      if (initialPetType == 'DOG' || initialPetType == 'CAT') {
        viewModel.petType = initialPetType!;
      }
      viewModel.load();
      return viewModel;
    },
    child: _CatalogContent(autoOpenFilters: initialShowFilters),
  );
}

class _CatalogContent extends StatefulWidget {
  const _CatalogContent({required this.autoOpenFilters});
  final bool autoOpenFilters;

  @override
  State<_CatalogContent> createState() => _CatalogContentState();
}

class _CatalogContentState extends State<_CatalogContent> {
  late final TextEditingController _searchController;
  int? _addingId;
  Timer? _searchDebounce;
  final ScrollController _gridController = ScrollController();

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
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(CatalogViewModel model, int page) async {
    await model.goToPage(page);
    if (mounted && _gridController.hasClients) _gridController.jumpTo(0);
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
      ('recommended', 'Khám phá', Icons.grid_view_rounded),
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
    if (_addingId != null || !product.canPurchase) return;
    setState(() => _addingId = product.productId);
    final added = await addProductToCart(context, productId: product.productId);
    if (mounted) {
      setState(() => _addingId = null);
      if (added) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã thêm vào giỏ hàng.')));
      }
    }
  }

  bool _autoOpened = false;

  Future<void> _showFilters(CatalogViewModel model) async {
    _searchDebounce?.cancel();
    // Preserve any search still waiting for debounce when opening the sheet.
    if (model.search != _searchController.text.trim()) {
      model.setSearch(_searchController.text.trim());
    }
    final filters = await showModalBottomSheet<CatalogFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      backgroundColor: PawmartColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => CatalogFilterSheet(
        initial: model.filters,
        categories: model.categories,
      ),
    );
    if (filters != null && mounted) await model.applyFilters(filters);
  }

  List<(String, String)> _selectedFilters(CatalogViewModel model) {
    final value = model.filters;
    return [
      if (value.petType != 'ALL')
        ('petType', value.petType == 'DOG' ? 'Chó' : 'Mèo'),
      if (value.categoryId != null)
        (
          'category',
          displayCategoryName(
            model.categories
                    .where(
                      (category) => category.categoryId == value.categoryId,
                    )
                    .firstOrNull
                    ?.categoryName ??
                'Danh mục đã chọn',
          ),
        ),
      if (value.breed?.isNotEmpty == true) ('breed', 'Giống: ${value.breed}'),
      if (value.minPrice != null || value.maxPrice != null)
        (
          'price',
          value.minPrice != null && value.maxPrice != null
              ? '${formatVnd(value.minPrice!)} – ${formatVnd(value.maxPrice!)}'
              : value.minPrice != null
              ? 'Từ ${formatVnd(value.minPrice!)}'
              : 'Đến ${formatVnd(value.maxPrice!)}',
        ),
      if (value.brand?.isNotEmpty == true) ('brand', value.brand!),
      if (value.inStockOnly) ('stock', 'Còn bán'),
    ];
  }

  @override
  Widget build(BuildContext context) => Consumer<CatalogViewModel>(
    builder: (context, model, _) {
      if (widget.autoOpenFilters && !_autoOpened && !model.isLoading) {
        _autoOpened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showFilters(model);
        });
      }
      final selected = _selectedFilters(model);
      final signedIn = context.watch<AuthViewModel>().isSignedIn;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cửa hàng PawMart'),
          leading: context.canPop() || signedIn
              ? IconButton(
                  tooltip: 'Quay lại',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/customer/home');
                    }
                  },
                )
              : null,
          actions: [
            if (!signedIn)
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
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _searchAsYouType,
                    onSubmitted: (value) {
                      _searchDebounce?.cancel();
                      model.setSearch(value.trim());
                    },
                    decoration: InputDecoration(
                      labelText: 'Tìm sản phẩm',
                      hintText: 'Thức ăn, đồ chơi, phụ kiện…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _searchDebounce?.cancel();
                                model.setSearch('');
                                setState(() {});
                              },
                            ),
                    ),
                  ),
                ),
                if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                              backgroundColor: PawmartColors.greenPale,
                              foregroundColor: PawmartColors.greenDark,
                            ),
                            onPressed:
                                model.isLoading && model.categories.isEmpty
                                ? null
                                : () => _showFilters(model),
                            icon: const Icon(
                              Icons.filter_alt_outlined,
                              size: 20,
                            ),
                            label: Text(
                              selected.isEmpty
                                  ? 'Bộ lọc'
                                  : 'Bộ lọc (${model.filters.activeCount})',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showSort(model),
                            icon: const Icon(Icons.swap_vert_rounded, size: 18),
                            label: Text(switch (model.sort) {
                              'price_asc' => 'Giá thấp trước',
                              'price_desc' => 'Giá cao trước',
                              'newest' => 'Mới nhất',
                              'name' => 'Tên A–Z',
                              _ => 'Sắp xếp',
                            }),
                          ),
                          if (selected.isNotEmpty)
                            TextButton(
                              onPressed: model.clearFilters,
                              child: const Text('Xóa bộ lọc'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (selected.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.textScalerOf(context).scale(18) + 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: selected.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, index) => InputChip(
                          label: Text(selected[index].$2),
                          onDeleted: () => model.applyFilters(
                            model.filters.without(selected[index].$1),
                          ),
                          deleteButtonTooltipMessage:
                              'Bỏ ${selected[index].$2}',
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        model.isLoading
                            ? 'Đang tìm sản phẩm…'
                            : '${model.totalItems} sản phẩm',
                        style: const TextStyle(
                          color: PawmartColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: model.isLoading && model.products.isEmpty
                      ? const LoadingState()
                      : model.errorMessage != null && model.products.isEmpty
                      ? ErrorPanel(
                          message: model.errorMessage!,
                          onRetry: model.load,
                        )
                      : model.products.isEmpty
                      ? RefreshIndicator(
                          onRefresh: model.load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              EmptyState(
                                title: 'Chưa có sản phẩm phù hợp',
                                message: 'Thử mở rộng khoảng giá hoặc bỏ bớt điều kiện lọc.',
                                actionLabel: selected.isNotEmpty
                                    ? 'Xóa bộ lọc'
                                    : null,
                                onAction: selected.isNotEmpty
                                    ? model.clearFilters
                                    : null,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: model.load,
                          child: CustomScrollView(
                            controller: _gridController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  4,
                                  20,
                                  16,
                                ),
                                sliver: SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                    final scale =
                                        MediaQuery.textScalerOf(context)
                                            .scale(14) /
                                        14;
                                    final columns =
                                        constraints.crossAxisExtent < 300 ||
                                            scale > 1.6
                                        ? 1
                                        : constraints.crossAxisExtent >= 1000
                                        ? 4
                                        : constraints.crossAxisExtent >= 700
                                        ? 3
                                        : 2;
                                    return SliverGrid.builder(
                                      itemCount: model.products.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            mainAxisExtent:
                                                278 +
                                                (scale > 1
                                                    ? (scale - 1) * 110
                                                    : 0),
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 14,
                                          ),
                                      itemBuilder: (context, index) {
                                        final product = model.products[index];
                                        return ProductCard(
                                          product: product,
                                          adding:
                                              _addingId == product.productId,
                                          categoryName: model.categories
                                              .where(
                                                (category) =>
                                                    category.categoryId ==
                                                    product.categoryId,
                                              )
                                              .firstOrNull
                                              ?.categoryName,
                                          onTap: () => context.push(
                                            '/products/${product.productId}',
                                          ),
                                          onAdd: () => _quickAdd(product),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              if (model.totalPages > 1)
                                SliverToBoxAdapter(
                                  child: _CatalogPagination(
                                    currentPage: model.currentPage,
                                    totalPages: model.totalPages,
                                    onPageSelected: (page) =>
                                        _goToPage(model, page),
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
    },
  );
}

class _CatalogPagination extends StatelessWidget {
  const _CatalogPagination({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 28),
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var page = 1; page <= totalPages; page++) ...[
              if (page > 1) const SizedBox(width: 8),
              SizedBox(
                width: 44,
                height: 44,
                child: page == currentPage
                    ? FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                        child: Text('$page'),
                      )
                    : OutlinedButton(
                        onPressed: () => onPageSelected(page),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: Text('$page'),
                      ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
