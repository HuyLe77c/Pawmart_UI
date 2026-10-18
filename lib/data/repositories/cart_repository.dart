import '../../domain/models/cart.dart';
import '../services/api_client.dart';

class CartRepository {
  const CartRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<Cart> getCart() async => Cart.fromJson(
    await _apiClient.getJson('api/cart') as Map<String, dynamic>,
  );

  Future<Cart> setQuantity({
    required int productId,
    required int quantity,
  }) async => Cart.fromJson(
    await _apiClient.putJson('api/cart/items', {
      'productId': productId,
      'quantity': quantity,
    }) as Map<String, dynamic>,
  );

  Future<void> remove(int productId) async =>
      _apiClient.delete('api/cart/items/$productId');
}
