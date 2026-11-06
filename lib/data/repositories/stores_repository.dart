import '../services/api_client.dart';

class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
  });

  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;

  factory StoreLocation.fromJson(Map<String, dynamic> json) => StoreLocation(
    id: (json['storeId'] as num).toInt(),
    name: json['storeName'] as String? ?? '',
    address: json['address'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    phone: json['phoneNumber'] as String?,
  );
}

class StoresRepository {
  const StoresRepository(this.api);
  final ApiClient api;

  Future<List<StoreLocation>> activeStores() async {
    final data = await api.getJson('api/stores') as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .where((row) => row['storeType'] == 'STORE')
        .map(StoreLocation.fromJson)
        .toList(growable: false);
  }
}
