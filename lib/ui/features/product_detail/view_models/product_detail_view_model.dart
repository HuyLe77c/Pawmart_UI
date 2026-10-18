import 'package:flutter/foundation.dart';

import '../../../../data/repositories/catalog_repository.dart';
import '../../../../data/repositories/pets_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/pet_profile.dart';
import '../../../../domain/models/product.dart';

class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel(
    this._catalogRepository,
    this._petsRepository,
    this._signedIn,
  );

  final CatalogRepository _catalogRepository;
  final PetsRepository _petsRepository;
  final bool _signedIn;

  Product? product;
  List<PetProfile> pets = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load(int productId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      product = await _catalogRepository.getProduct(productId);
      if (_signedIn) {
        try {
          pets = await _petsRepository.list();
        } on ApiException {
          pets = const [];
        }
      }
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được thông tin sản phẩm.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
