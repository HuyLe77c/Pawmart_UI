import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/chat_reply.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';

class ChatProductLinks extends StatelessWidget {
  const ChatProductLinks({super.key, required this.products});

  final List<ChatProductLink> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            'Xem sản phẩm tại cửa hàng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        for (final product in products) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: const CircleAvatar(
                backgroundColor: PawmartColors.greenPale,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: PawmartColors.green,
                ),
              ),
              title: Text(
                product.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                formatVnd(product.price),
                style: const TextStyle(
                  color: PawmartColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/products/${product.productId}'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
