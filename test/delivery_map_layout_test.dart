import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawmart/ui/features/maps/address_search_service.dart';
import 'package:pawmart/ui/features/maps/delivery_address_map_screen.dart';

void main() {
  testWidgets('Màn chọn địa chỉ vừa khung Android hẹp khi mở bàn phím', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DeliveryAddressMapScreen()),
    );
    await tester.pump();
    expect(find.text('Dùng địa chỉ này'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Địa điểm lân cận hiện thành nhiều ghim và danh sách', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = AddressSearchService(
      client: MockClient((request) async {
        final features = request.url.path == '/reverse'
            ? [
                {
                  'geometry': {
                    'coordinates': [106.777363, 10.8483153],
                  },
                  'properties': {'name': 'Tân Lập 1'},
                },
              ]
            : List.generate(
                12,
                (index) => {
                  'geometry': {
                    'coordinates': [106.777363 + index * 0.0001, 10.8483153],
                  },
                  'properties': {'name': 'Hẻm ${index + 1} Tân Lập 1'},
                },
              );
        return http.Response(
          jsonEncode({'features': features}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    addTearDown(service.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DeliveryAddressMapScreen(searchService: service)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('12 gợi ý quanh đây'), findsOneWidget);

    await tester.tap(find.text('12 gợi ý quanh đây'));
    await tester.pump();
    expect(find.text('12 vị trí phù hợp'), findsOneWidget);
    await tester.tap(find.text('Bản đồ'));
    await tester.pump();
    expect(find.text('Danh sách'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
