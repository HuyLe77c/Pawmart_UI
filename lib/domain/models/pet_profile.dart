class PetProfile {
  const PetProfile({
    required this.petId,
    required this.petName,
    required this.petType,
    this.breed,
    this.ageMonths,
    this.weightKg,
    this.specialNotes,
    this.bodySize,
    this.activityLevel,
    this.bodyConditionScore,
    this.feedingHabits,
    this.foodPreferences,
    this.imageUrl,
  });

  final int petId;
  final String petName;
  final String petType;
  final String? breed;
  final int? ageMonths;
  final double? weightKg;
  final String? specialNotes;
  final String? bodySize;
  final String? activityLevel;
  final int? bodyConditionScore;
  final String? feedingHabits;
  final String? foodPreferences;
  final String? imageUrl;

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
    petId: json['petId'] as int,
    petName: json['petName'] as String,
    petType: json['petType'] as String,
    breed: json['breed'] as String?,
    ageMonths: json['ageMonths'] as int?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    specialNotes: json['specialNotes'] as String?,
    bodySize: json['bodySize'] as String?,
    activityLevel: json['activityLevel'] as String?,
    bodyConditionScore: json['bodyConditionScore'] as int?,
    feedingHabits: json['feedingHabits'] as String?,
    foodPreferences: json['foodPreferences'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );
}
