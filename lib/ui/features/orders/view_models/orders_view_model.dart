import 'package:flutter/foundation.dart';

import '../../../../data/repositories/orders_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../domain/models/order.dart';

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel(this._repository);
  final OrdersRepository _repository;

  List<OrderListItem> orders = const [];
  bool isLoading = false;
  String? errorMessage;
  String filter = 'ALL';

  Future<void> load({String? status}) async {
    if (status != null) filter = status;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final page = await _repository.list(status: filter);
      orders = page.items;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được đơn hàng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class OrderDetailViewModel extends ChangeNotifier {
  OrderDetailViewModel(this._repository, this.orderId);
  final OrdersRepository _repository;
  final String orderId;

  OrderDetail? order;
  BankQrInstructions? bankQr;
  String? bankQrError;
  bool isLoading = false;
  bool isCancelling = false;
  bool isSubmittingReview = false;
  String? errorMessage;
  bool _isRefreshingPayment = false;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      order = await _repository.detail(orderId);
      bankQr = null;
      bankQrError = null;
      if (order!.paymentMethod == 'BANK_QR' && order!.status != 'CANCELLED') {
        try {
          bankQr = await _repository.bankQr(orderId);
        } on ApiException catch (error) {
          bankQrError = error.userMessage;
        } catch (_) {
          bankQrError = 'Không tải được mã QR. Kéo xuống để thử lại.';
        }
      }
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được thông tin đơn hàng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPaymentStatus() async {
    if (_isRefreshingPayment ||
        _disposed ||
        order?.paymentMethod != 'BANK_QR' ||
        order?.status == 'CANCELLED' ||
        order?.paymentStatus != 'PENDING') {
      return;
    }
    _isRefreshingPayment = true;
    try {
      final latest = await _repository.detail(orderId);
      if (_disposed) return;
      BankQrInstructions? latestQr;
      try {
        latestQr = await _repository.bankQr(orderId);
      } catch (_) {
        // The order detail remains the source of truth when QR refresh fails.
      }
      if (_disposed) return;
      order = latest;
      if (latestQr != null) bankQr = latestQr;
      notifyListeners();
    } catch (_) {
      // Keep the last known state; the next poll or pull-to-refresh can retry.
    } finally {
      _isRefreshingPayment = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<bool> cancel() async {
    isCancelling = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.cancel(orderId);
      await load();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không thể hủy đơn hàng.';
    } finally {
      isCancelling = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> submitReview({
    required int rating,
    required String comment,
    required bool sharePublicly,
  }) async {
    if (isSubmittingReview) return false;
    isSubmittingReview = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.submitReview(
        orderId,
        rating: rating,
        comment: comment.trim(),
        sharePublicly: sharePublicly,
      );
      await load();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không gửi được đánh giá. Vui lòng thử lại.';
    } finally {
      isSubmittingReview = false;
      notifyListeners();
    }
    return false;
  }
}
