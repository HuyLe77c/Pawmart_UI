import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _stores = StoresRepository(context.read<ApiClient>()).activeStores();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ghé PawMart'),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
    ),
    body: FutureBuilder<List<StoreLocation>>(
      future: _stores,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    size: 42,
                    color: PawmartColors.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text('Chưa tải được địa chỉ cửa hàng.'),
                  TextButton(
                    onPressed: () => setState(_reload),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
        final stores = snapshot.data!;
        if (stores.isEmpty) {
          return const Center(child: Text('Cửa hàng chưa cập nhật địa chỉ.'));
        }
        final selected = stores[_selected.clamp(0, stores.length - 1)];
        final point = LatLng(selected.latitude, selected.longitude);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          children: [
            Text(
              'Tìm đường đến cửa hàng',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Địa chỉ rõ ràng, dễ tìm đường khi bạn ghé mua trực tiếp.',
              style: TextStyle(color: PawmartColors.muted),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 330,
                child: PawMap(center: point, marker: point, controller: _map),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ghim là vị trí tham khảo; hãy kiểm tra địa chỉ chi tiết trước khi đến.',
              style: TextStyle(fontSize: 12, color: PawmartColors.muted),
            ),
            if (stores.length > 1) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stores.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ChoiceChip(
                    label: Text(stores[index].name),
                    selected: index == _selected,
                    onSelected: (_) {
                      setState(() => _selected = index);
                      _map.move(
                        LatLng(stores[index].latitude, stores[index].longitude),
                        16,
                      );
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PawmartColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: PawmartColors.green,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selected.name,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    selected.address,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: selected.address),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép địa chỉ cửa hàng.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Sao chép địa chỉ'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openDirections(selected),
              icon: const Icon(Icons.directions_rounded),
              label: const Text('Mở chỉ đường'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ],
        );
      },
    ),
  );
}
