import 'package:flutter/foundation.dart';

import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/cart.dart';

class CartViewModel extends ChangeNotifier {
  CartViewModel(this._repository);
  final CartRepository _repository;

  Cart? cart;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.getCart();
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được giỏ hàng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(int productId, {int quantity = 1}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final currentCart = cart ?? await _repository.getCart();
      final existing = currentCart.items
          .where((line) => line.productId == productId)
          .firstOrNull;
      final nextQuantity = (existing?.quantity ?? 0) + quantity;
      cart = await _repository.setQuantity(
        productId: productId,
        quantity: nextQuantity,
      );
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không thêm được sản phẩm vào giỏ.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> setQuantity(int productId, int quantity) async {
    if (quantity < 1) return remove(productId);
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      cart = await _repository.setQuantity(
        productId: productId,
        quantity: quantity,
      );
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không cập nhật được số lượng.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> remove(int productId) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.remove(productId);
      cart = await _repository.getCart();
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không xóa được sản phẩm khỏi giỏ.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
