import '../models/subscription_plan.dart';
import '../models/subscription_payment_init.dart';
import '../core/constants/api_constants.dart';
import 'api_client.dart';

class SubscriptionService {
  /// GET /api/get-plans/
  static Future<List<SubscriptionPlan>> getPlans() async {
    final data = await ApiClient.get(kGetPlansUrl);
    final List list = (data['_data'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((p) => SubscriptionPlan.fromJson(p.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// POST /api/subscriptions/create-subscription-payment/
  static Future<SubscriptionPaymentInit> createPayment(int planId) async {
    final data =
        await ApiClient.post(kCreateSubscriptionPaymentUrl, {'plan_id': planId});
    return SubscriptionPaymentInit.fromJson(data);
  }
}
