import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

abstract final class AdminPalette {
  static const background = PawmartColors.cream;
  static const forest = PawmartColors.greenDark;
  static const green = PawmartColors.green;
  static const softGreen = PawmartColors.greenPale;
  static const ink = PawmartColors.ink;
  static const secondary = PawmartColors.muted;
  static const border = PawmartColors.line;
  static const amber = PawmartColors.amber;
  static const softAmber = PawmartColors.amberPale;
  static const red = Color(0xFFB64949);
  static const softRed = Color(0xFFFBECEC);
  static const blue = Color(0xFF3769A0);
  static const softBlue = Color(0xFFEAF1FA);
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle(this.title, {this.action, super.key});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AdminPalette.ink,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class AdminSurface extends StatelessWidget {
  const AdminSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AdminPalette.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class AdminEmptyPanel extends StatelessWidget {
  const AdminEmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => AdminSurface(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: AdminPalette.secondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AdminPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminPalette.secondary, height: 1.35),
          ),
        ],
      ),
    ),
  );
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, foreground, background) = switch (status.toUpperCase()) {
      'PENDING' => ('Chờ xử lý', AdminPalette.amber, AdminPalette.softAmber),
      'CONFIRMED' => ('Đã xác nhận', AdminPalette.blue, AdminPalette.softBlue),
      'SHIPPING' => ('Đang giao', AdminPalette.blue, AdminPalette.softBlue),
      'DELIVERED' => ('Đã giao', AdminPalette.green, AdminPalette.softGreen),
      'CANCELLED' => ('Đã hủy', AdminPalette.red, AdminPalette.softRed),
      'ALL' => ('Tất cả', AdminPalette.forest, AdminPalette.softGreen),
      'ACTIVE' => ('Đang bật', AdminPalette.green, AdminPalette.softGreen),
      'SELLING' => ('Đang bán', AdminPalette.green, AdminPalette.softGreen),
      'INACTIVE' => (
        'Đang tắt',
        AdminPalette.secondary,
        AdminPalette.background,
      ),
      _ => (status, AdminPalette.secondary, AdminPalette.background),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class AdminMetric extends StatelessWidget {
  const AdminMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.warning = false,
    super.key,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) => AdminSurface(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: warning ? AdminPalette.softAmber : AdminPalette.softGreen,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: warning ? AdminPalette.amber : AdminPalette.green,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  color: AdminPalette.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                color: AdminPalette.secondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AdminPalette.ink,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: AdminPalette.secondary),
      ),
    ],
  );
}

Widget adminSeparator() => const Divider(height: 1, color: PawmartColors.line);
