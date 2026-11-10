import 'package:flutter/material.dart';

import '../app_theme.dart';

/// A consistent purchase footer that also works above gesture navigation.
class ShoppingActionBar extends StatelessWidget {
  const ShoppingActionBar({
    super.key,
    required this.label,
    required this.value,
    required this.action,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final Widget action;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: PawmartColors.line)),
      boxShadow: [
        BoxShadow(
          color: Color(0x10104936),
          blurRadius: 24,
          offset: Offset(0, -5),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 740),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: PawmartColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: PawmartColors.greenDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 10),
              action,
            ],
          ),
        ),
      ),
    ),
  );
}
