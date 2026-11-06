import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import 'address_search_service.dart';

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
    this.zoom = 17,
    this.onTap,
    this.userLocation,
    this.accuracyMeters,
    this.attributionBottom = 5,
    this.choices = const [],
    this.onChoiceTap,
    this.onUserMove,
  });

  final LatLng center;
  final LatLng? marker;
  final MapController? controller;
  final double zoom;
  final ValueChanged<LatLng>? onTap;
  final LatLng? userLocation;
  final double? accuracyMeters;
  final double attributionBottom;
  final List<MapPlace> choices;
  final ValueChanged<MapPlace>? onChoiceTap;
  final ValueChanged<LatLng>? onUserMove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: zoom,
          backgroundColor: PawmartColors.cream,
          minZoom: 5,
          maxZoom: 19,
          onTap: onTap == null ? null : (_, point) => onTap!(point),
          onPositionChanged: onUserMove == null
              ? null
              : (camera, hasGesture) {
                  if (hasGesture) onUserMove!(camera.center);
                },
        ),
        children: [
          TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: 'vn.pawmart.petstore',
          ),
          if (userLocation != null && accuracyMeters != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: userLocation!,
                  radius: accuracyMeters!.clamp(12, 160),
                  useRadiusInMeter: true,
                  color: const Color(0x24608AD7),
                  borderColor: const Color(0x55608AD7),
                  borderStrokeWidth: 1,
                ),
              ],
            ),
          if (choices.isNotEmpty)
            MarkerLayer(
              markers: [
                for (var index = 0; index < choices.length; index++)
                  Marker(
                    point: choices[index].point,
                    width: 38,
                    height: 38,
                    child: Semantics(
                      label: 'Gợi ý ${index + 1}: ${choices[index].name}',
                      button: true,
                      child: Tooltip(
                        message: choices[index].name,
                        child: GestureDetector(
                          onTap: onChoiceTap == null
                              ? null
                              : () => onChoiceTap!(choices[index]),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: PawmartColors.green,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: PawmartColors.greenDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (marker != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: marker!,
                  width: 64,
                  height: 68,
                  alignment: Alignment.bottomCenter,
                  child: const _PawPin(),
                ),
              ],
            ),
          if (userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: userLocation!,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2877D2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 9,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      Positioned(
        left: 8,
        bottom: attributionBottom,
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
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.topCenter,
    children: [
      const Icon(
        Icons.location_on_rounded,
        color: PawmartColors.greenDark,
        size: 66,
        shadows: [Shadow(color: Color(0x55000000), blurRadius: 10)],
      ),
      Positioned(
        top: 9,
        child: Container(
          width: 37,
          height: 37,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: PawmartColors.greenDark,
            size: 21,
          ),
        ),
      ),
    ],
  );
}

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({super.key, required this.controller});
  final MapController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    borderRadius: BorderRadius.circular(15),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Phóng to bản đồ',
          onPressed: () => controller.move(
            controller.camera.center,
            (controller.camera.zoom + 1).clamp(5, 19),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
        const SizedBox(width: 30, child: Divider(height: 1)),
        IconButton(
          tooltip: 'Thu nhỏ bản đồ',
          onPressed: () => controller.move(
            controller.camera.center,
            (controller.camera.zoom - 1).clamp(5, 19),
          ),
          icon: const Icon(Icons.remove_rounded),
        ),
      ],
    ),
  );
}
