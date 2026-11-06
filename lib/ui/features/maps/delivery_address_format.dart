import 'package:geocoding/geocoding.dart';

String addressNearPin(Placemark place) {
  final road = (place.thoroughfare?.trim().isNotEmpty ?? false)
      ? place.thoroughfare!
      : (place.street ?? '').replaceFirst(RegExp(r'^\d+(?:/\d+)*\s+'), '');
  final parts = <String>[
    road,
    place.subLocality ?? '',
    place.locality ?? '',
    place.administrativeArea ?? '',
  ].map((part) => part.trim()).where((part) => part.isNotEmpty);
  return parts.toSet().join(', ');
}
