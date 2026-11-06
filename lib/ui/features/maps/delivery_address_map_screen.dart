import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import 'address_search_service.dart';
import 'delivery_address_format.dart';
import 'map_widgets.dart';

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
    this.searchService,
  });
  final String address;
  final double? latitude;
  final double? longitude;
  final AddressSearchService? searchService;

  @override
  State<DeliveryAddressMapScreen> createState() =>
      _DeliveryAddressMapScreenState();
}

class _DeliveryAddressMapScreenState extends State<DeliveryAddressMapScreen> {
  final _map = MapController();
  late final _geocoding = Geocoding(locale: const Locale('vi', 'VN'));
  late final AddressSearchService _searchService;
  late final TextEditingController _address;
  Timer? _searchDebounce;
  Timer? _cameraDebounce;
  LatLng? _pin;
  LatLng? _userPoint;
  double? _accuracyMeters;
  List<MapPlace> _suggestions = const [];
  List<MapPlace> _nearbyOptions = const [];
  LatLng? _nearbyCenter;
  LatLng? _searchHereCenter;
  int _nearbyGeneration = 0;
  bool _nearbyLoading = false;
  bool _searchHereVisible = false;
  bool _busy = false;
  bool _locating = false;
  bool _searching = false;
  bool _showSuggestions = false;
  bool _suggestionsExpanded = true;
  bool _needsAddressReview = false;
  String? _message;
  String? _suggestionError;
  int _searchGeneration = 0;
  int _lookupGeneration = 0;

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? AddressSearchService();
    _address = TextEditingController(text: widget.address);
    if (widget.latitude != null && widget.longitude != null) {
      _pin = LatLng(widget.latitude!, widget.longitude!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadNearby(_pin ?? cityCenter));
      unawaited(_warmLocation());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _cameraDebounce?.cancel();
    if (widget.searchService == null) _searchService.dispose();
    _address.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    _lookupGeneration++;
    _searchGeneration++;
    _searchDebounce?.cancel();
    setState(() {
      if (_pin != null && !_needsAddressReview) _pin = null;
      _needsAddressReview = _pin != null && !_hasHouseNumber(value);
      _busy = false;
      _searching = false;
      _message = null;
      _showSuggestions = value.trim().length >= 3;
      _suggestionsExpanded = true;
      _suggestionError = null;
      _suggestions = const [];
    });
    if (!_showSuggestions) return;
    _searchDebounce = Timer(
      const Duration(milliseconds: 480),
      () => _loadSuggestions(value.trim()),
    );
  }

  Future<void> _loadNearby(LatLng center) async {
    if (_nearbyCenter != null &&
        const Distance().as(LengthUnit.Meter, _nearbyCenter!, center) < 400) {
      return;
    }
    _nearbyCenter = center;
    final generation = ++_nearbyGeneration;
    if (mounted) setState(() => _nearbyLoading = true);
    try {
      final road = await _searchService.reverse(center);
      if (road == null || road.name.trim().length < 3) {
        _nearbyCenter = null;
        return;
      }
      final results = await _searchService.suggest(road.name, near: center);
      if (!mounted || generation != _nearbyGeneration) return;
      final nearby = results
          .where((place) {
            return const Distance().as(LengthUnit.Meter, center, place.point) <=
                1800;
          })
          .toList(growable: false);
      setState(() => _nearbyOptions = nearby);
    } catch (_) {
      if (generation == _nearbyGeneration) _nearbyCenter = null;
    } finally {
      if (mounted && generation == _nearbyGeneration) {
        setState(() => _nearbyLoading = false);
      }
    }
  }

