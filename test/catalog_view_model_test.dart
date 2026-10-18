import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/data/repositories/catalog_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/category.dart';
import 'package:pawmart/domain/models/paged_result.dart';
import 'package:pawmart/domain/models/product.dart';
import 'package:pawmart/ui/features/catalog/view_models/catalog_view_model.dart';

class _ControlledCatalogRepository extends CatalogRepository {
  _ControlledCatalogRepository()
    : super(ApiClient(baseUrl: 'http://localhost', tokenStore: TokenStore()));

  final requests = <String, Completer<PagedResult<Product>>>{};

  @override
  Future<List<Category>> categories() async => const [];

  @override
  Future<PagedResult<Product>> search({
    String? search,
    int? categoryId,
    String? petType,
    String sort = 'newest',
    int page = 1,
    int pageSize = 20,
  }) => (requests[search ?? ''] ??= Completer<PagedResult<Product>>()).future;

  void complete(String search, Product product) {
    requests[search]!.complete(
      PagedResult(items: [product], page: 1, pageSize: 20, totalItems: 1),
    );
  }
}

Product _product(int id) => Product(
  productId: id,
  categoryId: 1,
  productName: 'Sản phẩm $id',
  price: 1000,
  stockQuantity: 5,
  lowStockThreshold: 2,
  targetPetType: 'ALL',
  isFeatured: false,
  isActive: true,
  images: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Kết quả tìm kiếm cũ không ghi đè bộ lọc mới', () async {
    final repository = _ControlledCatalogRepository();
    final model = CatalogViewModel(repository);

    final initial = model.load();
    await Future<void>.delayed(Duration.zero);
    repository.complete('', _product(1));
    await initial;

    final oldRequest = model.setSearch('cũ');
    final newRequest = model.setSearch('mới');
    await Future<void>.delayed(Duration.zero);
    repository.complete('mới', _product(3));
    await newRequest;
    repository.complete('cũ', _product(2));
    await oldRequest;

    expect(model.search, 'mới');
    expect(model.products.single.productId, 3);
    expect(model.isLoading, isFalse);
  });
}
