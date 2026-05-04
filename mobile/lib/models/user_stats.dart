class UserStats {
  const UserStats({
    required this.totalScans,
    required this.totalPayments,
    this.activeSubscriptionPlan,
    this.activeSubscriptionStatus,
    this.activeSubscriptionEndDate,
  });

  final int totalScans;
  final int totalPayments;
  final String? activeSubscriptionPlan;
  final String? activeSubscriptionStatus;
  final String? activeSubscriptionEndDate;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final active = (json['active_subscription'] is Map)
        ? (json['active_subscription'] as Map).cast<String, dynamic>()
        : null;
    return UserStats(
      totalScans: (json['total_scans'] as num?)?.toInt() ?? 0,
      totalPayments: (json['total_payments'] as num?)?.toInt() ?? 0,
      activeSubscriptionPlan: active?['plan'] as String?,
      activeSubscriptionStatus: active?['status'] as String?,
      activeSubscriptionEndDate: active?['end_date'] as String?,
    );
  }
}