  void _onUserMove(LatLng center) {
    _cameraDebounce?.cancel();
    _cameraDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final origin = _nearbyCenter ?? _pin ?? cityCenter;
      if (const Distance().as(LengthUnit.Meter, origin, center) > 350) {
        setState(() {
          _searchHereCenter = center;
          _searchHereVisible = true;
        });
      }
    });
  }

  void _searchHere() {
    final center = _searchHereCenter;
    if (center == null) return;
    setState(() {
      _searchHereVisible = false;
      _nearbyOptions = const [];
      _showSuggestions = false;
    });
    unawaited(_loadNearby(center));
  }

  Future<void> _loadSuggestions(String query) async {
    final generation = ++_searchGeneration;
    setState(() => _searching = true);
    try {
      final places = await _searchService.suggest(
        query,
        near: _userPoint ?? _pin,
      );
      if (!mounted || generation != _searchGeneration) return;
      if (_address.text.trim() != query) return;
      setState(() {
        _suggestions = places;
        _suggestionError = null;
      });
    } catch (_) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _suggestions = const [];
        _suggestionError =
            'Chưa tải được gợi ý. Bạn vẫn có thể chọn trên bản đồ.';
      });
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _searching = false);
      }
    }
  }

  void _choosePlace(MapPlace place) {
    _searchDebounce?.cancel();
    _searchGeneration++;
    _lookupGeneration++;
    FocusScope.of(context).unfocus();
    _address.text = place.address;
    setState(() {
      _busy = false;
      _searching = false;
      _pin = place.point;
      _showSuggestions = false;
      _suggestions = const [];
      _needsAddressReview = !_hasHouseNumber(place.address);
      _message = _needsAddressReview
          ? 'Đã ghim vị trí gần địa chỉ. Bổ sung số nhà hoặc điểm nhận hàng.'
          : 'Kiểm tra lại ghim trước khi dùng địa chỉ này.';
    });
    _map.move(place.point, 18);
  }

  bool _hasHouseNumber(String value) =>
      RegExp(r'(^|,\s*)\d+[A-Za-z]?(?:/\d+)?\b').hasMatch(value);

  Future<void> _reverse(LatLng point) async {
    final generation = ++_lookupGeneration;
    _searchGeneration++;
    _searchDebounce?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _pin = point;
      _busy = true;
      _searching = false;
      _showSuggestions = false;
      _suggestions = const [];
      _needsAddressReview = true;
      _message = 'Đang đọc địa chỉ gần ghim…';
    });
    _map.move(point, 18);
    String? nearestAddress;
    try {
      final places = await _geocoding
          .placemarkFromCoordinates(point.latitude, point.longitude)
          .timeout(const Duration(seconds: 3));
      if (places.isNotEmpty) nearestAddress = addressNearPin(places.first);
    } catch (_) {}
    if (nearestAddress == null || nearestAddress.isEmpty) {
      try {
        nearestAddress = (await _searchService.reverse(point))?.address;
      } catch (_) {}
    }
    if (!mounted || generation != _lookupGeneration) return;
    if (nearestAddress != null && nearestAddress.isNotEmpty) {
      _address.text = nearestAddress;
    }
    setState(() {
      _busy = false;
      _message = nearestAddress == null || nearestAddress.isEmpty
          ? 'Đã đặt ghim. Nhập số nhà, đường và phường để giao chính xác.'
          : 'Đây là địa chỉ gần ghim. Bổ sung số nhà hoặc điểm nhận hàng.';
    });
  }

  Future<void> _search() async {
    final query = _address.text.trim();
    if (query.length < 3) {
      setState(() => _message = 'Nhập tên đường hoặc địa điểm để tìm.');
      return;
    }
    if (_suggestions.isNotEmpty) {
      _choosePlace(_suggestions.first);
      return;
    }
    FocusScope.of(context).unfocus();
    final generation = ++_lookupGeneration;
    setState(() {
      _busy = true;
      _showSuggestions = false;
      _message = null;
    });
    try {
      final results = await _searchService.suggest(
        query,
        near: _userPoint ?? _pin,
      );
      if (!mounted || generation != _lookupGeneration) return;
      if (results.isNotEmpty) {
        _choosePlace(results.first);
        return;
      }
      final fallback = await _geocoding
          .locationFromAddress(query)
          .timeout(const Duration(seconds: 7));
      if (!mounted || generation != _lookupGeneration) return;
      if (fallback.isEmpty) throw StateError('empty');
      final point = LatLng(fallback.first.latitude, fallback.first.longitude);
      setState(() {
        _pin = point;
        _needsAddressReview = !_hasHouseNumber(query);
        _message = _needsAddressReview
            ? 'Vị trí chỉ gần địa chỉ này. Hãy bổ sung số nhà hoặc điểm nhận hàng.'
            : 'Đã tìm thấy vị trí gần địa chỉ. Kiểm tra lại ghim.';
      });
      _map.move(point, 18);
    } catch (_) {
      if (mounted && generation == _lookupGeneration) {
        setState(
          () => _message = 'Không tìm được địa chỉ. Thử thêm phường, thành phố hoặc chọn ghim.',
        );
      }
    } finally {
      if (mounted && generation == _lookupGeneration) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _warmLocation() async {
    if (!mounted) return;
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      return;
    }
    if (!mounted ||
        permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (last != null &&
          DateTime.now().difference(last.timestamp).inMinutes < 5 &&
          last.accuracy <= 250) {
        _showUserPosition(last, moveMap: _pin == null);
      }
    } catch (_) {}
    await _currentLocation(selectPin: false, requestPermission: false);
  }

  void _showUserPosition(Position position, {required bool moveMap}) {
    final point = LatLng(position.latitude, position.longitude);
    setState(() {
      _userPoint = point;
      _accuracyMeters = position.accuracy;
    });
    if (moveMap) _map.move(point, 17);
    unawaited(_loadNearby(point));
  }

  Future<void> _currentLocation({
    bool selectPin = true,
    bool requestPermission = true,
  }) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Hãy bật định vị trên điện thoại.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (requestPermission) {
          throw StateError('Hãy cho phép truy cập vị trí để dùng GPS.');
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
      _showUserPosition(position, moveMap: !selectPin && _pin == null);
      if (selectPin) {
        await _reverse(LatLng(position.latitude, position.longitude));
        if (mounted && position.accuracy > 100) {
          setState(
            () => _message =
                'GPS sai số khoảng ${position.accuracy.round()} m. Hãy chỉnh ghim và địa chỉ nhận hàng.',
          );
        }
      }
    } catch (error) {
      if (mounted && requestPermission) {
        setState(
          () => _message = error is StateError
              ? error.message
              : 'Chưa lấy được GPS. Bạn có thể tìm địa chỉ hoặc chọn ghim.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _confirm() {
    if (_pin == null) {
      setState(
        () => _message = 'Chọn một gợi ý, dùng GPS hoặc đặt ghim trên bản đồ.',
      );
      return;
    }
    if (_address.text.trim().length < 5) {
      setState(() => _message = 'Nhập địa chỉ giao hàng cụ thể.');
      return;
    }
    if (_needsAddressReview) {
      setState(
        () => _message =
            'Bổ sung số nhà hoặc mô tả điểm nhận vào ô địa chỉ phía trên.',
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
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn điểm giao hàng')),
      body: Stack(
        children: [
          PawMap(
            center: _pin ?? cityCenter,
            marker: _pin,
            controller: _map,
            userLocation: _userPoint,
            accuracyMeters: _accuracyMeters,
            attributionBottom: keyboardOpen ? 8 : 242,
            onTap: _busy ? null : _reverse,
            choices: _showSuggestions ? _suggestions : _nearbyOptions,
            onChoiceTap: _choosePlace,
            onUserMove: _onUserMove,
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                _searchPanel(),
                if (!_showSuggestions && _searchHereVisible) _searchHereChip(),
                if (!_showSuggestions && !_searchHereVisible && _nearbyLoading)
                  _loadingNearbyChip(),
                if (!_showSuggestions &&
                    !_searchHereVisible &&
                    !_nearbyLoading &&
                    _nearbyOptions.isNotEmpty)
                  _nearbyChip(),
                if (_showSuggestions) _suggestionPanel(),
                const Spacer(),
                if (!keyboardOpen) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        MapZoomControls(controller: _map),
                        const SizedBox(width: 10),
                        FloatingActionButton.small(
                          heroTag: 'delivery-location',
                          onPressed: _locating
                              ? null
                              : () => _currentLocation(),
                          tooltip: 'Dùng vị trí GPS hiện tại',
                          child: _locating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded),
                        ),
                      ],
                    ),
                  ),
                  _bottomCard(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchPanel() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: _address,
        onChanged: _onAddressChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(),
        decoration: InputDecoration(
          hintText: 'Tìm số nhà, đường, địa điểm…',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: PawmartColors.green,
          ),
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(15),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  tooltip: 'Tìm trên bản đồ',
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),
  );

  Widget _nearbyChip() => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 0),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _suggestions = _nearbyOptions;
            _showSuggestions = true;
            _suggestionsExpanded = true;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_outlined,
                  size: 17,
                  color: PawmartColors.green,
                ),
                const SizedBox(width: 7),
                Text(
                  '${_nearbyOptions.length} gợi ý quanh đây',
                  style: const TextStyle(
                    color: PawmartColors.greenDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: PawmartColors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _searchHereChip() => Align(
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Material(
        color: PawmartColors.greenDark,
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _searchHere,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 17, color: Colors.white),
                SizedBox(width: 7),
                Text(
                  'Tìm khu vực này',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _loadingNearbyChip() => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.fromLTRB(16, 9, 16, 0),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Text(
            'Đang tìm vị trí quanh đây…',
            style: TextStyle(
              color: PawmartColors.greenDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _suggestionPanel() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.sizeOf(context).height -
                  MediaQuery.viewInsetsOf(context).bottom) *
              (MediaQuery.viewInsetsOf(context).bottom > 0 ? 0.4 : 0.3),
        ),
        child: _suggestionError != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _suggestionError!,
                  style: const TextStyle(color: PawmartColors.muted),
                ),
              )
            : _suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Nhập thêm đường, phường hoặc thành phố để tìm đúng nơi.',
                  style: TextStyle(color: PawmartColors.muted),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_suggestions.length} vị trí phù hợp',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: PawmartColors.greenDark,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final expanded = !_suggestionsExpanded;
                            if (!expanded) {
                              FocusScope.of(context).unfocus();
                              _map.move(_suggestions.first.point, 17);
                            }
                            setState(() => _suggestionsExpanded = expanded);
                          },
                          icon: Icon(
                            _suggestionsExpanded
                                ? Icons.map_outlined
                                : Icons.format_list_bulleted_rounded,
                            size: 17,
                          ),
                          label: Text(
                            _suggestionsExpanded ? 'Bản đồ' : 'Danh sách',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_suggestionsExpanded)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(bottom: 6),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: PawmartColors.greenPale,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: PawmartColors.greenDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              place.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _choosePlace(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    ),
  );

  Widget _bottomCard() => Container(
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
        const SizedBox(height: 14),
        const Text(
          'VỊ TRÍ GIAO HÀNG',
          style: TextStyle(
            color: PawmartColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _pin == null
              ? 'Tìm địa chỉ hoặc dùng vị trí hiện tại'
              : _address.text.trim().isEmpty
              ? 'Đã chọn ghim trên bản đồ'
              : _address.text.trim(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PawmartColors.ink,
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _pin == null
              ? 'Chấm xanh là GPS của bạn; ghim xanh là điểm giao.'
              : 'Ghim: ${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
          style: const TextStyle(fontSize: 11, color: PawmartColors.muted),
        ),
        if (_message != null) ...[
          const SizedBox(height: 8),
          Text(
            _message!,
            style: const TextStyle(color: PawmartColors.amber, fontSize: 12),
          ),
        ],
        const SizedBox(height: 13),
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Dùng địa chỉ này'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    ),
  );
}
