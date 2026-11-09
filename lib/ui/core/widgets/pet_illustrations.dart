import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Decorative artwork stays outside the interaction and semantics trees.
class PetProfileBackdrop extends StatelessWidget {
  const PetProfileBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const Positioned.fill(
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _PetWallpaperPainter()),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class PetFamilyArtwork extends StatelessWidget {
  const PetFamilyArtwork({super.key});

  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: IgnorePointer(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(painter: _PetFamilyPainter()),
      ),
    ),
  );
}

class PetPortraitArtwork extends StatelessWidget {
  const PetPortraitArtwork({super.key, required this.petType});
  final String petType;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(painter: _PetPortraitPainter(petType)),
  );
}

const _honey = Color(0xFFE9BC76);
const _peach = Color(0xFFE8AB8E);
const _paper = Color(0xFFFFF8E9);

Paint _outline(Color color, [double width = 2.4]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _cat(
  Canvas canvas,
  Offset origin,
  double size, {
  Color? fill,
  Color ink = PawmartColors.greenDark,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(size / 100);
  final line = _outline(ink);
  final head = Path()
    ..moveTo(18, 44)
    ..lineTo(19, 15)
    ..quadraticBezierTo(19, 6, 28, 12)
    ..lineTo(42, 25)
    ..quadraticBezierTo(51, 22, 60, 25)
    ..lineTo(76, 11)
    ..quadraticBezierTo(84, 6, 83, 18)
    ..lineTo(84, 43)
    ..cubicTo(98, 60, 92, 88, 65, 92)
    ..quadraticBezierTo(49, 96, 31, 91)
    ..cubicTo(8, 85, 4, 62, 18, 44)
    ..close();
  if (fill != null) canvas.drawPath(head, Paint()..color = fill);
  canvas.drawPath(head, line);
  if (fill != null) {
    canvas.drawPath(
      Path()
        ..moveTo(25, 19)
        ..lineTo(26, 35)
        ..lineTo(37, 29)
        ..close(),
      Paint()..color = _peach,
    );
    canvas.drawPath(
      Path()
        ..moveTo(77, 19)
        ..lineTo(66, 29)
        ..lineTo(77, 35)
        ..close(),
      Paint()..color = _peach,
    );
  }
  canvas.drawPath(
    Path()
      ..moveTo(33, 55)
      ..quadraticBezierTo(37, 51, 41, 55),
    line,
  );
  canvas.drawPath(
    Path()
      ..moveTo(62, 55)
      ..quadraticBezierTo(66, 51, 70, 55),
    line,
  );
  canvas.drawPath(
    Path()
      ..moveTo(47, 65)
      ..lineTo(55, 65)
      ..lineTo(51, 69)
      ..close(),
    Paint()..color = ink,
  );
  canvas.drawPath(
    Path()
      ..moveTo(51, 69)
      ..lineTo(51, 74)
      ..quadraticBezierTo(45, 80, 41, 74),
    line,
  );
  canvas.drawPath(
    Path()
      ..moveTo(51, 74)
      ..quadraticBezierTo(57, 80, 61, 74),
    line,
  );
  for (final y in [64.0, 73.0]) {
    canvas.drawLine(Offset(17, y - 2), Offset(33, y + 1), line);
    canvas.drawLine(Offset(70, y + 1), Offset(86, y - 2), line);
  }
  canvas.restore();
}

void _dog(
  Canvas canvas,
  Offset origin,
  double size, {
  Color? fill,
  Color ink = PawmartColors.greenDark,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(size / 100);
  final line = _outline(ink);
  final head = Path()
    ..moveTo(23, 31)
    ..cubicTo(35, 18, 67, 18, 80, 33)
    ..cubicTo(94, 48, 94, 79, 77, 88)
    ..quadraticBezierTo(51, 101, 26, 87)
    ..cubicTo(8, 77, 10, 47, 23, 31)
    ..close();
  if (fill != null) canvas.drawPath(head, Paint()..color = fill);
  canvas.drawPath(head, line);
  final leftEar = Path()
    ..moveTo(24, 30)
    ..cubicTo(11, 15, 1, 30, 3, 54)
    ..cubicTo(2, 75, 12, 81, 21, 67)
    ..quadraticBezierTo(28, 49, 24, 30)
    ..close();
  final rightEar = Path()
    ..moveTo(79, 31)
    ..cubicTo(92, 17, 100, 34, 98, 56)
    ..cubicTo(98, 76, 87, 80, 81, 65)
    ..quadraticBezierTo(75, 48, 79, 31)
    ..close();
  for (final ear in [leftEar, rightEar]) {
    if (fill != null) canvas.drawPath(ear, Paint()..color = _peach);
    canvas.drawPath(ear, line);
  }
  if (fill != null) {
    canvas.drawOval(
      const Rect.fromLTWH(33, 58, 36, 29),
      Paint()..color = _paper,
    );
  }
  canvas.drawCircle(const Offset(36, 52), 2.5, Paint()..color = ink);
  canvas.drawCircle(const Offset(67, 52), 2.5, Paint()..color = ink);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(45, 63, 13, 9),
      const Radius.circular(4),
    ),
    Paint()..color = ink,
  );
  canvas.drawPath(
    Path()
      ..moveTo(51, 72)
      ..lineTo(51, 77)
      ..quadraticBezierTo(45, 82, 41, 77),
    line,
  );
  canvas.drawPath(
    Path()
      ..moveTo(51, 77)
      ..quadraticBezierTo(58, 82, 62, 76),
    line,
  );
  canvas.restore();
}

void _paw(Canvas canvas, Offset origin, double size, Color color) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(size / 44);
  final paint = _outline(color, 1.7);
  canvas.drawPath(
    Path()
      ..moveTo(11, 27)
      ..cubicTo(16, 14, 26, 14, 32, 28)
      ..cubicTo(42, 43, 28, 39, 23, 37)
      ..cubicTo(16, 37, 2, 42, 11, 27)
      ..close(),
    paint,
  );
  for (final toe in const [
    Rect.fromLTWH(2, 12, 7, 10),
    Rect.fromLTWH(11, 3, 8, 12),
    Rect.fromLTWH(24, 3, 8, 12),
    Rect.fromLTWH(35, 12, 7, 10),
  ]) {
    canvas.drawOval(toe, paint);
  }
  canvas.restore();
}

