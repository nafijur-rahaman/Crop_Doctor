import 'dart:typed_data';
import 'package:flutter/material.dart';

class RecommendationAction {
  const RecommendationAction({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class HistoryItem {
  const HistoryItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.statusColor,
    this.cropName = '',
    this.scientificName = '',
    this.matchPercentage = '0%',
    this.imageBytes,
    this.imageUrl,
    this.actions = const [],
  });

  final String title;
  final String time;
  final String icon;
  final Color statusColor;
  final String cropName;
  final String scientificName;
  final String matchPercentage;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final List<RecommendationAction> actions;
}
