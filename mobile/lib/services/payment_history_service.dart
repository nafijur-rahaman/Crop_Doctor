import '../core/constants/api_constants.dart';
import '../models/user_subscription_item.dart';
import 'api_client.dart';

class PaymentHistoryService {
  static Future<List<UserSubscriptionItem>> listMine() async {
    final data = await ApiClient.get(kMySubscriptionsUrl);
    final raw = data['subscriptions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => UserSubscriptionItem.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<UserSubscriptionItem> getMine(int id) async {
    final data = await ApiClient.get('$kMySubscriptionsUrl$id/');
    final sub = (data['subscription'] as Map<String, dynamic>?) ?? const {};
    return UserSubscriptionItem.fromJson(sub);
  }
}

