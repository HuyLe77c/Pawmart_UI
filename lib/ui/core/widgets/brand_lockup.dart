import 'package:flutter/material.dart';

import '../app_theme.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: compact ? 40 : 54,
        height: compact ? 40 : 54,
        decoration: BoxDecoration(
          color: PawmartColors.greenDark,
          borderRadius: BorderRadius.circular(compact ? 13 : 17),
        ),
        child: Icon(
          Icons.pets_rounded,
          color: Colors.white,
          size: compact ? 23 : 29,
        ),
      ),
      SizedBox(width: compact ? 10 : 12),
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
                fontSize: compact ? 20 : 25,
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
                fontSize: compact ? 9 : 10,
                letterSpacing: compact ? 1.1 : 1.2,
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
