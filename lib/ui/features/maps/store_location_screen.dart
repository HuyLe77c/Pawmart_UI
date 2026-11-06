import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/stores_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../core/app_theme.dart';
import 'map_widgets.dart';

class StoreLocationScreen extends StatefulWidget {
  const StoreLocationScreen({super.key});

  @override
  State<StoreLocationScreen> createState() => _StoreLocationScreenState();
}

class _StoreLocationScreenState extends State<StoreLocationScreen> {
  final _map = MapController();
  late Future<List<StoreLocation>> _stores;
  int _selected = 0;
  LatLng? _userPoint;
  double? _accuracyMeters;
  bool _locating = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLocation(false));
  }

  void _reload() {
    _stores = StoresRepository(context.read<ApiClient>()).activeStores();
  }

  Future<void> _loadLocation(bool requestPermission) async {
    if (_locating || !mounted) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Bật định vị để xem vị trí của bạn.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (requestPermission) {
          throw StateError('Cho phép vị trí để xem bạn đang ở đâu.');
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _userPoint = point;
        _accuracyMeters = position.accuracy;
        _locationMessage = null;
      });
      if (requestPermission) _map.move(point, 16);
    } catch (error) {
      if (mounted && requestPermission) {
        setState(
          () => _locationMessage = error is StateError
              ? error.message
              : 'Không lấy được GPS. Hãy thử lại sau.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openDirections(StoreLocation store) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': store.address,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng chỉ đường.')),
      );
    }
  }

  Future<void> _copyAddress(String address) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép địa chỉ cửa hàng.')),
      );
    }
  }

  String _distanceTo(LatLng point) {
    final meters = const Distance().as(LengthUnit.Meter, _userPoint!, point);
    return meters < 1000
        ? '${meters.round()} m'
        : '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<List<StoreLocation>>(
      future: _stores,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadState(snapshot.hasError);
        }
        final stores = snapshot.data!;
        if (stores.isEmpty) return _loadState(true, empty: true);
        final selected = stores[_selected.clamp(0, stores.length - 1)];
        final point = LatLng(selected.latitude, selected.longitude);
        final bottomInset = MediaQuery.paddingOf(context).bottom;
        return Stack(
          children: [
            PawMap(
              center: point,
              marker: point,
              controller: _map,
              zoom: 17,
              userLocation: _userPoint,
              accuracyMeters: _accuracyMeters,
              attributionBottom: 298 + bottomInset,
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  if (stores.length > 1) _storeChoices(stores),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MapZoomControls(controller: _map),
                        const SizedBox(width: 10),
                        FloatingActionButton.small(
                          heroTag: 'store-location',
                          tooltip: 'Xem vị trí hiện tại',
                          onPressed: _locating
                              ? null
                              : () => _loadLocation(true),
                          child: _locating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),
                  _storeCard(selected, point),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _loadState(bool error, {bool empty = false}) => SafeArea(
    child: Column(
      children: [
        _header(),
        const Spacer(),
        Icon(
          error ? Icons.location_off_outlined : Icons.map_outlined,
          color: PawmartColors.green,
          size: 42,
        ),
        const SizedBox(height: 12),
        Text(
          empty
              ? 'Chưa có địa chỉ cửa hàng.'
              : error
              ? 'Chưa tải được địa chỉ cửa hàng.'
              : 'Đang mở bản đồ cửa hàng…',
        ),
        if (error && !empty)
          TextButton(
            onPressed: () => setState(_reload),
            child: const Text('Thử lại'),
          ),
        const Spacer(),
      ],
    ),
  );

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Material(
      elevation: 5,
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Quay lại',
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 5),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghé PawMart',
                    style: TextStyle(
                      color: PawmartColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Xem cơ sở và tìm đường đi',
                    style: TextStyle(color: PawmartColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Về vị trí cửa hàng',
              onPressed: () async {
                final stores = await _stores;
                if (!mounted || stores.isEmpty) return;
                final selected = stores[_selected.clamp(0, stores.length - 1)];
                _map.move(LatLng(selected.latitude, selected.longitude), 17);
              },
              icon: const Icon(
                Icons.storefront_rounded,
                color: PawmartColors.green,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _storeChoices(List<StoreLocation> stores) => SizedBox(
    height: 55,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
      itemCount: stores.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) => ChoiceChip(
        label: Text(stores[index].name),
        selected: index == _selected,
        onSelected: (_) {
          setState(() => _selected = index);
          _map.move(
            LatLng(stores[index].latitude, stores[index].longitude),
            17,
          );
        },
      ),
    ),
  );

  Widget _storeCard(StoreLocation store, LatLng point) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [BoxShadow(color: Color(0x18000000), blurRadius: 18)],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: PawmartColors.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(
              Icons.storefront_rounded,
              color: PawmartColors.green,
              size: 23,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                store.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Sao chép địa chỉ',
              onPressed: () => _copyAddress(store.address),
              icon: const Icon(Icons.copy_rounded, size: 19),
            ),
          ],
        ),
        Text(
          store.address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: PawmartColors.ink, height: 1.35),
        ),
        const SizedBox(height: 8),
        if (_userPoint != null)
          Text(
            'Cách bạn khoảng ${_distanceTo(point)} theo đường thẳng',
            style: const TextStyle(
              color: PawmartColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (_locationMessage != null)
          Text(
            _locationMessage!,
            style: const TextStyle(color: PawmartColors.amber, fontSize: 12),
          ),
        const SizedBox(height: 7),
        const Text(
          'Ghim chỉ vị trí tham khảo trên đường. Xem số nhà trước khi đến.',
          style: TextStyle(
            color: PawmartColors.muted,
            fontSize: 11,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => _openDirections(store),
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Mở chỉ đường'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    ),
  );
}
