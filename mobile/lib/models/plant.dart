class Plant {
  const Plant({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
    );
  }
}

