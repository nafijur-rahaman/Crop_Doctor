import 'package:flutter/material.dart';
import '../models/history_item.dart';

class ScanPrediction {
  const ScanPrediction({
    required this.crop,
    this.disease,
    required this.confidence,
    required this.status,
    this.message,
  });

  final String crop;
  final String? disease;
  final double confidence;

  /// 'ok' | 'not_a_plant' | 'crop_mismatch' | 'low_confidence'
  final String status;
  final String? message;

  factory ScanPrediction.fromJson(Map<String, dynamic> json) {
    return ScanPrediction(
      crop: (json['crop'] as String?) ?? '',
      disease: json['disease'] as String?,
      confidence: ((json['confidence'] as num?) ?? 0).toDouble(),
      status: (json['status'] as String?) ?? 'ok',
      message: json['message'] as String?,
    );
  }
}

class ScanSolution {
  const ScanSolution({
    required this.organicSolution,
    required this.chemicalSolution,
    this.preventionTips,
  });

  final String organicSolution;
  final String chemicalSolution;
  final String? preventionTips;

  List<RecommendationAction> toActions() {
    final actions = <RecommendationAction>[];
    if (organicSolution.isNotEmpty) {
      actions.add(RecommendationAction(
        icon: Icons.eco_outlined,
        title: 'Organic Treatment',
        description: organicSolution,
      ));
    }
    if (chemicalSolution.isNotEmpty) {
      actions.add(RecommendationAction(
        icon: Icons.science_outlined,
        title: 'Chemical Treatment',
        description: chemicalSolution,
      ));
    }
    if (preventionTips != null && preventionTips!.isNotEmpty) {
      actions.add(RecommendationAction(
        icon: Icons.shield_outlined,
        title: 'Prevention Tips',
        description: preventionTips!,
      ));
    }
    return actions;
  }

  factory ScanSolution.fromJson(Map<String, dynamic> json) {
    return ScanSolution(
      organicSolution: (json['organic_solution'] as String?) ?? '',
      chemicalSolution: (json['chemical_solution'] as String?) ?? '',
      preventionTips: json['prevention_tips'] as String?,
    );
  }
}

class ScanResult {
  const ScanResult({required this.prediction, this.solution});

  final ScanPrediction prediction;
  final ScanSolution? solution;

  bool get isOk => prediction.status == 'ok';

  bool get isHealthy =>
      prediction.disease == null ||
      prediction.disease!.toLowerCase().contains('healthy');

  String get diseaseName => prediction.disease ?? 'Unknown';

  String get confidencePercent =>
      '${(prediction.confidence).toStringAsFixed(1)}%';

  Color get statusColor {
    if (isHealthy) return Colors.green;
    if (prediction.confidence >= 0.8) return Colors.red;
    return Colors.orange;
  }

  List<RecommendationAction> get actions =>
      solution?.toActions() ?? const [];

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      prediction: ScanPrediction.fromJson(
        (json['prediction'] as Map<String, dynamic>?) ?? {},
      ),
      solution: json['solution'] != null
          ? ScanSolution.fromJson(json['solution'] as Map<String, dynamic>)
          : null,
    );
  }
}
