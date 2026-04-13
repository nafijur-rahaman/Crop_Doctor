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
    this.scientificName = '',
    this.matchPercentage = '0%',
    this.imageBytes,
    this.actions = const [],
  });

  final String title;
  final String time;
  final String icon;
  final Color statusColor;
  final String scientificName;
  final String matchPercentage;
  final Uint8List? imageBytes;
  final List<RecommendationAction> actions;
}
