import 'package:flutter/foundation.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel(this._repository);
  final OrdersRepository _repository;

  bool isSubmitting = false;
  String? errorMessage;
  OrderSummary? createdOrder;

  Future<OrderSummary?> submit({
    required String recipientName,
    required String recipientPhone,
    required String address,
    double? latitude,
    double? longitude,
    String? promotionCode,
    String? note,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      createdOrder = await _repository.checkout(
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        shippingAddress: address,
        latitude: latitude,
        longitude: longitude,
        paymentMethod: 'COD',
        promotionCode: promotionCode,
        note: note,
      );
      return createdOrder;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage =
          'Không thể tạo đơn hàng. Hãy kiểm tra lại giỏ hàng và thử lại.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
    return null;
  }
}
