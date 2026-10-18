import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/paged_result.dart';
import '../../../../domain/models/product.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this._repository);
  final CatalogRepository _repository;

  List<Product> products = const [];
  List<Category> categories = const [];
  String search = '';
  String petType = 'ALL';
  String sort = 'newest';
  int? categoryId;
  int totalItems = 0;
  int _page = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  bool _loadedCategories = false;
  int _requestRevision = 0;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && (isLoading || isLoadingMore)) return;
    final revision = ++_requestRevision;
    isLoading = true;
    errorMessage = null;
    if (refresh) {
      products = const [];
      _page = 0;
      totalItems = 0;
      isLoadingMore = false;
    }
    notifyListeners();
    try {
      if (!_loadedCategories) {
        final fetchedCategories = await _repository.categories();
        if (revision != _requestRevision) return;
        categories = fetchedCategories;
        _loadedCategories = true;
      }
      final result = await _repository.search(
        search: search,
        categoryId: categoryId,
        petType: petType,
        sort: sort,
        page: 1,
      );
      if (revision == _requestRevision) _applyFirstPage(result);
    } on ApiException catch (error) {
      if (revision == _requestRevision) errorMessage = error.userMessage;
    } catch (_) {
      if (revision == _requestRevision) {
        errorMessage = 'Không tải được danh mục. Vui lòng thử lại.';
      }
    } finally {
      if (revision == _requestRevision) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || products.length >= totalItems) return;
    final revision = _requestRevision;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _repository.search(
        search: search,
        categoryId: categoryId,
        petType: petType,
        sort: sort,
        page: _page + 1,
      );
      if (revision == _requestRevision) {
        products = [...products, ...result.items];
        _page = result.page;
        totalItems = result.totalItems;
      }
    } on ApiException catch (error) {
      if (revision == _requestRevision) errorMessage = error.userMessage;
    } catch (_) {
      if (revision == _requestRevision) {
        errorMessage = 'Không tải thêm được sản phẩm.';
      }
    } finally {
      if (revision == _requestRevision) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> setSearch(String value) async {
    search = value;
    await load(refresh: true);
  }

  Future<void> setPetType(String value) async {
    petType = value;
    await load(refresh: true);
  }

  Future<void> setCategory(int? value) async {
    categoryId = value;
    await load(refresh: true);
  }

  Future<void> setSort(String value) async {
    sort = value;
    await load(refresh: true);
  }

  void _applyFirstPage(PagedResult<Product> result) {
    products = result.items;
    totalItems = result.totalItems;
    _page = result.page;
  }
}
