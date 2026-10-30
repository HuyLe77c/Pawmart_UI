class ChatProductLink {
  const ChatProductLink({
    required this.productId,
    required this.productName,
    required this.price,
  });

  final int productId;
  final String productName;
  final double price;

  factory ChatProductLink.fromJson(Map<String, dynamic> json) =>
      ChatProductLink(
        productId: json['productId'] as int,
        productName: json['productName'] as String,
        price: (json['price'] as num).toDouble(),
      );
}

class ChatReply {
  const ChatReply({required this.answer, this.products = const []});

  final String answer;
  final List<ChatProductLink> products;

  factory ChatReply.fromJson(Map<String, dynamic> json) => ChatReply(
    answer: json['answer'] as String,
    products: (json['products'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ChatProductLink.fromJson)
        .toList(growable: false),
  );
}
