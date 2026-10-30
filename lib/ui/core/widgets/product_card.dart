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
    this.categoryName,
    this.adding = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final String? categoryName;
  final bool adding;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 128,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFFF2F5F0),
                  child: ProductArtwork(
                    imageUrl: product.primaryImageUrl,
                    height: 128,
                  ),
                ),
                if (product.stockQuantity <= 0)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: _ProductBadge(
                      text: 'Hết hàng',
                      color: PawmartColors.ink,
                    ),
                  )
                else if (product.isFeatured)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: _ProductBadge(
                      text: 'Nổi bật',
                      color: PawmartColors.amber,
                    ),
                  ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton.filled(
                    tooltip: 'Thêm vào giỏ',
                    style: IconButton.styleFrom(
                      backgroundColor: PawmartColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: product.stockQuantity > 0 && !adding
                        ? onAdd
                        : null,
                    icon: adding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_shopping_cart_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand ??
                        categoryName ??
                        _petLabel(product.targetPetType),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: PawmartColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      color: PawmartColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatVnd(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: PawmartColors.greenDark,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
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
      borderRadius: BorderRadius.circular(9),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
