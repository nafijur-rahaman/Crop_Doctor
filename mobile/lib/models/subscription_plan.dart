class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationDays;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      price: ((json['price'] as num?) ?? 0).toDouble(),
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
    );
  }
}
