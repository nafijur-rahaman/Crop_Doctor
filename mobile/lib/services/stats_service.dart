import '../models/user_stats.dart';
import 'api_client.dart';

class StatsService {
  static Future<UserStats> getStats() async {
    final data = await ApiClient.get('/api/users/stats/');
    return UserStats.fromJson(data);
  }
}

