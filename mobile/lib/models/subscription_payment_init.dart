class SubscriptionPaymentInit {
  const SubscriptionPaymentInit({
    required this.paymentUrl,
    required this.transactionId,
  });

  final String paymentUrl;
  final String transactionId;

  factory SubscriptionPaymentInit.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentInit(
      paymentUrl: (json['payment_url'] as String?) ?? '',
      transactionId: (json['transaction_id'] as String?) ?? '',
    );
  }
}

