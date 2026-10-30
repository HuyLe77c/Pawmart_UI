class OrderSummary {
  const OrderSummary({
    required this.orderId,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  final String orderId;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final List<OrderLine> items;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
    orderId: json['orderId'] as String,
    subtotal: (json['subtotal'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    shippingFee: (json['shippingFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    paymentMethod: json['paymentMethod'] as String,
    paymentStatus: json['paymentStatus'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderLine.fromJson)
        .toList(growable: false),
  );
}

class OrderListItem {
  const OrderListItem({
    required this.orderId,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
  });

  final String orderId;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;

  factory OrderListItem.fromJson(Map<String, dynamic> json) => OrderListItem(
    orderId: json['orderId'] as String,
    total: (json['total'] as num).toDouble(),
    paymentMethod: json['paymentMethod'] as String,
    paymentStatus: json['paymentStatus'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    productId: json['productId'] as int,
    productName: json['productName'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    lineTotal: (json['lineTotal'] as num).toDouble(),
  );
}

class OrderStatusHistory {
  const OrderStatusHistory({
    required this.status,
    required this.createdAt,
    this.note,
  });
  final String status;
  final DateTime createdAt;
  final String? note;

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistory(
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        note: json['note'] as String?,
      );
}

class OrderDetail {
  const OrderDetail({
    required this.orderId,
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
    required this.shippingAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    required this.items,
    required this.history,
    this.latitude,
    this.longitude,
    this.note,
  });

  final String orderId;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String shippingAddress;
  final String recipientName;
  final String recipientPhone;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final List<OrderLine> items;
  final List<OrderStatusHistory> history;
  final double? latitude;
  final double? longitude;
  final String? note;

  factory OrderDetail.fromJson(Map<String, dynamic> json) => OrderDetail(
    orderId: json['orderId'] as String,
    subtotal: (json['subtotal'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    shippingFee: (json['shippingFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    shippingAddress: json['shippingAddress'] as String,
    recipientName: json['recipientName'] as String,
    recipientPhone: json['recipientPhone'] as String,
    paymentMethod: json['paymentMethod'] as String,
    paymentStatus: json['paymentStatus'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderLine.fromJson)
        .toList(growable: false),
    history: (json['history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderStatusHistory.fromJson)
        .toList(growable: false),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    note: json['note'] as String?,
  );
}

class RecommendedProduct {
  const RecommendedProduct({
    required this.productId,
    required this.productName,
    required this.price,
    required this.targetPetType,
  });
  final int productId;
  final String productName;
  final double price;
  final String targetPetType;

  factory RecommendedProduct.fromJson(Map<String, dynamic> json) =>
      RecommendedProduct(
        productId: json['productId'] as int,
        productName: json['productName'] as String,
        price: (json['price'] as num).toDouble(),
        targetPetType: json['targetPetType'] as String,
      );
}

class RecommendationResult {
  const RecommendationResult({
    required this.advice,
    required this.products,
    this.sources = const [],
  });
  final String advice;
  final List<RecommendedProduct> products;
  final List<NutritionSource> sources;

  factory RecommendationResult.fromJson(Map<String, dynamic> json) =>
      RecommendationResult(
        advice: json['advice'] as String,
        products: (json['products'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(RecommendedProduct.fromJson)
            .toList(growable: false),
        sources: (json['sources'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(NutritionSource.fromJson)
            .toList(growable: false),
      );
}

class NutritionSource {
  const NutritionSource({required this.title, required this.url});
  final String title;
  final String url;

  factory NutritionSource.fromJson(Map<String, dynamic> json) =>
      NutritionSource(
        title: json['title'] as String,
        url: json['url'] as String,
      );
}
