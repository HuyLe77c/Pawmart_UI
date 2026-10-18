import '../../domain/models/order.dart';
import '../../domain/models/paged_result.dart';
import '../services/api_client.dart';

class OrdersRepository {
  const OrdersRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<PagedResult<OrderListItem>> list({
    String? status,
    int page = 1,
  }) async {
    final json = await _apiClient.getJson(
      'api/orders',
      query: {
        'page': '$page',
        'pageSize': '20',
        if (status != null && status != 'ALL') 'status': status,
      },
    ) as Map<String, dynamic>;
    return PagedResult(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OrderListItem.fromJson)
          .toList(growable: false),
      page: json['page'] as int? ?? page,
      pageSize: json['pageSize'] as int? ?? 20,
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }

  Future<OrderDetail> detail(String orderId) async => OrderDetail.fromJson(
    await _apiClient.getJson('api/orders/$orderId') as Map<String, dynamic>,
  );

  Future<OrderSummary> checkout({
    required String recipientName,
    required String recipientPhone,
    required String shippingAddress,
    double? latitude,
    double? longitude,
    String paymentMethod = 'COD',
    String? promotionCode,
    String? note,
  }) async => OrderSummary.fromJson(
    await _apiClient.postJson('api/cart/checkout', {
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'shippingAddress': shippingAddress,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'paymentMethod': paymentMethod,
      if (promotionCode?.isNotEmpty ?? false) 'promotionCode': promotionCode,
      if (note?.isNotEmpty ?? false) 'note': note,
    }) as Map<String, dynamic>,
  );

  Future<void> cancel(String orderId) async =>
      _apiClient.postJson('api/orders/$orderId/cancel');
}
