import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:pawmart/ui/features/maps/address_search_service.dart';

void main() {
  test('gợi ý lấy tọa độ thật từ kết quả và nhớ truy vấn', () async {
    var calls = 0;
    final service = AddressSearchService(
      client: MockClient((request) async {
        calls++;
        expect(request.url.queryParameters['q'], 'Tân Lập 1');
        expect(request.url.queryParameters['countrycode'], 'VN');
        expect(request.url.queryParameters['limit'], '15');
        expect(request.url.queryParameters['lat'], '10.8483');
        return http.Response(
          '''
          {"features":[{"geometry":{"coordinates":[106.777363,10.8483153]},
          "properties":{"name":"Tân Lập 1","district":"Tăng Nhơn Phú",
          "city":"Thành phố Hồ Chí Minh"}}]}
        ''',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final first = await service.suggest(
      'Tân Lập 1',
      near: const LatLng(10.8483, 106.7773),
    );
    final second = await service.suggest(
      'Tân Lập 1',
      near: const LatLng(10.8483, 106.7773),
    );

    expect(calls, 1);
    expect(second, same(first));
    expect(first.single.address, contains('Tăng Nhơn Phú'));
    expect(first.single.point.longitude, 106.777363);
    service.dispose();
  });

  test('bỏ qua gợi ý không có tọa độ hợp lệ', () {
    expect(
      MapPlace.fromPhoton({
        'geometry': {
          'coordinates': [200, 10],
        },
        'properties': {'name': 'Sai tọa độ'},
      }),
      isNull,
    );
  });
}
