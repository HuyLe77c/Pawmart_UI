String displayCategoryName(String name) => switch (name.trim().toLowerCase()) {
  'dog food' => 'Thức ăn cho chó',
  'cat food' => 'Thức ăn cho mèo',
  'treats' => 'Bánh thưởng',
  'accessories' => 'Phụ kiện',
  _ => name,
};
