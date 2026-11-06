import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import 'map_widgets.dart';
import 'delivery_address_format.dart';

class DeliveryPlace {
  const DeliveryPlace({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  final String address;
  final double latitude;
  final double longitude;
}

class DeliveryMapInput {
  const DeliveryMapInput({
    required this.address,
    this.latitude,
    this.longitude,
  });
  final String address;
  final double? latitude;
  final double? longitude;
}

class DeliveryAddressMapScreen extends StatefulWidget {
  const DeliveryAddressMapScreen({
    super.key,
    this.address = '',
    this.latitude,
    this.longitude,
  });
  final String address;
  final double? latitude;
  final double? longitude;

  @override
  State<DeliveryAddressMapScreen> createState() =>
      _DeliveryAddressMapScreenState();
}

class _DeliveryAddressMapScreenState extends State<DeliveryAddressMapScreen> {
  final _map = MapController();
  final _geocoding = Geocoding(locale: const Locale('vi', 'VN'));
  late final TextEditingController _address;
  LatLng? _pin;
  bool _busy = false;
  bool _needsAddressReview = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(text: widget.address);
    if (widget.latitude != null && widget.longitude != null) {
      _pin = LatLng(widget.latitude!, widget.longitude!);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _setPin(LatLng point, {double zoom = 17}) {
    setState(() {
      _pin = point;
      _message = null;
    });
    _map.move(point, zoom);
  }

  Future<void> _reverse(LatLng point) async {
    _setPin(point);
    setState(() {
      _busy = true;
      _needsAddressReview = true;
    });
    try {
      final places = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (!mounted) return;
      if (places.isNotEmpty) {
        final address = addressNearPin(places.first);
        if (address.isNotEmpty) {
          _address.text = address;
        }
        setState(
          () => _message = 'Đã lấy địa chỉ gần ghim. Hãy bổ sung số nhà và kiểm tra lại trước khi đặt.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Đã chọn ghim. Chưa đọc được địa chỉ; hãy nhập số nhà, đường và phường.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search() async {
    final query = _address.text.trim();
    if (query.length < 5) {
      setState(() => _message = 'Nhập địa chỉ đủ chi tiết để tìm trên bản đồ.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final places = await _geocoding.locationFromAddress(query);
      if (!mounted) return;
      if (places.isEmpty) throw StateError('empty');
      _setPin(LatLng(places.first.latitude, places.first.longitude));
      setState(
        () => _message =
            'Đã tìm thấy vị trí gần địa chỉ. Hãy kiểm tra ghim và số nhà.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Không tìm được địa chỉ này. Hãy thêm phường, thành phố hoặc chạm chọn trên bản đồ.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _currentLocation() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Hãy bật dịch vụ vị trí trên điện thoại.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Chưa có quyền vị trí. Bạn vẫn có thể tìm địa chỉ hoặc chọn ghim.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      await _reverse(LatLng(position.latitude, position.longitude));
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is StateError ? error.message : 'Không lấy được vị trí hiện tại. Bạn có thể tìm địa chỉ hoặc chọn ghim.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm() {
    if (_pin == null) {
      setState(
        () => _message =
            'Hãy tìm địa chỉ, dùng GPS hoặc chạm bản đồ để đặt ghim.',
      );
      return;
    }
    if (_address.text.trim().length < 5) {
      setState(
        () => _message =
            'Hãy nhập địa chỉ giao hàng cụ thể, gồm số nhà và đường.',
      );
      return;
    }
    if (_needsAddressReview) {
      setState(
        () => _message =
            'Hãy bổ sung số nhà hoặc mô tả điểm nhận vào địa chỉ phía trên.',
      );
      return;
    }
    Navigator.pop(
      context,
      DeliveryPlace(
        address: _address.text.trim(),
        latitude: _pin!.latitude,
        longitude: _pin!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Chọn điểm giao hàng')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _address,
                  onChanged: (_) {
                    if (_needsAddressReview) {
                      setState(() => _needsAddressReview = false);
                    }
                  },
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: const InputDecoration(
                    hintText: 'Số nhà, đường, phường, thành phố',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Tìm địa chỉ trên bản đồ',
                onPressed: _busy ? null : _search,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              PawMap(
                center: _pin ?? cityCenter,
                marker: _pin,
                controller: _map,
                onTap: _busy ? null : _reverse,
              ),
              Positioned(
                top: 12,
                left: 18,
                right: 18,
                child: IgnorePointer(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Color(0x20000000), blurRadius: 10),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Text(
                          _pin == null
                              ? 'Chạm bản đồ để chọn đúng điểm giao'
                              : 'Ghim đã chọn · Chạm để chỉnh lại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 22,
                child: FloatingActionButton.small(
                  heroTag: 'delivery-location',
                  onPressed: _busy ? null : _currentLocation,
                  tooltip: 'Dùng vị trí hiện tại',
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.edit_location_alt_rounded,
                      color: PawmartColors.green,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Địa chỉ giao hàng',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (_busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _pin == null
                      ? 'Chưa chọn vị trí trên bản đồ'
                      : 'Ghim: ${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PawmartColors.muted,
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: const TextStyle(
                      color: PawmartColors.amber,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _confirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Dùng địa chỉ này'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
