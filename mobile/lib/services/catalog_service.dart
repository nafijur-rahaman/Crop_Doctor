import '../core/constants/api_constants.dart';
import '../models/disease_solution_item.dart';
import '../models/plant.dart';
import 'api_client.dart';

class CatalogService {
  static Future<List<Plant>> fetchPlants() async {
    final data = await ApiClient.get(kCatalogPlantsUrl);
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Plant.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<List<DiseaseSolutionItem>> fetchSolutions({int? plantId}) async {
    final path = plantId == null
        ? kCatalogSolutionsUrl
        : '$kCatalogSolutionsUrl?plant_id=$plantId';
    final data = await ApiClient.get(path);
    final raw = data['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => DiseaseSolutionItem.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
