import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: '₫',
  decimalDigits: 0,
);

String formatVnd(num amount) => _vnd.format(amount);

String? primaryImageUrl(List<dynamic> images) {
  if (images.isEmpty) return null;
  for (final image in images) {
    if (image is Map<String, dynamic> && image['isPrimary'] == true) {
      return image['imageUrl'] as String?;
    }
  }
  final first = images.first;
  return first is Map<String, dynamic> ? first['imageUrl'] as String? : null;
}
