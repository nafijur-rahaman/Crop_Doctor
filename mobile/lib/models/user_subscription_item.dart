import 'subscription_plan.dart';

class UserSubscriptionItem {
  const UserSubscriptionItem({
    required this.id,
    required this.transactionId,
    required this.status,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
    required this.plan,
  });

  final int id;
  final String transactionId;
  final String status;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String createdAt;
  final SubscriptionPlan plan;

  factory UserSubscriptionItem.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionItem(
      id: (json['id'] as num).toInt(),
      transactionId: (json['transaction_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      isActive: (json['is_active'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
      plan: SubscriptionPlan.fromJson(
        (json['plan'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

