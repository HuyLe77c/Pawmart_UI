class PaymentMethods {
  const PaymentMethods({
    required this.codAvailable,
    required this.bankQrAvailable,
  });
  final bool codAvailable;
  final bool bankQrAvailable;

  factory PaymentMethods.fromJson(Map<String, dynamic> json) => PaymentMethods(
    codAvailable: json['codAvailable'] as bool? ?? true,
    bankQrAvailable: json['bankQrAvailable'] as bool? ?? false,
  );
}

class BankQrInstructions {
  const BankQrInstructions({
    required this.orderId,
    required this.amount,
    required this.bankName,
    required this.bankAccountNo,
    required this.bankAccountName,
    required this.transferContent,
    required this.qrImageUrl,
    required this.paymentStatus,
    required this.orderStatus,
    this.receivedAmount = 0,
  });

  final String orderId;
  final double amount;
  final String bankName;
  final String bankAccountNo;
  final String bankAccountName;
  final String transferContent;
  final String qrImageUrl;
  final String paymentStatus;
  final String orderStatus;
  final double receivedAmount;

  factory BankQrInstructions.fromJson(Map<String, dynamic> json) =>
      BankQrInstructions(
        orderId: json['orderId'] as String,
        amount: (json['amount'] as num).toDouble(),
        bankName: json['bankName'] as String,
        bankAccountNo: json['bankAccountNo'] as String,
        bankAccountName: json['bankAccountName'] as String,
        transferContent: json['transferContent'] as String,
        qrImageUrl: json['qrImageUrl'] as String,
        paymentStatus: json['paymentStatus'] as String,
        orderStatus: json['orderStatus'] as String,
        receivedAmount: (json['receivedAmount'] as num?)?.toDouble() ?? 0,
      );
}

class CheckoutQuote {
  const CheckoutQuote({
    required this.subtotal,
    required this.discount,
    required this.shippingFee,
    required this.total,
    required this.fingerprint,
    required this.items,
    this.promotionCode,
  });

  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String fingerprint;
  final String? promotionCode;
  final List<OrderLine> items;

  factory CheckoutQuote.fromJson(Map<String, dynamic> json) => CheckoutQuote(
    subtotal: (json['subtotal'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    shippingFee: (json['shippingFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    fingerprint: json['fingerprint'] as String,
    promotionCode: json['promotionCode'] as String?,
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(OrderLine.fromJson)
        .toList(growable: false),
  );
}

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
    this.reviewRating,
  });

  final String orderId;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final int? reviewRating;

  factory OrderListItem.fromJson(Map<String, dynamic> json) => OrderListItem(
    orderId: json['orderId'] as String,
    total: (json['total'] as num).toDouble(),
    paymentMethod: json['paymentMethod'] as String,
    paymentStatus: json['paymentStatus'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    reviewRating: json['reviewRating'] as int?,
  );
}

class OrderReview {
  const OrderReview({
    required this.reviewId,
    required this.orderId,
    required this.authorName,
    required this.rating,
    required this.sharePublicly,
    required this.isVisible,
    required this.createdAt,
    this.comment,
    this.shopReply,
    this.repliedAt,
  });

  final int reviewId;
  final String orderId;
  final String authorName;
  final int rating;
  final String? comment;
  final bool sharePublicly;
  final bool isVisible;
  final String? shopReply;
  final DateTime createdAt;
  final DateTime? repliedAt;

  factory OrderReview.fromJson(Map<String, dynamic> json) => OrderReview(
    reviewId: json['reviewId'] as int,
    orderId: json['orderId'] as String,
    authorName: json['authorName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    sharePublicly: json['sharePublicly'] as bool? ?? false,
    isVisible: json['isVisible'] as bool? ?? true,
    shopReply: json['shopReply'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    repliedAt: json['repliedAt'] == null
        ? null
        : DateTime.parse(json['repliedAt'] as String),
  );
}

class PublicOrderReview {
  const PublicOrderReview({
    required this.authorName,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.shopReply,
  });
  final String authorName;
  final int rating;
  final DateTime createdAt;
  final String? comment;
  final String? shopReply;

  factory PublicOrderReview.fromJson(Map<String, dynamic> json) =>
      PublicOrderReview(
        authorName: json['authorName'] as String,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        shopReply: json['shopReply'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PublicOrderReviews {
  const PublicOrderReviews({
    required this.total,
    required this.averageRating,
    required this.items,
  });
  final int total;
  final double averageRating;
  final List<PublicOrderReview> items;

  factory PublicOrderReviews.fromJson(Map<String, dynamic> json) =>
      PublicOrderReviews(
        total: json['total'] as int,
        averageRating: (json['averageRating'] as num).toDouble(),
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PublicOrderReview.fromJson)
            .toList(growable: false),
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
    this.review,
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
  final OrderReview? review;

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
    review: json['review'] is Map<String, dynamic>
        ? OrderReview.fromJson(json['review'] as Map<String, dynamic>)
        : null,
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
