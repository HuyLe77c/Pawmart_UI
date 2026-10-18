class PetProfile {
  const PetProfile({
    required this.petId,
    required this.petName,
    required this.petType,
    this.breed,
    this.ageMonths,
    this.weightKg,
    this.specialNotes,
    this.imageUrl,
  });

  final int petId;
  final String petName;
  final String petType;
  final String? breed;
  final int? ageMonths;
  final double? weightKg;
  final String? specialNotes;
  final String? imageUrl;

  factory PetProfile.fromJson(Map<String, dynamic> json) => PetProfile(
    petId: json['petId'] as int,
    petName: json['petName'] as String,
    petType: json['petType'] as String,
    breed: json['breed'] as String?,
    ageMonths: json['ageMonths'] as int?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    specialNotes: json['specialNotes'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );
}
