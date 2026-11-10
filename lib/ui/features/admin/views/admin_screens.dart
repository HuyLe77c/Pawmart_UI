import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/app_dependencies.dart';
import '../../../core/formatters.dart';
import '../../../core/picked_image.dart';
import '../../../../data/services/api_client.dart';
import '../../../core/widgets/feedback_states.dart';
import '../../../core/widgets/product_artwork.dart';
import '../../auth/view_models/auth_view_model.dart';
import 'admin_design.dart';

String _compactOrderId(Object? value) {
  final id = '$value';
  return id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}

String? _adminOrderTime(Object? value) {
  final date = DateTime.tryParse('$value');
  if (date == null) return null;
  return DateFormat('HH:mm · dd/MM/yyyy').format(date.toLocal());
}

class _AdminQuickAction extends StatelessWidget {
  const _AdminQuickAction({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AdminPalette.softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AdminPalette.green, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminPalette.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AdminPalette.secondary,
          ),
        ],
      ),
    ),
  );
}

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});
  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic> revenue = {};
  List<dynamic> statuses = [];
  List<dynamic> lowStock = [];
  List<dynamic> recentOrders = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<AppDependencies>().apiClient;
      final values = await Future.wait([
        api.getJson('api/admin/reports/revenue'),
        api.getJson('api/admin/reports/orders-by-status'),
        api.getJson('api/admin/reports/low-stock'),
        api.getJson('api/admin/orders', query: {'page': '1', 'pageSize': '5'}),
      ]);
      if (!mounted) return;
      setState(() {
        revenue = values[0] as Map<String, dynamic>;
        statuses = values[1] as List<dynamic>;
        lowStock = values[2] as List<dynamic>;
        recentOrders =
            (values[3] as Map<String, dynamic>)['items'] as List<dynamic>? ??
            [];
      });
    } catch (e) {
      if (mounted) setState(() => error = _error(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminPalette.background,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/branding/pawmart-mark.png',
            width: 36,
            height: 36,
            semanticLabel: 'PawMart',
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              'PawMart / Quản trị',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
        const _AdminSignOutAction(),
      ],
    ),
    body: loading
        ? const LoadingState()
        : error != null
        ? ErrorPanel(message: error!, onRetry: load)
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
              children: [
                const AdminPageHeader(
                  title: 'Tổng quan cửa hàng',
                  subtitle: 'Theo dõi hoạt động và xử lý công việc hôm nay',
                ),
                const SizedBox(height: 20),
                AdminSurface(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CÔNG VIỆC HÔM NAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AdminPalette.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AdminQuickAction(
                        icon: Icons.pending_actions_rounded,
                        title: 'Đơn đang chờ',
                        detail:
                            '${statuses.where((s) => '${s['status']}'.toUpperCase() == 'PENDING').fold<int>(0, (count, s) => count + ((s['count'] as num?)?.toInt() ?? 0))} đơn cần xác nhận',
                        onTap: () => context.go('/admin/orders'),
                      ),
                      adminSeparator(),
                      _AdminQuickAction(
                        icon: Icons.inventory_2_outlined,
                        title: 'Kiểm tra tồn kho',
                        detail: '${lowStock.length} sản phẩm cần chú ý',
                        onTap: () => context.go('/admin/products'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AdminPalette.forest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            color: Color(0xFFB9DABF),
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Doanh thu hôm nay',
                            style: TextStyle(
                              color: Color(0xFFD7E7D9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        formatVnd(revenue['todayRevenue'] as num? ?? 0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFF42604A), height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFB9DABF),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${revenue['ordersToday'] ?? 0} đơn hàng hôm nay',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.28,
                  children: [
                    AdminMetric(
                      label: 'Doanh thu kỳ',
                      value: formatVnd(revenue['periodRevenue'] as num? ?? 0),
                      icon: Icons.insights_outlined,
                    ),
                    AdminMetric(
                      label: 'Sắp hết hàng',
                      value: '${lowStock.length}',
                      icon: Icons.inventory_2_outlined,
                      warning: lowStock.isNotEmpty,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const AdminSectionTitle('Đơn theo trạng thái'),
                if (statuses.isEmpty)
                  const AdminEmptyPanel(
                    icon: Icons.receipt_long_outlined,
                    title: 'Chưa có đơn hàng',
                    message: 'Các trạng thái sẽ xuất hiện khi có đơn mới.',
                  )
                else
                  AdminSurface(
                    child: Column(
                      children: [
                        for (var i = 0; i < statuses.length; i++) ...[
                          if (i > 0) adminSeparator(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              children: [
                                AdminStatusPill('${statuses[i]['status']}'),
                                const Spacer(),
                                Text(
                                  '${statuses[i]['count']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AdminPalette.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                const AdminSectionTitle('Cần kiểm tra tồn kho'),
                if (lowStock.isEmpty)
                  const AdminEmptyPanel(
                    icon: Icons.check_circle_outline,
                    title: 'Tồn kho ổn định',
                    message: 'Hiện không có sản phẩm sắp hết hàng.',
                  )
                else
                  AdminSurface(
                    child: Column(
                      children: [
                        for (var i = 0; i < lowStock.length; i++) ...[
                          if (i > 0) adminSeparator(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AdminPalette.amber,
                                  size: 21,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${lowStock[i]['productName']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AdminPalette.ink,
                                        ),
                                      ),
                                      Text(
                                        '${lowStock[i]['stockStatus']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AdminPalette.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Còn ${lowStock[i]['stockQuantity']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AdminPalette.amber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 26),
                const AdminSectionTitle('Đơn hàng gần đây'),
                if (recentOrders.isEmpty)
                  const AdminEmptyPanel(
                    icon: Icons.inbox_outlined,
                    title: 'Chưa có đơn gần đây',
                    message: 'Đơn mới sẽ được liệt kê tại đây.',
                  )
                else
                  AdminSurface(
                    child: Column(
                      children: [
                        for (var i = 0; i < recentOrders.length; i++) ...[
                          if (i > 0) adminSeparator(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Đơn #${_compactOrderId(recentOrders[i]['orderId'])}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AdminPalette.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      AdminStatusPill(
                                        '${recentOrders[i]['status']}',
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatVnd(recentOrders[i]['total'] as num),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AdminPalette.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
  );
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];
  List<dynamic> categories = [];
  Map<String, dynamic> summary = {};
  String search = '';
  final searchController = TextEditingController();
  Timer? searchDebounce;
  int? selectedCategoryId;
  String? selectedPetType;
  bool? selectedActive;
  int requestRevision = 0;
  int page = 1, total = 0;

  int _categoryCount(int categoryId) {
    final counts = summary['categories'] as List<dynamic>? ?? const [];
    final row = counts
        .where((entry) => (entry as Map)['categoryId'] == categoryId)
        .firstOrNull;
    return row is Map ? row['total'] as int? ?? 0 : 0;
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void changeFilter({
    int? categoryId,
    String? petType,
    bool? active,
    required String field,
  }) {
    setState(() {
      if (field == 'category') selectedCategoryId = categoryId;
      if (field == 'pet') selectedPetType = petType;
      if (field == 'active') selectedActive = active;
      page = 1;
    });
    load();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final revision = ++requestRevision;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<AppDependencies>().apiClient;
      final values = await Future.wait([
        api.getJson(
          'api/admin/products',
          query: {
            'page': '$page',
            'pageSize': '20',
            if (search.isNotEmpty) 'search': search,
            if (selectedCategoryId != null) 'categoryId': '$selectedCategoryId',
            'petType': ?selectedPetType,
            if (selectedActive != null) 'active': '$selectedActive',
          },
        ),
        api.getJson('api/admin/categories'),
        api
            .getJson('api/admin/products/summary')
            .catchError(
              (Object _) => <String, dynamic>{'categories': <dynamic>[]},
            ),
      ]);
      if (!mounted || revision != requestRevision) return;
      final response = values[0] as Map<String, dynamic>;
      setState(() {
        items = response['items'] as List<dynamic>? ?? [];
        total = response['totalItems'] as int? ?? 0;
        categories = values[1] as List<dynamic>;
        summary = values[2] as Map<String, dynamic>;
      });
    } catch (e) {
      if (mounted && revision == requestRevision) {
        setState(() => error = _error(e));
      }
    } finally {
      if (mounted && revision == requestRevision) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> setActive(Map<String, dynamic> product) async {
    try {
      await context.read<AppDependencies>().apiClient.patchJson(
        'api/products/${product['productId']}/active',
        {'isActive': !(product['isActive'] as bool)},
      );
      await load();
    } catch (e) {
      _snack(_error(e));
    }
  }

  Future<void> showCatalogReview(Map<String, dynamic> product) async {
    try {
      final data = await context.read<AppDependencies>().apiClient.getJson(
        'api/admin/products/${product['productId']}/catalog-review',
      ) as Map<String, dynamic>;
      if (!mounted) return;
      String state(String key) =>
          data[key] == 'VERIFIED' ? 'Đã xác minh' : 'Cần kiểm tra';
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kiểm duyệt sản phẩm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${data['modelName']}'),
                const SizedBox(height: 12),
                Text('Model: ${state('modelStatus')}'),
                Text('Ảnh: ${state('imageStatus')}'),
                Text(
                  'Giá VNĐ: ${state('priceStatus') == 'OWNER_SET' ? 'PawMart tự đặt' : state('priceStatus')}',
                ),
                Text(
                  'Mở bán: ${state('productStatus') == 'OWNER_APPROVED' ? 'PawMart đã duyệt' : state('productStatus')}',
                ),
                const SizedBox(height: 12),
                const Text('Nguồn sản phẩm'),
                SelectableText('${data['officialUrl']}'),
                if ((data['reviewNote'] as String?)?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text('${data['reviewNote']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack(_error(e));
    }
  }

  Future<void> edit([Map<String, dynamic>? product]) async {
    if (categories.isEmpty) {
      _snack('Cần tạo danh mục trước.');
      return;
    }
    final form = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) =>
            _ProductForm(product: product, categories: categories),
      ),
    );
    if (form == null || !mounted) return;
    final selectedImage = form.remove('_selectedImage') as XFile?;
    try {
      final api = context.read<AppDependencies>().apiClient;
      if (selectedImage != null) {
        final existingImages = product?['images'] as List<dynamic>? ?? [];
        form['images'] = existingImages
            .map((image) => Map<String, dynamic>.from(image as Map))
            .toList();
      }
      final saved = product == null
          ? await api.postJson('api/products', form)
          : await api.putJson('api/products/${product['productId']}', form);
      if (selectedImage != null) {
        final productId =
            product?['productId'] as int? ??
            (saved as Map<String, dynamic>)['productId'] as int;
        try {
          await api.postMultipart(
            'api/admin/products/$productId/images/upload',
            fileFieldName: 'file',
            file: selectedImage,
          );
        } catch (e) {
          _snack('Đã lưu sản phẩm nhưng tải ảnh thất bại: ${_error(e)}');
        }
      }
      await load();
    } catch (e) {
      _snack(_error(e));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminPalette.background,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Sản phẩm'),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
        const _AdminSignOutAction(),
      ],
    ),
    body: loading && categories.isEmpty
        ? const LoadingState()
        : error != null
        ? ErrorPanel(message: error!, onRetry: load)
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AdminPalette.green,
                        ),
                        hintText: 'Tìm tên, thương hiệu, SKU…',
                        suffixIcon: searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Xóa tìm kiếm',
                                onPressed: () {
                                  searchDebounce?.cancel();
                                  searchController.clear();
                                  setState(() {
                                    search = '';
                                    page = 1;
                                  });
                                  load();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        setState(() {});
                        searchDebounce?.cancel();
                        searchDebounce = Timer(
                          const Duration(milliseconds: 350),
                          () {
                            if (!mounted) return;
                            setState(() {
                              search = value.trim();
                              page = 1;
                            });
                            load();
                          },
                        );
                      },
                      onSubmitted: (value) {
                        searchDebounce?.cancel();
                        setState(() {
                          search = value.trim();
                          page = 1;
                        });
                        load();
                      },
                    ),
                    if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                      const SizedBox(height: 12),
                      _InventorySummary(summary: summary),
                      const SizedBox(height: 16),
                      const _AdminFilterLabel('DANH MỤC'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _AdminFilterPill(
                              label: 'Tất cả',
                              selected: selectedCategoryId == null,
                              onTap: () => changeFilter(field: 'category'),
                            ),
                            for (final raw in categories) ...[
                              const SizedBox(width: 7),
                              _AdminFilterPill(
                                label:
                                    '${(raw as Map)['categoryName']}  ${_categoryCount(raw['categoryId'] as int)}',
                                selected:
                                    selectedCategoryId == raw['categoryId'],
                                onTap: () => changeFilter(
                                  field: 'category',
                                  categoryId: raw['categoryId'] as int,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _AdminFilterPill(
                                    label: 'Mọi loại',
                                    selected: selectedPetType == null,
                                    onTap: () => changeFilter(field: 'pet'),
                                  ),
                                  const SizedBox(width: 7),
                                  _AdminFilterPill(
                                    label: 'Chó',
                                    selected: selectedPetType == 'DOG',
                                    onTap: () => changeFilter(
                                      field: 'pet',
                                      petType: 'DOG',
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  _AdminFilterPill(
                                    label: 'Mèo',
                                    selected: selectedPetType == 'CAT',
                                    onTap: () => changeFilter(
                                      field: 'pet',
                                      petType: 'CAT',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<bool?>(
                            tooltip: 'Lọc trạng thái bán',
                            color: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) =>
                                changeFilter(field: 'active', active: value),
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: null,
                                child: Text('Mọi trạng thái'),
                              ),
                              PopupMenuItem(
                                value: true,
                                child: Text('Đang bán'),
                              ),
                              PopupMenuItem(
                                value: false,
                                child: Text('Đang tắt'),
                              ),
                            ],
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                              ),
                              decoration: BoxDecoration(
                                color: selectedActive == null
                                    ? Colors.white
                                    : AdminPalette.softAmber,
                                border: Border.all(color: AdminPalette.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_list_rounded,
                                    size: 18,
                                    color: AdminPalette.forest,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedActive == null
                                        ? 'Trạng thái'
                                        : selectedActive!
                                        ? 'Đang bán'
                                        : 'Đang tắt',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            loading ? 'Đang lọc…' : '$total sản phẩm',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AdminPalette.ink,
                            ),
                          ),
                        ),
                        Text(
                          'Trang $page',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.secondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => edit(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm mới'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 42),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const _AdminInventorySkeleton()
                    : items.isEmpty
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: AdminEmptyPanel(
                            title:
                                search.isEmpty &&
                                    selectedCategoryId == null &&
                                    selectedPetType == null &&
                                    selectedActive == null
                                ? 'Chưa có sản phẩm'
                                : 'Không tìm thấy sản phẩm',
                            message:
                                search.isEmpty &&
                                    selectedCategoryId == null &&
                                    selectedPetType == null &&
                                    selectedActive == null
                                ? 'Thêm sản phẩm để bắt đầu quản lý cửa hàng.'
                                : 'Thử từ khóa hoặc bộ lọc khác.',
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 94),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final p = Map<String, dynamic>.from(
                            items[index] as Map,
                          );
                          final images = p['images'] as List<dynamic>?;
                          final firstImage = images?.firstOrNull;
                          final imageUrl = firstImage is Map
                              ? firstImage['imageUrl'] as String?
                              : null;
                          final categoryName = categories
                              .where(
                                (raw) =>
                                    (raw as Map)['categoryId'] ==
                                    p['categoryId'],
                              )
                              .firstOrNull;
                          final stock = p['stockQuantity'] as int? ?? 0;
                          final review = p['catalogReview'] as Map?;
                          final priceNeedsReview =
                              review != null &&
                              review['priceStatus'] != 'VERIFIED' &&
                              review['priceStatus'] != 'OWNER_SET';
                          final imageNeedsReview =
                              review != null &&
                              review['imageStatus'] != 'VERIFIED';
                          final lowThreshold =
                              p['lowStockThreshold'] as int? ?? 5;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: AdminPalette.border,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => edit(p),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: SizedBox(
                                              width: 72,
                                              height: 72,
                                              child: imageNeedsReview
                                                  ? const ColoredBox(
                                                      color: AdminPalette
                                                          .background,
                                                      child: Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color: AdminPalette
                                                            .secondary,
                                                      ),
                                                    )
                                                  : ProductArtwork(
                                                      imageUrl: imageUrl,
                                                      height: 72,
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${p['productName']}',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AdminPalette.ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  '${categoryName is Map ? categoryName['categoryName'] : 'Chưa phân loại'}  ·  ${switch (p['targetPetType']) {
                                                    'DOG' => 'Chó',
                                                    'CAT' => 'Mèo',
                                                    _ => 'Mọi loại',
                                                  }}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AdminPalette.secondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  priceNeedsReview
                                                      ? 'Chưa xác minh giá'
                                                      : formatVnd(
                                                          p['price'] as num,
                                                        ),
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: AdminPalette.forest,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          review == null
                                              ? const Icon(
                                                  Icons.edit_outlined,
                                                  color: AdminPalette.secondary,
                                                  size: 19,
                                                )
                                              : IconButton(
                                                  tooltip:
                                                      'Nguồn và kiểm duyệt',
                                                  onPressed: () =>
                                                      showCatalogReview(p),
                                                  icon: const Icon(
                                                    Icons.fact_check_outlined,
                                                    color:
                                                        AdminPalette.secondary,
                                                    size: 20,
                                                  ),
                                                ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      adminSeparator(),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          AdminStatusPill(
                                            p['isActive'] == true
                                                ? 'SELLING'
                                                : 'INACTIVE',
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              review != null &&
                                                      review['productStatus'] !=
                                                          'VERIFIED' &&
                                                      review['productStatus'] !=
                                                          'OWNER_APPROVED'
                                                  ? 'Chờ kiểm duyệt'
                                                  : stock <= 0
                                                  ? 'Hết hàng'
                                                  : stock <= lowThreshold
                                                  ? 'Sắp hết · $stock'
                                                  : 'Tồn kho · $stock',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: stock <= lowThreshold
                                                    ? AdminPalette.red
                                                    : AdminPalette.secondary,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            tooltip: p['isActive'] == true
                                                ? 'Ẩn sản phẩm'
                                                : 'Kích hoạt',
                                            onPressed: () => setActive(p),
                                            icon: Icon(
                                              p['isActive'] == true
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: AdminPalette.green,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if ((p['sku'] as String?)?.isNotEmpty ==
                                          true)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'SKU  ${p['sku']}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AdminPalette.secondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (total > 20)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: page > 1
                            ? () {
                                setState(() => page--);
                                load();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('Trang $page'),
                      IconButton(
                        onPressed: page * 20 < total
                            ? () {
                                setState(() => page++);
                                load();
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    child: Row(
      children: [
        _InventoryMetric(
          label: 'Tổng mặt hàng',
          value: summary['total'] as int? ?? 0,
          color: AdminPalette.ink,
        ),
        const SizedBox(
          height: 38,
          child: VerticalDivider(color: AdminPalette.border, width: 1),
        ),
        _InventoryMetric(
          label: 'Đang bán',
          value: summary['active'] as int? ?? 0,
          color: AdminPalette.green,
        ),
        const SizedBox(
          height: 38,
          child: VerticalDivider(color: AdminPalette.border, width: 1),
        ),
        _InventoryMetric(
          label: 'Cần nhập',
          value: summary['lowStock'] as int? ?? 0,
          color: AdminPalette.amber,
        ),
      ],
    ),
  );
}

class _AdminInventorySkeleton extends StatelessWidget {
  const _AdminInventorySkeleton();
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
    itemCount: 4,
    itemBuilder: (context, index) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: AdminSurface(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const _AdminSkeletonLine(width: 64, height: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AdminSkeletonLine(width: 170, height: 13),
                  SizedBox(height: 10),
                  _AdminSkeletonLine(width: 110, height: 10),
                  SizedBox(height: 10),
                  _AdminSkeletonLine(width: 90, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminSkeletonLine extends StatelessWidget {
  const _AdminSkeletonLine({required this.width, required this.height});
  final double width;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AdminPalette.background,
      borderRadius: BorderRadius.circular(7),
    ),
  );
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: AdminPalette.secondary),
        ),
      ],
    ),
  );
}

class _AdminFilterLabel extends StatelessWidget {
  const _AdminFilterLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      letterSpacing: 1,
      fontWeight: FontWeight.w800,
      color: AdminPalette.secondary,
    ),
  );
}

class _AdminFilterPill extends StatefulWidget {
  const _AdminFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_AdminFilterPill> createState() => _AdminFilterPillState();
}

class _AdminFilterPillState extends State<_AdminFilterPill> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: pressed && !reduceMotion ? 0.96 : 1,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 100),
      child: Material(
        color: widget.selected ? AdminPalette.forest : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: widget.selected ? AdminPalette.forest : AdminPalette.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => pressed = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.selected ? Colors.white : AdminPalette.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.product, required this.categories});
  final Map<String, dynamic>? product;
  final List<dynamic> categories;
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  static const _maxImageBytes = 20 * 1024 * 1024;
  static final _managedImageUrl = RegExp(
    r'^/uploads/products/[0-9a-f]{32}\.(jpg|png|webp)$',
    caseSensitive: false,
  );
  final name = TextEditingController(),
      price = TextEditingController(),
      stock = TextEditingController(),
      image = TextEditingController(),
      brand = TextEditingController(),
      description = TextEditingController(),
      ingredients = TextEditingController(),
      nutritionInfo = TextEditingController(),
      packageSize = TextEditingController(),
      lifeStage = TextEditingController(),
      feedingGuide = TextEditingController();
  XFile? selectedImage;
  bool choosingImage = false;
  int? categoryId;
  String target = 'ALL';
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name.text = p?['productName'] as String? ?? '';
    price.text = '${p?['price'] ?? ''}';
    stock.text = '${p?['stockQuantity'] ?? '0'}';
    brand.text = p?['brand'] as String? ?? '';
    description.text = p?['description'] as String? ?? '';
    ingredients.text = p?['ingredients'] as String? ?? '';
    nutritionInfo.text = p?['nutritionInfo'] as String? ?? '';
    packageSize.text = p?['packageSize'] as String? ?? '';
    lifeStage.text = p?['lifeStage'] as String? ?? '';
    feedingGuide.text = p?['feedingGuide'] as String? ?? '';
    categoryId =
        p?['categoryId'] as int? ??
        widget.categories.first['categoryId'] as int;
    target = p?['targetPetType'] as String? ?? 'ALL';
    final images = p?['images'] as List<dynamic>? ?? [];
    if (images.isNotEmpty) {
      image.text = images.first['imageUrl'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    stock.dispose();
    image.dispose();
    brand.dispose();
    description.dispose();
    ingredients.dispose();
    nutritionInfo.dispose();
    packageSize.dispose();
    lifeStage.dispose();
    feedingGuide.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    setState(() => choosingImage = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chỉ hỗ trợ ảnh JPG, PNG hoặc WebP.')),
        );
        return;
      }
      final length = await file.length();
      if (!mounted) return;
      if (length > _maxImageBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ảnh phải có dung lượng tối đa 20 MB.')),
        );
        return;
      }
      setState(() {
        selectedImage = file;
        image.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không chọn được ảnh: $e')));
      }
    } finally {
      if (mounted) setState(() => choosingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminPalette.background,
    appBar: AppBar(
      title: Text(
        widget.product == null ? 'Thêm sản phẩm' : 'Chỉnh sửa sản phẩm',
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdminPageHeader(
            title: 'Thông tin hàng hóa',
            subtitle: 'Cập nhật nội dung hiển thị trên cửa hàng',
          ),
          const SizedBox(height: 20),
          if (widget.product case final product?) ...[
            AdminSurface(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: ProductArtwork(
                        imageUrl:
                            ((product['images'] as List<dynamic>?)?.firstOrNull
                                    as Map?)?['imageUrl']
                                as String?,
                        height: 64,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product['productName']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AdminPalette.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU ${product['sku'] ?? '—'} · Tồn ${product['stockQuantity'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminPalette.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const _AdminFormSection('THÔNG TIN CƠ BẢN'),
          const SizedBox(height: 10),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
          ),
          TextField(
            controller: brand,
            decoration: const InputDecoration(labelText: 'Thương hiệu'),
          ),
          TextField(
            controller: packageSize,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Quy cách / khối lượng trên bao bì',
            ),
          ),
          TextField(
            controller: lifeStage,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Giai đoạn sống phù hợp',
            ),
          ),
          const SizedBox(height: 18),
          AdminSurface(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              maintainState: true,
              shape: const Border(),
              collapsedShape: const Border(),
              title: const Text(
                'Mô tả & nội dung',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink,
                ),
              ),
              subtitle: const Text(
                'Thành phần, dinh dưỡng và cách dùng',
                style: TextStyle(fontSize: 12, color: AdminPalette.secondary),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả sản phẩm',
                  ),
                ),
                TextField(
                  controller: ingredients,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Thành phần theo nhãn',
                  ),
                ),
                TextField(
                  controller: nutritionInfo,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Dinh dưỡng theo nhãn',
                  ),
                ),
                TextField(
                  controller: feedingGuide,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Hướng dẫn sử dụng theo nhãn',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _AdminFormSection('PHÂN LOẠI & BÁN HÀNG'),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: categoryId,
            decoration: const InputDecoration(labelText: 'Danh mục'),
            items: widget.categories
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c['categoryId'] as int,
                    child: Text('${c['categoryName']}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => categoryId = v),
          ),
          TextField(
            controller: price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Giá'),
          ),
          TextField(
            controller: stock,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Tồn kho'),
          ),
          DropdownButtonFormField<String>(
            initialValue: target,
            decoration: const InputDecoration(labelText: 'Phù hợp với'),
            items: const ['ALL', 'DOG', 'CAT', 'OTHER']
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(switch (e) {
                      'DOG' => 'Chó',
                      'CAT' => 'Mèo',
                      'OTHER' => 'Thú cưng khác',
                      _ => 'Mọi loại',
                    }),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => target = v ?? 'ALL'),
          ),
          const SizedBox(height: 18),
          const _AdminFormSection('HÌNH ẢNH'),
          const SizedBox(height: 10),
          TextField(
            controller: image,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL ảnh (HTTP hoặc HTTPS)',
              hintText: 'https://example.com/anh-san-pham.jpg',
            ),
            onChanged: (value) {
              if (value.trim().isNotEmpty && selectedImage != null) {
                setState(() {
                  selectedImage = null;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: choosingImage ? null : _chooseImage,
              icon: choosingImage
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                selectedImage == null
                    ? 'Chọn ảnh từ thiết bị'
                    : 'Đổi ảnh đã chọn',
              ),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('JPG, PNG, WebP • tối đa 20 MB'),
          ),
          if (selectedImage != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PickedImage(
                file: selectedImage!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 80,
                  child: Center(child: Text('Không xem trước được ảnh này.')),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  selectedImage = null;
                }),
                icon: const Icon(Icons.close),
                label: const Text('Bỏ ảnh đã chọn'),
              ),
            ),
          ],
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AdminPalette.border)),
        ),
        child: FilledButton.icon(
          icon: const Icon(Icons.save_outlined),
          onPressed: () {
            final cost = double.tryParse(price.text);
            final quantity = int.tryParse(stock.text);
            final imageUrl = image.text.trim();
            if (name.text.trim().length < 2 ||
                cost == null ||
                cost <= 0 ||
                quantity == null ||
                quantity < 0 ||
                categoryId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Nhập tên, giá lớn hơn 0, tồn kho không âm và danh mục.',
                  ),
                ),
              );
              return;
            }
            final uri = Uri.tryParse(imageUrl);
            final validImageUrl =
                imageUrl.isEmpty ||
                (uri != null &&
                    uri.hasAuthority &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) ||
                _managedImageUrl.hasMatch(imageUrl);
            if (!validImageUrl) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Nhập URL ảnh HTTP(S) hợp lệ hoặc chọn ảnh từ máy.',
                  ),
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'productName': name.text.trim(),
              'brand': brand.text.trim().isEmpty ? null : brand.text.trim(),
              'categoryId': categoryId,
              'price': cost,
              'stockQuantity': quantity,
              'lowStockThreshold': widget.product?['lowStockThreshold'] ?? 5,
              'targetPetType': target,
              'isFeatured': widget.product?['isFeatured'] ?? false,
              'description': description.text.trim().isEmpty
                  ? null
                  : description.text.trim(),
              'ingredients': ingredients.text.trim().isEmpty
                  ? null
                  : ingredients.text.trim(),
              'nutritionInfo': nutritionInfo.text.trim().isEmpty
                  ? null
                  : nutritionInfo.text.trim(),
              'packageSize': packageSize.text.trim().isEmpty
                  ? null
                  : packageSize.text.trim(),
              'lifeStage': lifeStage.text.trim().isEmpty
                  ? null
                  : lifeStage.text.trim(),
              'feedingGuide': feedingGuide.text.trim().isEmpty
                  ? null
                  : feedingGuide.text.trim(),
              'sku': widget.product?['sku'],
              'images':
                  widget.product != null &&
                      imageUrl ==
                          ((widget.product!['images'] as List<dynamic>?)
                                      ?.firstOrNull?['imageUrl']
                                  as String? ??
                              '')
                  ? widget.product!['images']
                  : imageUrl.isEmpty
                  ? []
                  : [
                      {
                        'imageUrl': imageUrl,
                        'isPrimary': true,
                        'displayOrder': 0,
                      },
                    ],
              '_selectedImage': selectedImage,
            });
          },
          label: const Text('Lưu sản phẩm'),
        ),
      ),
    ),
  );
}

class _AdminFormSection extends StatelessWidget {
  const _AdminFormSection(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
      color: AdminPalette.green,
    ),
  );
}

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];
  String status = 'ALL';
  int page = 1;
  int total = 0;
  int requestRevision = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final revision = ++requestRevision;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await context.read<AppDependencies>().apiClient.getJson(
        'api/admin/orders',
        query: {
          'page': '$page',
          'pageSize': '20',
          if (status != 'ALL') 'status': status,
        },
      ) as Map<String, dynamic>;
      if (!mounted || revision != requestRevision) return;
      setState(() {
        items = result['items'] as List<dynamic>? ?? [];
        total = result['totalItems'] as int? ?? 0;
      });
    } catch (e) {
      if (mounted && revision == requestRevision) {
        setState(() => error = _error(e));
      }
    } finally {
      if (mounted && revision == requestRevision) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> move(Map<String, dynamic> order) async {
    final api = context.read<AppDependencies>().apiClient;
    final choices = switch (order['status']) {
      'PENDING' => ['CONFIRMED', 'CANCELLED'],
      'CONFIRMED' => ['SHIPPING'],
      'SHIPPING' => ['DELIVERED'],
      _ => <String>[],
    };
    if (choices.isEmpty) return;
    final next = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chuyển trạng thái đơn',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            ...choices.map(
              (s) => ListTile(
                title: AdminStatusPill(s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, s),
              ),
            ),
          ],
        ),
      ),
    );
    if (next == null) return;
    try {
      await api.putJson('api/admin/orders/${order['orderId']}/status', {
        'status': next,
      });
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  Future<void> showDetails(Map<String, dynamic> order) async {
    try {
      final detail = await context.read<AppDependencies>().apiClient.getJson(
        'api/admin/orders/${order['orderId']}',
      ) as Map<String, dynamic>;
      if (!mounted) return;
      final change = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AdminPalette.background,
        builder: (context) => _AdminOrderDetails(detail: detail),
      );
      if (change == 'STATUS' && mounted) await move(order);
      if (change == 'PAYMENT' && mounted) await confirmPayment(detail);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  Future<void> confirmPayment(Map<String, dynamic> detail) async {
    final isQr = detail['paymentMethod'] == 'BANK_QR';
    final formKey = GlobalKey<FormState>();
    final expectedAmount = (detail['total'] as num).toDouble();
    var amount = expectedAmount.toStringAsFixed(0);
    var bankTransactionId = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isQr ? 'Đối soát chuyển khoản QR' : 'Xác nhận đã thu COD'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isQr
                      ? 'Chỉ xác nhận sau khi thấy giao dịch đúng số tiền và nội dung trên sao kê ngân hàng.'
                      : 'Chỉ xác nhận sau khi đã giao hàng và thu đủ tiền mặt.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  initialValue: amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số tiền đã nhận (VNĐ)',
                  ),
                  onChanged: (value) => amount = value.trim(),
                  validator: (value) =>
                      double.tryParse(value?.trim() ?? '') == expectedAmount
                      ? null
                      : 'Số tiền phải khớp chính xác với đơn hàng',
                ),
                if (isQr) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mã giao dịch trên sao kê',
                    ),
                    onChanged: (value) => bankTransactionId = value.trim(),
                    validator: (value) => (value?.trim().length ?? 0) >= 6
                        ? null
                        : 'Nhập mã giao dịch ngân hàng',
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Xác nhận đã nhận tiền'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<AppDependencies>().apiClient.postJson(
        'api/admin/orders/${detail['orderId']}/payment/confirm',
        {
          'receivedAmount': double.parse(amount),
          if (isQr) 'bankTransactionId': bankTransactionId,
        },
      );
      await load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận thanh toán sau đối soát.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminPalette.background,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Đơn hàng'),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: load,
          icon: const Icon(Icons.refresh),
        ),
        const _AdminSignOutAction(),
      ],
    ),
    body: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 22, 18, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AdminPageHeader(
              title: 'Xử lý đơn hàng',
              subtitle: 'Lọc đơn theo tiến độ và cập nhật trạng thái',
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          child: Row(
            children:
                [
                      'ALL',
                      'PENDING',
                      'CONFIRMED',
                      'SHIPPING',
                      'DELIVERED',
                      'CANCELLED',
                    ]
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(switch (s) {
                            'ALL' => 'Tất cả',
                            'PENDING' => 'Chờ xử lý',
                            'CONFIRMED' => 'Đã xác nhận',
                            'SHIPPING' => 'Đang giao',
                            'DELIVERED' => 'Đã giao',
                            _ => 'Đã hủy',
                          }),
                          selected: status == s,
                          onSelected: (_) {
                            setState(() {
                              status = s;
                              page = 1;
                            });
                            load();
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: Row(
            children: [
              Text(
                loading ? 'Đang tải đơn…' : '$total đơn hàng',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AdminPalette.ink,
                ),
              ),
              const Spacer(),
              if (total > 20)
                Text(
                  'Trang $page / ${(total / 20).ceil()}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminPalette.secondary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const LoadingState()
              : error != null
              ? ErrorPanel(message: error!, onRetry: load)
              : items.isEmpty
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: AdminEmptyPanel(
                      title: 'Không có đơn hàng',
                      message: status == 'ALL'
                          ? 'Đơn hàng mới sẽ xuất hiện tại đây.'
                          : 'Chưa có đơn ở trạng thái này.',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final o = Map<String, dynamic>.from(items[i] as Map);
                    final createdAt = _adminOrderTime(o['createdAt']);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AdminSurface(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => showDetails(o),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Tooltip(
                                        message: 'Mã đầy đủ: ${o['orderId']}',
                                        child: Text(
                                          'Đơn #${_compactOrderId(o['orderId'])}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AdminPalette.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                    AdminStatusPill('${o['status']}'),
                                  ],
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    createdAt,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AdminPalette.secondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                adminSeparator(),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.credit_card_outlined,
                                      size: 17,
                                      color: AdminPalette.secondary,
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        '${o['paymentMethod'] == 'BANK_QR'
                                            ? 'QR chuyển khoản'
                                            : o['paymentMethod'] == 'COD'
                                            ? 'COD'
                                            : o['paymentMethod']} · ${o['paymentStatus'] == 'SUCCESS' ? 'Đã thu' : 'Chờ tiền'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AdminPalette.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                Row(
                                  children: [
                                    Text(
                                      formatVnd(o['total'] as num),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AdminPalette.forest,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Text(
                                      'Xem chi tiết',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AdminPalette.green,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: AdminPalette.green,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (total > 20 && !loading && error == null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: page > 1
                        ? () {
                            setState(() => page--);
                            load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Trước'),
                  ),
                  TextButton.icon(
                    onPressed: page * 20 < total
                        ? () {
                            setState(() => page++);
                            load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Tiếp'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class AdminMoreScreen extends StatefulWidget {
  const AdminMoreScreen({super.key});
  @override
  State<AdminMoreScreen> createState() => _AdminMoreScreenState();
}

class _AdminMoreScreenState extends State<AdminMoreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 4, vsync: this);
  final Map<int, List<dynamic>> data = {};
  final Map<int, int> categoryCounts = {};
  bool loading = true;
  String? error;
  int requestRevision = 0;
  final endpoints = const [
    'api/admin/categories',
    'api/promotions/admin',
    'api/admin/stores',
  ];
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final revision = ++requestRevision;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final api = context.read<AppDependencies>().apiClient;
      final results = await Future.wait([
        api.getJson(endpoints[0]),
        api.getJson(endpoints[1], query: {'page': '1', 'pageSize': '50'}),
        api.getJson(endpoints[2]),
        api.getJson('api/admin/products/summary'),
      ]);
      if (!mounted || revision != requestRevision) return;
      setState(() {
        for (var i = 0; i < endpoints.length; i++) {
          final result = results[i];
          data[i] = result is Map<String, dynamic>
              ? (result['items'] as List<dynamic>? ?? [])
              : result as List<dynamic>;
        }
        categoryCounts.clear();
        final counts =
            (results[3] as Map<String, dynamic>)['categories']
                as List<dynamic>? ??
            [];
        for (final raw in counts) {
          final row = raw as Map;
          final id = row['categoryId'] as int?;
          if (id != null) categoryCounts[id] = row['total'] as int? ?? 0;
        }
      });
    } catch (e) {
      if (mounted && revision == requestRevision) {
        setState(() => error = _error(e));
      }
    } finally {
      if (mounted && revision == requestRevision) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> toggle(int tab, Map<String, dynamic> row) async {
    final base = switch (tab) {
      0 => 'api/categories',
      1 => 'api/promotions',
      _ => 'api/stores',
    };
    final id =
        row[switch (tab) {
          0 => 'categoryId',
          1 => 'promotionId',
          _ => 'storeId',
        }];
    try {
      await context.read<AppDependencies>().apiClient.patchJson(
        '$base/$id/active',
        {'isActive': !(row['isActive'] as bool)},
      );
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  Future<void> create([Map<String, dynamic>? existing]) async {
    final tab = tabs.index;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _SimpleAdminForm(kind: tab, existing: existing),
    );
    if (result == null || !mounted) return;
    final base = switch (tab) {
      0 => 'api/categories',
      1 => 'api/promotions',
      _ => 'api/stores',
    };
    try {
      final api = context.read<AppDependencies>().apiClient;
      if (existing == null) {
        await api.postJson(base, result);
      } else {
        final id =
            existing[switch (tab) {
              0 => 'categoryId',
              1 => 'promotionId',
              _ => 'storeId',
            }];
        await api.putJson('$base/$id', result);
      }
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  Future<void> broadcast() async {
    final request = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _BroadcastForm(),
    );
    if (request == null || !mounted) return;
    try {
      final result = await context.read<AppDependencies>().apiClient.postJson(
        'api/admin/notifications/broadcast',
        request,
      ) as Map<String, dynamic>;
      if (!mounted) return;
      final push = result['pushAvailable'] == true
          ? 'Push đã gửi: ${result['pushSent'] ?? 0}'
          : 'Thông báo đã lưu trong ứng dụng; push chưa cấu hình.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu cho ${result['recipients'] ?? 0} khách. $push'),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không gửi được thông báo. Hãy thử lại.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AdminPalette.background,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: const Text('Quản lý'),
      actions: [
        IconButton(
          tooltip: 'Gửi thông báo khách hàng',
          onPressed: broadcast,
          icon: const Icon(Icons.campaign_outlined),
        ),
        const _AdminSignOutAction(),
      ],
    ),
    body: loading
        ? const LoadingState()
        : error != null
        ? ErrorPanel(message: error!, onRetry: load)
        : Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 22, 18, 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AdminPageHeader(
                    title: 'Vận hành cửa hàng',
                    subtitle: 'Danh mục, ưu đãi, điểm bán và đánh giá',
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AdminPalette.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: tabs,
                  dividerHeight: 0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AdminPalette.softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: AdminPalette.forest,
                  unselectedLabelColor: AdminPalette.secondary,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Danh mục'),
                    Tab(text: 'Ưu đãi'),
                    Tab(text: 'Điểm bán'),
                    Tab(text: 'Đánh giá'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: tabs,
                  children: List.generate(4, (tab) {
                    if (tab == 3) return const _AdminReviewsPanel();
                    final rows = data[tab] ?? [];
                    final label = switch (tab) {
                      0 => 'danh mục',
                      1 => 'chương trình',
                      _ => 'điểm bán',
                    };
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
                      itemCount: rows.isEmpty ? 2 : rows.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${rows.length} $label',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AdminPalette.ink,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => create(),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Thêm'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (rows.isEmpty) {
                          return AdminEmptyPanel(
                            title: 'Chưa có $label',
                            message: 'Nhấn Thêm để tạo $label đầu tiên.',
                            icon: tab == 0
                                ? Icons.category_outlined
                                : tab == 1
                                ? Icons.local_offer_outlined
                                : Icons.store_outlined,
                          );
                        }
                        final r = Map<String, dynamic>.from(rows[i - 1] as Map);
                        final title =
                            r[switch (tab) {
                              0 => 'categoryName',
                              1 => 'promotionName',
                              _ => 'storeName',
                            }];
                        final desc = tab == 1
                            ? '${r['code']} · ${r['discountType']} ${r['discountValue']}'
                            : tab == 2
                            ? '${r['storeType'] == 'WAREHOUSE' ? 'Kho hàng' : 'Cửa hàng'} · ${r['address']}'
                            : '${r['description'] ?? ''}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AdminSurface(
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              onTap: () => create(r),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AdminPalette.softGreen,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        tab == 0
                                            ? Icons.category_outlined
                                            : tab == 1
                                            ? Icons.local_offer_outlined
                                            : Icons.store_outlined,
                                        color: AdminPalette.green,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$title',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AdminPalette.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AdminPalette.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              AdminStatusPill(
                                                r['isActive'] == true
                                                    ? 'ACTIVE'
                                                    : 'INACTIVE',
                                              ),
                                              if (tab == 0)
                                                Text(
                                                  '${categoryCounts[r['categoryId'] as int] ?? 0} sản phẩm',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color:
                                                        AdminPalette.secondary,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: r['isActive'] == true
                                          ? 'Tắt'
                                          : 'Bật',
                                      onPressed: () => toggle(tab, r),
                                      icon: Icon(
                                        r['isActive'] == true
                                            ? Icons.toggle_on
                                            : Icons.toggle_off,
                                        color: r['isActive'] == true
                                            ? AdminPalette.green
                                            : AdminPalette.secondary,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
  );
}

class _AdminReviewsPanel extends StatefulWidget {
  const _AdminReviewsPanel();

  @override
  State<_AdminReviewsPanel> createState() => _AdminReviewsPanelState();
}

class _AdminReviewsPanelState extends State<_AdminReviewsPanel> {
  int page = 1;
  int total = 0;
  int requestRevision = 0;
  bool loading = true;
  String? error;
  List<dynamic> reviews = const [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final revision = ++requestRevision;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await context.read<AppDependencies>().apiClient.getJson(
        'api/admin/reviews',
        query: {'page': '$page', 'pageSize': '20'},
      ) as Map<String, dynamic>;
      if (!mounted || revision != requestRevision) return;
      setState(() {
        reviews = result['items'] as List<dynamic>? ?? const [];
        total = result['totalItems'] as int? ?? 0;
      });
    } catch (cause) {
      if (mounted && revision == requestRevision) {
        setState(() => error = _error(cause));
      }
    } finally {
      if (mounted && revision == requestRevision) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> reply(Map<String, dynamic> review) async {
    final initial = review['shopReply'] as String? ?? '';
    var draft = initial;
    final answer = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Phản hồi khách hàng'),
        content: TextFormField(
          initialValue: initial,
          maxLines: 4,
          maxLength: 600,
          decoration: const InputDecoration(
            hintText: 'Cảm ơn bạn đã chia sẻ…',
            helperText: 'Để trống và lưu để gỡ phản hồi.',
            helperMaxLines: 2,
          ),
          onChanged: (value) => draft = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, draft),
            child: const Text('Lưu phản hồi'),
          ),
        ],
      ),
    );
    if (answer == null || !mounted) return;
    try {
      await context.read<AppDependencies>().apiClient.putJson(
        'api/admin/reviews/${review['reviewId']}/reply',
        {'reply': answer.trim()},
      );
      await load();
    } catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(cause))));
      }
    }
  }

  Future<void> setVisibility(Map<String, dynamic> review) async {
    try {
      await context.read<AppDependencies>().apiClient.putJson(
        'api/admin/reviews/${review['reviewId']}/visibility',
        {'isVisible': review['isVisible'] != true},
      );
      await load();
    } catch (cause) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(cause))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && reviews.isEmpty) return const LoadingState();
    if (error != null && reviews.isEmpty) {
      return ErrorPanel(message: error!, onRetry: load);
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 96),
        children: [
          Row(
            children: [
              Text(
                '$total đánh giá từ đơn hàng',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AdminPalette.ink,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Làm mới đánh giá',
                onPressed: load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (reviews.isEmpty)
            const AdminEmptyPanel(
              title: 'Chưa có đánh giá',
              message: 'Đánh giá của các đơn đã giao và thanh toán sẽ xuất hiện ở đây.',
              icon: Icons.rate_review_outlined,
            ),
          for (final row in reviews) ...[
            Builder(
              builder: (context) {
                final review = Map<String, dynamic>.from(row as Map);
                final orderId = '${review['orderId']}';
                final rating = review['rating'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AdminSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${review['authorName']} · #${orderId.substring(0, orderId.length < 8 ? orderId.length : 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '$rating/5 ★',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB67B20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['comment'] as String? ??
                              'Khách chỉ chấm điểm sao.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['sharePublicly'] == true
                              ? review['isVisible'] == true
                                    ? 'Được phép hiển thị công khai'
                                    : 'Đã ẩn khỏi công khai'
                              : 'Khách chọn đánh giá riêng tư',
                          style: const TextStyle(
                            color: AdminPalette.secondary,
                            fontSize: 12,
                          ),
                        ),
                        if ((review['shopReply'] as String?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 8),
                          Text(
                            'PawMart: ${review['shopReply']}',
                            style: const TextStyle(color: AdminPalette.forest),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => reply(review),
                              icon: const Icon(Icons.reply_rounded, size: 18),
                              label: Text(
                                review['shopReply'] == null
                                    ? 'Phản hồi'
                                    : 'Sửa phản hồi',
                              ),
                            ),
                            if (review['sharePublicly'] == true)
                              TextButton.icon(
                                onPressed: () => setVisibility(review),
                                icon: Icon(
                                  review['isVisible'] == true
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  review['isVisible'] == true ? 'Ẩn' : 'Hiện',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          if (total > 20)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: page <= 1
                      ? null
                      : () {
                          setState(() => page--);
                          load();
                        },
                  child: const Text('Trang trước'),
                ),
                Text('Trang $page'),
                TextButton(
                  onPressed: page * 20 >= total
                      ? null
                      : () {
                          setState(() => page++);
                          load();
                        },
                  child: const Text('Trang sau'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AdminOrderDetails extends StatelessWidget {
  const _AdminOrderDetails({required this.detail});
  final Map<String, dynamic> detail;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: FractionallySizedBox(
      heightFactor: 0.78,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Đơn #${_compactOrderId(detail['orderId'])}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AdminPalette.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sao chép mã đơn đầy đủ',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: '${detail['orderId']}'),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã đơn')),
                        );
                      },
                      icon: const Icon(Icons.copy_outlined, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AdminStatusPill('${detail['status']}'),
                const SizedBox(height: 24),
                const AdminSectionTitle('Thông tin giao hàng'),
                AdminSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detail['recipientName']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminPalette.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detail['recipientPhone']}',
                        style: const TextStyle(color: AdminPalette.secondary),
                      ),
                      const SizedBox(height: 10),
                      adminSeparator(),
                      const SizedBox(height: 10),
                      Text(
                        '${detail['shippingAddress']}',
                        style: const TextStyle(
                          color: AdminPalette.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const AdminSectionTitle('Thanh toán'),
                AdminSurface(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.credit_card_outlined,
                        color: AdminPalette.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          detail['paymentMethod'] == 'BANK_QR'
                              ? 'Chuyển khoản QR'
                              : detail['paymentMethod'] == 'COD'
                              ? 'Thu tiền khi giao'
                              : '${detail['paymentMethod']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        detail['paymentStatus'] == 'SUCCESS'
                            ? 'Đã nhận tiền'
                            : detail['paymentStatus'] == 'PENDING'
                            ? 'Chờ thanh toán'
                            : '${detail['paymentStatus']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminPalette.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const AdminSectionTitle('Sản phẩm trong đơn'),
                AdminSurface(
                  child: Column(
                    children: [
                      for (final item
                          in detail['items'] as List<dynamic>? ?? const []) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['productName']}  × ${item['quantity']}',
                                style: const TextStyle(color: AdminPalette.ink),
                              ),
                            ),
                            Text(
                              formatVnd(item['lineTotal'] as num),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      adminSeparator(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tổng cộng',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AdminPalette.ink,
                              ),
                            ),
                          ),
                          Text(
                            formatVnd(detail['total'] as num),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AdminPalette.forest,
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
          if (['PENDING', 'CONFIRMED', 'SHIPPING'].contains(detail['status']) ||
              (detail['paymentStatus'] == 'PENDING' &&
                  detail['status'] != 'CANCELLED' &&
                  (detail['paymentMethod'] == 'BANK_QR' ||
                      (detail['paymentMethod'] == 'COD' &&
                          detail['status'] == 'DELIVERED'))))
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Row(
                children: [
                  if ([
                    'PENDING',
                    'CONFIRMED',
                    'SHIPPING',
                  ].contains(detail['status']))
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, 'STATUS'),
                        child: const Text('Trạng thái đơn'),
                      ),
                    ),
                  if (detail['paymentStatus'] == 'PENDING' &&
                      detail['status'] != 'CANCELLED' &&
                      (detail['paymentMethod'] == 'BANK_QR' ||
                          (detail['paymentMethod'] == 'COD' &&
                              detail['status'] == 'DELIVERED'))) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, 'PAYMENT'),
                        child: const Text('Xác nhận tiền'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class _SimpleAdminForm extends StatefulWidget {
  const _SimpleAdminForm({required this.kind, this.existing});
  final int kind;
  final Map<String, dynamic>? existing;
  @override
  State<_SimpleAdminForm> createState() => _SimpleAdminFormState();
}

class _SimpleAdminFormState extends State<_SimpleAdminForm> {
  final a = TextEditingController(),
      b = TextEditingController(),
      c = TextEditingController(),
      d = TextEditingController(),
      e = TextEditingController();
  String type = 'STORE', discount = 'PERCENT';

  void _invalid(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();
    final row = widget.existing;
    if (row == null) return;
    if (widget.kind == 0) {
      a.text = row['categoryName'] as String? ?? '';
      b.text = row['description'] as String? ?? '';
      c.text = '${row['sortOrder'] ?? 0}';
    } else if (widget.kind == 1) {
      a.text = row['code'] as String? ?? '';
      b.text = row['promotionName'] as String? ?? '';
      c.text = '${row['discountValue'] ?? ''}';
      d.text = '${row['minOrderAmount'] ?? 0}';
      discount = row['discountType'] as String? ?? 'PERCENT';
    } else {
      a.text = row['storeName'] as String? ?? '';
      b.text = row['address'] as String? ?? '';
      c.text = '${row['latitude'] ?? ''}';
      d.text = '${row['longitude'] ?? ''}';
      e.text = row['phoneNumber'] as String? ?? '';
      type = row['storeType'] as String? ?? 'STORE';
    }
  }

  @override
  void dispose() {
    a.dispose();
    b.dispose();
    c.dispose();
    d.dispose();
    e.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? ['Danh mục mới', 'Khuyến mãi mới', 'Cửa hàng / kho mới'][kind]
            : ['Sửa danh mục', 'Sửa khuyến mãi', 'Sửa cửa hàng / kho'][kind],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: kind == 0
              ? [
                  TextField(
                    controller: a,
                    decoration: const InputDecoration(
                      labelText: 'Tên danh mục',
                    ),
                  ),
                  TextField(
                    controller: b,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Thứ tự'),
                  ),
                ]
              : kind == 1
              ? [
                  TextField(
                    controller: a,
                    decoration: const InputDecoration(labelText: 'Mã'),
                  ),
                  TextField(
                    controller: b,
                    decoration: const InputDecoration(labelText: 'Tên'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: discount,
                    items: const ['PERCENT', 'FIXED']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              v == 'PERCENT'
                                  ? 'Theo phần trăm'
                                  : 'Số tiền cố định',
                            ),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Hình thức giảm',
                    ),
                    onChanged: (v) => setState(() => discount = v ?? 'PERCENT'),
                  ),
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị giảm',
                    ),
                  ),
                  TextField(
                    controller: d,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đơn tối thiểu',
                    ),
                  ),
                ]
              : [
                  TextField(
                    controller: a,
                    decoration: const InputDecoration(labelText: 'Tên'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    items: const ['STORE', 'WAREHOUSE']
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v == 'STORE' ? 'Cửa hàng' : 'Kho hàng'),
                          ),
                        )
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Loại điểm bán',
                    ),
                    onChanged: (v) => setState(() => type = v ?? 'STORE'),
                  ),
                  TextField(
                    controller: b,
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  ),
                  TextField(
                    controller: c,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Vĩ độ'),
                  ),
                  TextField(
                    controller: d,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Kinh độ'),
                  ),
                  TextField(
                    controller: e,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại (không bắt buộc)',
                    ),
                  ),
                ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final now = DateTime.now().toUtc();
            Map<String, dynamic> request;
            if (kind == 0) {
              if (a.text.trim().length < 2) {
                _invalid('Tên danh mục cần ít nhất 2 ký tự.');
                return;
              }
              request = {
                'categoryName': a.text.trim(),
                'description': b.text.trim(),
                'imageUrl': widget.existing?['imageUrl'],
                'sortOrder': int.tryParse(c.text) ?? 0,
              };
            } else if (kind == 1) {
              final val = double.tryParse(c.text);
              if (a.text.trim().length < 3 ||
                  b.text.trim().length < 2 ||
                  val == null ||
                  val <= 0 ||
                  (discount == 'PERCENT' && val > 100)) {
                _invalid('Kiểm tra mã, tên và giá trị giảm giá.');
                return;
              }
              request = {
                'code': a.text.trim(),
                'promotionName': b.text.trim(),
                'discountType': discount,
                'discountValue': val,
                'minOrderAmount': double.tryParse(d.text) ?? 0,
                'maxDiscountAmount': widget.existing?['maxDiscountAmount'],
                'usageLimit': widget.existing?['usageLimit'],
                'description': widget.existing?['description'],
                'startAt': widget.existing?['startAt'] ?? now.toIso8601String(),
                'endAt':
                    widget.existing?['endAt'] ??
                    now.add(const Duration(days: 30)).toIso8601String(),
              };
            } else {
              final lat = double.tryParse(c.text),
                  lon = double.tryParse(d.text);
              if (a.text.trim().length < 2 ||
                  b.text.trim().length < 5 ||
                  lat == null ||
                  lon == null ||
                  lat < -90 ||
                  lat > 90 ||
                  lon < -180 ||
                  lon > 180) {
                _invalid('Nhập tên, địa chỉ và tọa độ hợp lệ.');
                return;
              }
              request = {
                'storeName': a.text.trim(),
                'storeType': type,
                'address': b.text.trim(),
                'latitude': lat,
                'longitude': lon,
                'phoneNumber': e.text.trim().isEmpty ? null : e.text.trim(),
              };
            }
            Navigator.pop(context, request);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

String _error(Object error) => error is ApiException
    ? error.userMessage
    : 'Không thể tải dữ liệu. Vui lòng thử lại.';

class _AdminSignOutAction extends StatelessWidget {
  const _AdminSignOutAction();
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Đăng xuất',
    onPressed: () => context.read<AuthViewModel>().signOut(),
    icon: const Icon(Icons.logout),
  );
}

class _BroadcastForm extends StatefulWidget {
  const _BroadcastForm();
  @override
  State<_BroadcastForm> createState() => _BroadcastFormState();
}

class _BroadcastFormState extends State<_BroadcastForm> {
  final title = TextEditingController();
  final message = TextEditingController();
  @override
  void dispose() {
    title.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Gửi thông báo khách hàng'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: title,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          TextField(
            controller: message,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Nội dung'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (title.text.trim().isEmpty || message.text.trim().isEmpty) return;
          Navigator.pop(context, {
            'title': title.text.trim(),
            'message': message.text.trim(),
            'notificationType': 'PROMOTION',
          });
        },
        child: const Text('Gửi'),
      ),
    ],
  );
}
