import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/paged_result.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/catalog_filters.dart';

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this._repository);
  final CatalogRepository _repository;
  static const int pageSize = 12;

  List<Product> products = const [];
  List<Category> categories = const [];
  String search = '';
  String petType = 'ALL';
  String sort = 'recommended';
  int? categoryId;
  String? breed;
  String? brand;
  int? minPrice;
  int? maxPrice;
  bool inStockOnly = false;

  CatalogFilters get filters => CatalogFilters(
    petType: petType,
    categoryId: categoryId,
    breed: breed,
    brand: brand,
    minPrice: minPrice,
    maxPrice: maxPrice,
    inStockOnly: inStockOnly,
  );

  Future<void> applyFilters(CatalogFilters value) async {
    petType = value.petType;
    categoryId = value.categoryId;
    breed = value.breed;
    brand = value.brand;
    minPrice = value.minPrice;
    maxPrice = value.maxPrice;
    inStockOnly = value.inStockOnly;
    await load(refresh: true);
  }

  Future<void> clearFilters() => applyFilters(const CatalogFilters());
  int totalItems = 0;
  int currentPage = 1;
  int get totalPages => (totalItems + pageSize - 1) ~/ pageSize;
  bool isLoading = false;
  String? errorMessage;
  bool _loadedCategories = false;
  int _requestRevision = 0;

  Future<void> load({bool refresh = false}) async {
    if (!refresh && isLoading) return;
    final revision = ++_requestRevision;
    isLoading = true;
    errorMessage = null;
    if (refresh) {
      products = const [];
      currentPage = 1;
      totalItems = 0;
    }
    notifyListeners();
    try {
      if (!_loadedCategories) {
        final fetchedCategories = await _repository.categories();
        if (revision != _requestRevision) return;
        categories = fetchedCategories;
        _loadedCategories = true;
      }
      var result = await _searchPage(currentPage);
      if (revision != _requestRevision) return;
      // Stock/catalog changes may remove the page the customer was viewing.
      final lastPage = result.totalItems == 0
          ? 1
          : (result.totalItems + pageSize - 1) ~/ pageSize;
      if (result.page > lastPage) {
        currentPage = lastPage;
        if (result.totalItems == 0) {
          result = PagedResult<Product>(
            items: const [],
            page: 1,
            pageSize: pageSize,
            totalItems: 0,
          );
        } else {
          result = await _searchPage(lastPage);
        }
      }
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

  Future<PagedResult<Product>> _searchPage(int page) => _repository.search(
    search: search,
    categoryId: categoryId,
    petType: petType,
    breed: breed,
    brand: brand,
    minPrice: minPrice,
    maxPrice: maxPrice,
    inStockOnly: inStockOnly,
    sort: sort,
    page: page,
    pageSize: pageSize,
  );

  Future<void> goToPage(int page) async {
    if (isLoading || page == currentPage || page < 1 || page > totalPages) {
      return;
    }
    currentPage = page;
    products = const [];
    await load();
  }

  Future<void> setSearch(String value) async {
    search = value;
    await load(refresh: true);
  }

  Future<void> setPetType(String value) async {
    if (petType != value) breed = null;
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
    currentPage = result.page;
  }
}
