import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/product.dart';
import '../../../../domain/models/promotion.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository);
  final CatalogRepository _repository;

  List<Category> categories = const [];
  List<Product> featured = const [];
  List<Product> products = const [];
  List<Promotion> promotions = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      categories = await _repository.categories();
      final result = await _repository.search(pageSize: 20);
      products = result.items;
      final featuredItems = result.items
          .where((product) => product.isFeatured)
          .toList(growable: false);
      featured = featuredItems.isEmpty ? result.items : featuredItems;
      promotions = await _repository.activePromotions();
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được trang chủ. Vui lòng thử lại.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
