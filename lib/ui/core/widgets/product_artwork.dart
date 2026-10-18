import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/services/api_client.dart';
import '../app_theme.dart';

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({
    super.key,
    this.imageUrl,
    this.height = 130,
    this.icon = Icons.inventory_2_outlined,
  });

  final String? imageUrl;
  final double height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final imageUri = url == null || url.isEmpty
        ? null
        : context.read<ApiClient>().resolveMediaUri(url).toString();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: imageUri == null
            ? const _ArtworkPlaceholder()
            : Image.network(
                imageUri,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const _ArtworkPlaceholder(),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
              ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: PawmartColors.greenPale,
    child: Center(
      child: Icon(Icons.pets, size: 42, color: PawmartColors.green),
    ),
  );
}
