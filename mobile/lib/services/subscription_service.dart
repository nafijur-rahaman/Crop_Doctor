import '../models/subscription_plan.dart';
import 'api_client.dart';

class SubscriptionService {
  /// GET /api/subscriptions/admin/get-plans/
  /// NOTE: Although the path says 'admin', the view (AdminPlanManageView) 
  /// handles both listing plans (GET) and managing them. 
  /// Usually, a separate public endpoint would be better, but we'll use what's available.
  static Future<List<SubscriptionPlan>> getPlans() async {
    // The endpoint is /api/admin/get-plans/ (api/ prefix from main urls.py)
    final data = await ApiClient.get('/api/admin/get-plans/');
    final List list = data['_data'] as List? ?? [];
    return list.map((p) => SubscriptionPlan.fromJson(p as Map<String, dynamic>)).toList();
  }

  /// POST /api/subscriptions/create-subscription-payment/
  static Future<String> createPayment(int planId) async {
    final data = await ApiClient.post(
      '/api/subscriptions/create-subscription-payment/',
      {'plan_id': planId},
    );
    return (data['payment_url'] as String?) ?? '';
  }
}
