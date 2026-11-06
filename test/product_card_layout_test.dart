import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/domain/models/product.dart';
import 'package:pawmart/ui/core/app_theme.dart';
import 'package:pawmart/ui/core/widgets/product_card.dart';

void main() {
  testWidgets('Thẻ sản phẩm không tràn ở ô lưới nhỏ', (tester) async {
    const product = Product(
      productId: 1,
      categoryId: 1,
      productName: 'Thức ăn cho mèo trưởng thành vị cá hồi và rau củ',
      price: 279000,
      stockQuantity: 12,
      lowStockThreshold: 5,
      targetPetType: 'CAT',
      isFeatured: true,
      isActive: true,
      images: [],
      brand: 'PawMart Nutrition',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PawmartTheme.light,
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: SizedBox(
                width: 148,
                height: 258,
                child: ProductCard(
                  product: product,
                  onTap: () {},
                  onAdd: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('279.000'), findsOneWidget);
  });

  testWidgets('Bản xem trước không hiện giá 0 hoặc nút mua', (tester) async {
    const product = Product(
      productId: 12,
      categoryId: 8,
      productName: 'KONG Classic – Đồ chơi cao su nhét bánh thưởng cho chó',
      price: 0,
      stockQuantity: 0,
      lowStockThreshold: 5,
      targetPetType: 'DOG',
      isFeatured: false,
      isActive: false,
      images: [],
      brand: 'KONG',
      catalogReview: CatalogReviewSummary(
        modelStatus: 'VERIFIED',
        imageStatus: 'NEEDS_REVIEW',
        priceStatus: 'NEEDS_REVIEW',
        productStatus: 'NEEDS_REVIEW',
        publicPreview: true,
        officialUrl: 'https://www.kongcompany.com/kong-classic/',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PawmartTheme.light,
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: SizedBox(
                width: 148,
                height: 258,
                child: ProductCard(
                  product: product,
                  onTap: () {},
                  onAdd: () => fail('Preview cannot be added to cart'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Giá chưa công bố'), findsOneWidget);
    expect(find.text('Sắp mở bán'), findsOneWidget);
    expect(find.textContaining('0 đ'), findsNothing);
    expect(find.byIcon(Icons.add_shopping_cart_rounded), findsNothing);
  });

  testWidgets('Sản phẩm PawMart duyệt bán hiện giá và nút mua', (tester) async {
    var added = false;
    const product = Product(
      productId: 41,
      categoryId: 8,
      productName: 'KONG Classic',
      price: 189000,
      stockQuantity: 120,
      lowStockThreshold: 5,
      targetPetType: 'DOG',
      isFeatured: false,
      isActive: true,
      images: [],
      catalogReview: CatalogReviewSummary(
        modelStatus: 'NEEDS_REVIEW',
        imageStatus: 'VERIFIED',
        priceStatus: 'OWNER_SET',
        productStatus: 'OWNER_APPROVED',
        publicPreview: false,
        officialUrl: '',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PawmartTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 280,
              child: ProductCard(
                product: product,
                onTap: () {},
                onAdd: () => added = true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(product.canPurchase, isTrue);
    expect(find.textContaining('189.000'), findsOneWidget);
    expect(find.text('Sắp mở bán'), findsNothing);
    await tester.tap(find.byIcon(Icons.add_shopping_cart_rounded));
    expect(added, isTrue);
  });
}
