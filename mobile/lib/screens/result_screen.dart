import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/custom_notification.dart';
import 'forum_screen.dart';

import '../models/history_item.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    this.imageBytes,
    this.diagnosisTitle = 'Tomato Early Blight',
    this.diagnosisColor = Colors.red,
    this.scientificName = 'Fungal Infection - Alternaria solani',
    this.matchPercentage = '98%',
    this.actions = const [
      RecommendationAction(
        icon: Icons.cut_outlined,
        title: 'Prune infected leaves',
        description: 'Remove and destroy all leaves showing spots to prevent spreading.',
      ),
      RecommendationAction(
        icon: Icons.opacity_outlined,
        title: 'Apply Copper Fungicide',
        description: 'Spray a copper-based fungicide every 7-10 days.',
      ),
      RecommendationAction(
        icon: Icons.water_drop_outlined,
        title: 'Water at the base',
        description: 'Avoid overhead watering to keep foliage dry.',
      ),
    ],
    this.isHistoryView = false,
  });

  final Uint8List? imageBytes;
  final String diagnosisTitle;
  final Color diagnosisColor;
  final String scientificName;
  final String matchPercentage;
  final List<RecommendationAction> actions;
  final bool isHistoryView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analysis Result',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(25),
                    image: imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: NetworkImage(
                              'https://via.placeholder.com/400x250',
                            ),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A36C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      matchPercentage.contains('%') ? matchPercentage : '$matchPercentage% Match',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: Text(
                    diagnosisTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: diagnosisColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: diagnosisColor,
                  ),
                ),
              ],
            ),
            Text(
              scientificName,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),
            const Text(
              'Recommended Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...actions.map((action) => _buildActionItem(
              context,
              action.icon,
              action.title,
              action.description,
            )),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A191E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need more help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Talk to a certified agronomist now.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForumScreen(
                            initialDraftQuestion:
                                'I need help with Tomato Early Blight on my crop. What should I do next?',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C),
                    ),
                    child: const Text('Chat'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: isHistoryView ? null : Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            AgroAppScope.of(context).saveDiagnosisToHistory(
              title: diagnosisTitle,
              statusColor: diagnosisColor,
              scientificName: scientificName,
              matchPercentage: matchPercentage,
              imageBytes: imageBytes,
              actions: actions,
            );
            CustomNotification.show(context, 'Saved to history.');
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A36C),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Save to History',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00A36C)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