void _spark(Canvas canvas, Offset center, double size, Color color) {
  final paint = _outline(color, 2);
  canvas.drawLine(center - Offset(size, 0), center + Offset(size, 0), paint);
  canvas.drawLine(center - Offset(0, size), center + Offset(0, size), paint);
}

class _PetWallpaperPainter extends CustomPainter {
  const _PetWallpaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8F5ED),
    );
    canvas.drawCircle(
      Offset(size.width + 8, 100),
      180,
      Paint()..color = const Color(0xFFE9EEDC),
    );
    canvas.drawCircle(
      Offset(-70, size.height * .78),
      200,
      Paint()..color = const Color(0xFFF3E3CE),
    );
    final ink = PawmartColors.greenDark.withValues(alpha: .10);
    for (var row = 0; row * 180 < size.height + 180; row++) {
      for (var col = 0; col * 180 < size.width + 180; col++) {
        canvas.save();
        canvas.translate(
          col * 180.0 + (row.isOdd ? 75 : -28),
          row * 180.0 + 20,
        );
        canvas.rotate(row.isOdd ? .16 : -.18);
        switch ((col + row) % 3) {
          case 0:
            _cat(canvas, Offset.zero, 76, ink: ink);
          case 1:
            _dog(canvas, Offset.zero, 78, ink: ink);
          case 2:
            _paw(canvas, const Offset(12, 10), 44, ink);
        }
        _spark(
          canvas,
          const Offset(117, 108),
          4,
          _honey.withValues(alpha: .50),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PetWallpaperPainter oldDelegate) => false;
}

class _PetFamilyPainter extends CustomPainter {
  const _PetFamilyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 160);
    canvas.drawCircle(const Offset(84, 82), 65, Paint()..color = _honey);
    canvas.drawCircle(const Offset(142, 20), 4, Paint()..color = _peach);
    _spark(canvas, const Offset(19, 26), 7, _paper);
    _spark(canvas, const Offset(149, 113), 5, _peach);
    _cat(canvas, const Offset(65, 25), 83, fill: _paper);
    _dog(canvas, const Offset(5, 59), 100, fill: const Color(0xFFF2D7A4));
    canvas.drawPath(
      Path()
        ..moveTo(120, 133)
        ..cubicTo(109, 121, 100, 137, 121, 148)
        ..cubicTo(144, 135, 129, 120, 120, 133),
      _outline(_paper, 2.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PetFamilyPainter oldDelegate) => false;
}

class _PetPortraitPainter extends CustomPainter {
  const _PetPortraitPainter(this.petType);
  final String petType;

  @override
  void paint(Canvas canvas, Size size) {
    final extent = size.shortestSide * .84;
    final origin = Offset(
      (size.width - extent) / 2,
      (size.height - extent) / 2,
    );
    if (petType == 'CAT') {
      _cat(canvas, origin, extent, fill: _paper);
    } else if (petType == 'DOG') {
      _dog(canvas, origin, extent, fill: const Color(0xFFF2D7A4));
    } else {
      _paw(canvas, origin, extent, PawmartColors.green);
    }
  }

  @override
  bool shouldRepaint(_PetPortraitPainter oldDelegate) =>
      petType != oldDelegate.petType;
}
