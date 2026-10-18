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
  bool isLoading = false;
  bool isCancelling = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      order = await _repository.detail(orderId);
    } on ApiException catch (error) {
      errorMessage = error.userMessage;
    } catch (_) {
      errorMessage = 'Không tải được thông tin đơn hàng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
}
