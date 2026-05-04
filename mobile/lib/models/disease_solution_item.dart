class DiseaseSolutionItem {
  const DiseaseSolutionItem({
    required this.diseaseName,
    this.plantId,
    this.plantName,
    this.organic,
    this.chemical,
    this.tips,
    this.isAiGenerated,
  });

  final String diseaseName;
  final int? plantId;
  final String? plantName;
  final String? organic;
  final String? chemical;
  final String? tips;
  final bool? isAiGenerated;

  factory DiseaseSolutionItem.fromJson(Map<String, dynamic> json) {
    final plant = (json['plant'] is Map) ? (json['plant'] as Map) : null;
    return DiseaseSolutionItem(
      diseaseName: (json['disease_name'] as String?) ?? '',
      plantId: plant?['id'] is num ? (plant!['id'] as num).toInt() : null,
      plantName: plant?['name'] as String?,
      organic: json['organic'] as String?,
      chemical: json['chemical'] as String?,
      tips: json['tips'] as String?,
      isAiGenerated: json['is_ai_generated'] as bool?,
    );
  }
}

