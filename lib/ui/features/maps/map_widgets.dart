import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';

const cityCenter = LatLng(10.8483153, 106.7773630);
const tileUrl = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

class PawMap extends StatelessWidget {
  const PawMap({
    super.key,
    required this.center,
    required this.marker,
    this.controller,
    this.zoom = 16,
    this.onTap,
  });

  final LatLng center;
  final LatLng? marker;
  final MapController? controller;
  final double zoom;
  final ValueChanged<LatLng>? onTap;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          minZoom: 5,
          maxZoom: 19,
          onTap: onTap == null ? null : (_, point) => onTap!(point),
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'vn.pawmart.petstore',
          ),
          if (marker != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: marker!,
                  width: 58,
                  height: 68,
                  alignment: Alignment.topCenter,
                  child: const _PawPin(),
                ),
              ],
            ),
        ],
      ),
      Positioned(
        right: 5,
        bottom: 5,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10, color: PawmartColors.ink),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _PawPin extends StatelessWidget {
  const _PawPin();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: PawmartColors.greenDark,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.pets_rounded, color: Colors.white, size: 26),
      ),
      Container(width: 3, height: 11, color: PawmartColors.greenDark),
    ],
  );
}
