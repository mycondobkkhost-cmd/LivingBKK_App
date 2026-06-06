import '../l10n/app_strings.dart';

/// นโยบายเลี้ยงสัตว์ — เก็บใน `listings.pet_policy` (jsonb)
class ListingPetPolicyInput {
  const ListingPetPolicyInput({
    this.allowed = false,
    this.maxWeightKg,
    this.maxCount,
    this.dogsAllowed = false,
    this.catsAllowed = false,
  });

  final bool allowed;
  final double? maxWeightKg;
  final int? maxCount;
  final bool dogsAllowed;
  final bool catsAllowed;

  ListingPetPolicyInput copyWith({
    bool? allowed,
    double? maxWeightKg,
    bool clearMaxWeight = false,
    int? maxCount,
    bool clearMaxCount = false,
    bool? dogsAllowed,
    bool? catsAllowed,
  }) {
    return ListingPetPolicyInput(
      allowed: allowed ?? this.allowed,
      maxWeightKg: clearMaxWeight ? null : (maxWeightKg ?? this.maxWeightKg),
      maxCount: clearMaxCount ? null : (maxCount ?? this.maxCount),
      dogsAllowed: dogsAllowed ?? this.dogsAllowed,
      catsAllowed: catsAllowed ?? this.catsAllowed,
    );
  }

  factory ListingPetPolicyInput.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ListingPetPolicyInput();
    return ListingPetPolicyInput(
      allowed: json['allowed'] as bool? ?? false,
      maxWeightKg: (json['max_weight_kg'] as num?)?.toDouble(),
      maxCount: (json['max_count'] as num?)?.toInt(),
      dogsAllowed: json['dogs_allowed'] as bool? ?? false,
      catsAllowed: json['cats_allowed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'allowed': allowed,
        if (maxWeightKg != null) 'max_weight_kg': maxWeightKg,
        if (maxCount != null) 'max_count': maxCount,
        'dogs_allowed': dogsAllowed,
        'cats_allowed': catsAllowed,
      };

  Map<String, dynamic> toDbFields() => {
        'pet_policy': toJson(),
        'pet_allowed': allowed,
      };

  bool get typesValidWhenAllowed => !allowed || dogsAllowed || catsAllowed;

  String summary(AppStrings s) {
    if (!allowed) return s.petPolicyNotAllowed;
    final types = <String>[];
    if (dogsAllowed) types.add(s.petPolicyDogs);
    if (catsAllowed) types.add(s.petPolicyCats);
    final typeStr = types.isEmpty ? '—' : types.join(', ');
    final weight = maxWeightKg != null
        ? s.petPolicyMaxWeight(maxWeightKg!.toStringAsFixed(0))
        : s.petPolicyWeightUnlimited;
    final count = maxCount != null
        ? s.petPolicyMaxCount(maxCount!)
        : s.petPolicyCountUnlimited;
    return '${s.petPolicyAllowed} · $typeStr · $weight · $count';
  }
}
