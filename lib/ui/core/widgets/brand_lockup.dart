import 'package:flutter/material.dart';

import '../app_theme.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => compact
      ? _compactLockup()
      : Image.asset(
          'assets/branding/pawmart-logo.png',
          width: 190,
          height: 190,
          fit: BoxFit.contain,
          semanticLabel: 'PawMart',
        );

  Widget _compactLockup() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        'assets/branding/pawmart-mark.png',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        semanticLabel: 'Biểu tượng PawMart',
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PawMart',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: PawmartColors.ink,
              ),
            ),
            Text(
              'CHĂM SÓC BÉ MỖI NGÀY',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
                color: PawmartColors.muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
