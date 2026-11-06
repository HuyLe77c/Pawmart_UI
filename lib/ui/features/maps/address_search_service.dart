import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapPlace {
  const MapPlace({
    required this.name,
    required this.address,
    required this.point,
  });

  final String name;
  final String address;
  final LatLng point;

  static MapPlace? fromPhoton(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final properties = feature['properties'];
    if (geometry is! Map || properties is! Map) return null;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;
    final longitude = coordinates[0];
    final latitude = coordinates[1];
    if (longitude is! num || latitude is! num) return null;
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    String field(String key) => '${properties[key] ?? ''}'.trim();
    final house = field('housenumber');
    final street = field('street');
    final name = field('name');
    final first = [house, street].where((part) => part.isNotEmpty).join(' ');
    final main = first.isNotEmpty ? first : name;
    final parts = <String>[
      main,
      field('locality'),
      field('district'),
      field('city'),
      field('state'),
    ];
    final unique = <String>[];
    for (final part in parts) {
      if (part.isNotEmpty && !unique.contains(part)) unique.add(part);
    }
    final address = unique.join(', ');
    if (address.isEmpty) return null;
    return MapPlace(
      name: name.isNotEmpty ? name : main,
      address: address,
      point: LatLng(latitude.toDouble(), longitude.toDouble()),
    );
  }
}

class AddressSearchService {
  AddressSearchService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, List<MapPlace>> _cache = {};
  static const _host = String.fromEnvironment(
    'MAP_SEARCH_HOST',
    defaultValue: 'photon.komoot.io',
  );

  Future<List<MapPlace>> suggest(String query, {LatLng? near}) async {
    final cleaned = query.trim();
    if (cleaned.length < 3) return const [];
    final key =
        '${cleaned.toLowerCase()}|${near?.latitude.toStringAsFixed(2)}|${near?.longitude.toStringAsFixed(2)}';
    if (_cache[key] case final cached?) return cached;
    final focus = near ?? const LatLng(10.8231, 106.6297);
    final uri = Uri.https(_host, '/api/', {
      'q': cleaned,
      'lat': focus.latitude.toString(),
      'lon': focus.longitude.toString(),
      'limit': '15',
      'countrycode': 'VN',
    });
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'PawMart/1.0 (Android Flutter)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 7));
    if (response.statusCode != 200) {
      throw StateError('Address search unavailable');
    }
    final data = jsonDecode(response.body);
    if (data is! Map || data['features'] is! List) return const [];
    final places = (data['features'] as List)
        .whereType<Map<String, dynamic>>()
        .map(MapPlace.fromPhoton)
        .whereType<MapPlace>()
        .toList(growable: false);
    if (_cache.length >= 16) _cache.remove(_cache.keys.first);
    _cache[key] = places;
    return places;
  }

  Future<MapPlace?> reverse(LatLng point) async {
    final uri = Uri.https(_host, '/reverse', {
      'lat': point.latitude.toString(),
      'lon': point.longitude.toString(),
      'limit': '1',
    });
    final response = await _client
        .get(
          uri,
          headers: {
            'User-Agent': 'PawMart/1.0 (Android Flutter)',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 7));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map || data['features'] is! List) return null;
    for (final feature in data['features'] as List) {
      if (feature is Map<String, dynamic>) {
        return MapPlace.fromPhoton(feature);
      }
    }
    return null;
  }

  void dispose() => _client.close();
}
