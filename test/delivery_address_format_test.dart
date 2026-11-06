import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pawmart/ui/features/maps/delivery_address_format.dart';

void main() {
  test('Vị trí gần ghim không tự nhận số nhà của nơi lân cận', () {
    const place = Placemark(
      street: '10/370 Tân Lập 1',
      thoroughfare: 'Tân Lập 1',
      subThoroughfare: '10/370',
      subLocality: 'Tăng Nhơn Phú',
      locality: 'Hồ Chí Minh',
    );
    expect(addressNearPin(place), 'Tân Lập 1, Tăng Nhơn Phú, Hồ Chí Minh');
  });

  test('Lọc số nhà gần ghim khi Android không trả tên đường riêng', () {
    const place = Placemark(
      street: '10/370 Tân Lập 1',
      locality: 'Hồ Chí Minh',
    );
    expect(addressNearPin(place), 'Tân Lập 1, Hồ Chí Minh');
  });
}
