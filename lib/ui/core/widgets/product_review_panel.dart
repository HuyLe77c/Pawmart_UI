import 'package:flutter/material.dart';

import '../../../domain/models/product.dart';
import '../app_theme.dart';

class ProductReviewPanel extends StatelessWidget {
  const ProductReviewPanel({
    super.key,
    required this.product,
    required this.height,
  });

  final Product product;
  final double height;

  @override
  Widget build(BuildContext context) {
    final brand = product.brand ?? 'PawMart';
    final fullModel = product.productName.split(' – ').first;
    final model = fullModel.startsWith(brand)
        ? fullModel.substring(brand.length).trim()
        : fullModel;
    final compact = height < 200;
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      color: const Color(0xFFE9F0E9),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            brand.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PawmartColors.greenDark,
              fontSize: compact ? 9 : 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            model.isEmpty ? fullModel : model,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PawmartColors.greenDark,
              fontSize: compact ? 14 : 24,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 4 : 7),
          Text(
            'Ảnh đang được xác minh',
            maxLines: compact ? 1 : 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: PawmartColors.muted,
              fontSize: compact ? 9 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
