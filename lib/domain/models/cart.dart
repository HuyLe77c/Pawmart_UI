class CartLine {
  const CartLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.availableStock,
    this.imageUrl,
  });

  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final int availableStock;
  final String? imageUrl;

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    productId: json['productId'] as int,
    productName: json['productName'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    quantity: json['quantity'] as int,
    lineTotal: (json['lineTotal'] as num).toDouble(),
    availableStock: json['availableStock'] as int,
    imageUrl: json['imageUrl'] as String?,
  );
}

class Cart {
  const Cart({
    required this.items,
    required this.subtotal,
    required this.totalQuantity,
  });

  final List<CartLine> items;
  final double subtotal;
  final int totalQuantity;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CartLine.fromJson)
        .toList(growable: false),
    subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
    totalQuantity: json['totalQuantity'] as int? ?? 0,
  );
}
