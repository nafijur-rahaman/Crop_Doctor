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

  static double _parsePrice(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?) ?? '';
    final durationDays = (json['duration_days'] as num?)?.toInt() ?? 30;
    final description = (json['description'] as String?) ??
        (name.isNotEmpty
            ? 'Access premium features for $durationDays days.'
            : 'Access premium features.');
    return SubscriptionPlan(
      id: (json['id'] as num).toInt(),
      name: name,
      description: description,
      price: _parsePrice(json['price']),
      durationDays: durationDays,
    );
  }
}
