import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Hiển thị ảnh người dùng vừa chọn bằng image_picker trên mọi nền tảng.
/// - Web: [XFile.path] là blob URL nên dùng Image.network (Image.file không hỗ trợ web).
/// - Mobile/Desktop: dùng Image.file như cũ.
class PickedImage extends StatelessWidget {
  const PickedImage({
    super.key,
    required this.file,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  });

  final XFile file;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
    return Image.file(
      File(file.path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}