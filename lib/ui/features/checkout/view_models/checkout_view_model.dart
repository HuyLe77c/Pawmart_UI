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
  CheckoutQuote? quote;
  bool isLoadingQuote = false;
  String? quoteError;
  int _quoteVersion = 0;

  void invalidateQuote() {
    _quoteVersion++;
    quote = null;
    quoteError = null;
    isLoadingQuote = false;
    notifyListeners();
  }

  Future<void> loadQuote({String? promotionCode}) async {
    final version = ++_quoteVersion;
    quote = null;
    quoteError = null;
    isLoadingQuote = true;
    notifyListeners();
    try {
      final result = await _repository.checkoutQuote(
        promotionCode: promotionCode,
      );
      if (version == _quoteVersion) quote = result;
    } on ApiException catch (error) {
      if (version == _quoteVersion) quoteError = _checkoutMessage(error);
    } catch (_) {
      if (version == _quoteVersion)
        quoteError = 'Không lấy được tổng tiền. Hãy thử lại.';
    } finally {
      if (version == _quoteVersion) {
        isLoadingQuote = false;
        notifyListeners();
      }
    }
  }

  Future<OrderSummary?> submit({
    required String recipientName,
    required String recipientPhone,
    required String address,
    double? latitude,
    double? longitude,
    String? promotionCode,
    String? note,
  }) async {
    final reviewedQuote = quote;
    if (reviewedQuote == null) {
      errorMessage = 'Hãy cập nhật và xem lại tổng tiền trước khi đặt hàng.';
      notifyListeners();
      return null;
    }
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
        expectedQuoteFingerprint: reviewedQuote.fingerprint,
        note: note,
      );
      return createdOrder;
    } on ApiException catch (error) {
      errorMessage = _checkoutMessage(error);
      if (error.statusCode == 409) {
        await loadQuote(promotionCode: promotionCode);
        errorMessage = quote == null ? quoteError : 'Giỏ hàng, giá hoặc ưu đãi đã thay đổi. Vui lòng xem lại tổng tiền mới trước khi đặt.';
      }
    } catch (_) {
      errorMessage =
          'Không thể tạo đơn hàng. Hãy kiểm tra lại giỏ hàng và thử lại.';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
    return null;
  }

  String _checkoutMessage(ApiException error) => switch (error.title) {
    'Empty cart' => 'Giỏ hàng đang trống. Hãy chọn sản phẩm trước khi đặt.',
    'Product unavailable' =>
      'Có sản phẩm không còn bán. Hãy kiểm tra giỏ hàng.',
    'Insufficient stock' =>
      'Số lượng tồn kho đã thay đổi. Hãy kiểm tra giỏ hàng.',
    'Promotion unavailable' => 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn.',
    'Checkout quote changed' =>
      'Tổng tiền đã thay đổi. Hãy xem lại trước khi đặt.',
    'Order total too large' => 'Tổng tiền vượt mức hỗ trợ. Hãy giảm số lượng.',
    _ => error.userMessage,
  };
}
