import 'package:flutter/material.dart';

import '../../../domain/models/product.dart';
import '../app_theme.dart';
import '../formatters.dart';
import 'product_artwork.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.adding = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool adding;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ColoredBox(
                color: PawmartColors.cream,
                child: ProductArtwork(
                  imageUrl: product.primaryImageUrl,
                  height: 138,
                ),
              ),
              if (product.stockQuantity <= 0)
                const Positioned(
                  left: 8,
                  top: 8,
                  child: _ProductBadge(
                    text: 'Hết hàng',
                    color: PawmartColors.error,
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand ?? _petLabel(product.targetPetType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PawmartColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatVnd(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: PawmartColors.greenDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      IconButton.outlined(
                        tooltip: 'Thêm vào giỏ',
                        style: IconButton.styleFrom(
                          foregroundColor: PawmartColors.green,
                          side: const BorderSide(color: PawmartColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: product.stockQuantity > 0 && !adding
                            ? onAdd
                            : null,
                        icon: adding
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  static String _petLabel(String type) => switch (type.toUpperCase()) {
    'DOG' => 'Dành cho chó',
    'CAT' => 'Dành cho mèo',
    _ => 'Thú cưng',
  };
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    ),
  );
}
