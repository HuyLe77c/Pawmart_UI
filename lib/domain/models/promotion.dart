class Promotion {
  const Promotion({
    required this.promotionId,
    required this.code,
    required this.promotionName,
    required this.discountType,
    required this.discountValue,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    this.description,
    this.minOrderAmount = 0,
    this.maxDiscountAmount,
  });

  final int promotionId;
  final String code;
  final String promotionName;
  final String discountType;
  final double discountValue;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
  final String? description;
  final double minOrderAmount;
  final double? maxDiscountAmount;

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
    promotionId: json['promotionId'] as int,
    code: json['code'] as String,
    promotionName: json['promotionName'] as String,
    discountType: json['discountType'] as String,
    discountValue: (json['discountValue'] as num).toDouble(),
    startAt: DateTime.parse(json['startAt'] as String),
    endAt: DateTime.parse(json['endAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
    description: json['description'] as String?,
    minOrderAmount: (json['minOrderAmount'] as num? ?? 0).toDouble(),
    maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
  );
}
