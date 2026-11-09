import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/catalog_filters.dart';
import '../../../../domain/models/category.dart';
import '../../../core/app_theme.dart';
import '../../../core/category_label.dart';

class CatalogFilterSheet extends StatefulWidget {
  const CatalogFilterSheet({
    super.key,
    required this.initial,
    required this.categories,
  });
  final CatalogFilters initial;
  final List<Category> categories;

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  var _formKey = GlobalKey<FormState>();
  late String _petType;
  late int? _categoryId;
  late bool _inStock;
  late final TextEditingController _breed;
  late final TextEditingController _brand;
  late final TextEditingController _minimum;
  late final TextEditingController _maximum;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _petType = value.petType;
    _categoryId =
        widget.categories.any(
          (category) => category.categoryId == value.categoryId,
        )
        ? value.categoryId
        : null;
    _inStock = value.inStockOnly;
    _breed = TextEditingController(text: value.breed ?? '');
    _brand = TextEditingController(text: value.brand ?? '');
    _minimum = TextEditingController(text: value.minPrice?.toString() ?? '');
    _maximum = TextEditingController(text: value.maxPrice?.toString() ?? '');
  }

  @override
  void dispose() {
    _breed.dispose();
    _brand.dispose();
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _petType = 'ALL';
    _categoryId = null;
    _inStock = false;
    _breed.clear();
    _brand.clear();
    _minimum.clear();
    _maximum.clear();
    _formKey = GlobalKey<FormState>();
  });

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      CatalogFilters(
        petType: _petType,
        categoryId: _categoryId,
        breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        minPrice: int.tryParse(_minimum.text),
        maxPrice: int.tryParse(_maximum.text),
        inStockOnly: _inStock,
      ),
    );
  }

  Widget _title(String value) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      value,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final compact = MediaQuery.sizeOf(context).height - keyboard < 360;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * (keyboard > 0 ? 1 : .91) -
                    keyboard)
                .clamp(120.0, double.infinity),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bộ lọc sản phẩm',
                          maxLines: compact ? 1 : null,
                          overflow: compact ? TextOverflow.ellipsis : null,
                          style: TextStyle(
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!compact) const SizedBox(height: 4),
                        if (!compact)
                          const Text(
                            'Tìm đúng món đồ bạn cần cho bé.',
                            style: TextStyle(
                              fontSize: 12,
                              color: PawmartColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng bộ lọc',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('Bạn mua cho bé nào?'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in const [
                            ('ALL', 'Tất cả'),
                            ('DOG', 'Chó'),
                            ('CAT', 'Mèo'),
                          ])
                            ChoiceChip(
                              label: Text(item.$2),
                              selected: _petType == item.$1,
                              selectedColor: PawmartColors.greenDark,
                              labelStyle: TextStyle(
                                fontFamily: 'Roboto',
                                color: _petType == item.$1
                                    ? Colors.white
                                    : PawmartColors.ink,
                              ),
                              onSelected: (_) => setState(() {
                                if (_petType != item.$1) _breed.clear();
                                _petType = item.$1;
                              }),
                            ),
                        ],
                      ),
                      _title('Giống thú cưng'),
                      TextFormField(
                        key: const ValueKey('filter-breed'),
                        controller: _breed,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Giống',
                          hintText: 'Ví dụ: Poodle, mèo Anh…',
                          counterText: '',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Chỉ tìm sản phẩm có nhắc đến giống trong tên hoặc mô tả.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: PawmartColors.muted,
                          ),
                        ),
                      ),
                      _title('Loại sản phẩm'),
                      DropdownButtonFormField<int>(
                        key: ValueKey(_categoryId),
                        initialValue: _categoryId ?? 0,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 0,
                            child: Text('Tất cả loại sản phẩm'),
                          ),
                          for (final category in widget.categories)
                            DropdownMenuItem(
                              value: category.categoryId,
                              child: Text(
                                displayCategoryName(category.categoryName),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(
                          () => _categoryId = value == 0 ? null : value,
                        ),
                      ),
                      _title('Khoảng giá (đ)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final range in const [
                            ('Tất cả giá', '', ''),
                            ('Đến 100.000đ', '', '100000'),
                            ('100.000–300.000đ', '100000', '300000'),
                            ('300.000–500.000đ', '300000', '500000'),
                            ('Từ 500.000đ', '500000', ''),
                          ])
                            ChoiceChip(
                              label: Text(range.$1),
                              selected:
                                  _minimum.text == range.$2 &&
                                  _maximum.text == range.$3,
                              selectedColor: PawmartColors.greenPale,
                              labelStyle: const TextStyle(
                                fontFamily: 'Roboto',
                                color: PawmartColors.greenDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (_) => setState(() {
                                _minimum.text = range.$2;
                                _maximum.text = range.$3;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('filter-min-price'),
                              controller: _minimum,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Giá từ',
                                hintText: 'Không giới hạn',
                                suffixText: 'đ',
                              ),
                              validator: (text) =>
                                  text!.isNotEmpty && int.tryParse(text) == null
                                  ? 'Giá không hợp lệ'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const ValueKey('filter-max-price'),
                              controller: _maximum,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Giá đến',
                                hintText: 'Không giới hạn',
                                suffixText: 'đ',
                              ),
                              validator: (text) {
                                if (text!.isEmpty) return null;
                                final maximum = int.tryParse(text);
                                if (maximum == null) return 'Giá không hợp lệ';
                                final minimum = int.tryParse(_minimum.text);
                                return minimum != null && maximum < minimum
                                    ? 'Phải ≥ giá từ'
                                    : null;
                              },
                            ),
                          ),
                        ],
                      ),
                      _title('Thương hiệu'),
                      TextFormField(
                        key: const ValueKey('filter-brand'),
                        controller: _brand,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Tên thương hiệu',
                          hintText: 'Ví dụ: Royal Canin',
                          counterText: '',
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 14),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Chỉ xem hàng còn bán',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Sản phẩm đang mở bán và còn tồn kho.',
                        ),
                        value: _inStock,
                        onChanged: (value) => setState(() => _inStock = value),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: PawmartColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Đặt lại'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _apply,
                        child: const Text('Áp dụng bộ lọc'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
