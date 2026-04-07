import 'package:flutter/material.dart';

class HistoryItem {
  const HistoryItem({
    required this.title,
    required this.time,
    required this.icon,
    required this.statusColor,
  });

  final String title;
  final String time;
  final String icon;
  final Color statusColor;
}
