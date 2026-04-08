import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'models/forum_post.dart';
import 'models/forum_reply.dart';
import 'models/history_item.dart';

class AgroAppState extends ChangeNotifier {
  final List<ForumPost> _forumPosts = <ForumPost>[
    ForumPost(
      id: 'post_1',
      name: 'Alhanullah Sajib',
      time: '1 hr ago',
      question:
          'My wheat leaves are turning yellow at the tips. Is this nutrient deficiency or a disease?',
      initials: 'A',
      icon: 'W',
      replies: [
        const ForumReply(
          id: 'reply_1',
          name: 'Dr. Jane Smith',
          initials: 'J',
          time: '45 mins ago',
          content: 'This looks like early stages of Nitrogen deficiency. Apply a nitrogen-rich fertilizer and monitor for 3 days.',
          isExpert: true,
          helpfulCount: 12,
        ),
        const ForumReply(
          id: 'reply_2',
          name: 'Farmer Bob',
          initials: 'B',
          time: '30 mins ago',
          content: 'I had the same issue last season. Jane is correct, nitrogen fixed it for me.',
          helpfulCount: 3,
        ),
      ],
    ),
    const ForumPost(
      id: 'post_2',
      name: 'Vasha Quddus',
      time: '3 hrs ago',
      question:
          'Used copper fungicide 2 days ago but the tomato blight is spreading. What should I do next?',
      initials: 'V',
      icon: 'T',
    ),
  ];

  final List<HistoryItem> _historyItems = <HistoryItem>[
    const HistoryItem(
      title: 'Tomato Early Blight',
      time: '2 hours ago',
      icon: 'T',
      statusColor: Colors.red,
      scientificName: 'Fungal Infection - Alternaria solani',
      matchPercentage: '98%',
      actions: [
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
    ),
    const HistoryItem(
      title: 'Potato Late Blight',
      time: 'Yesterday',
      icon: 'P',
      statusColor: Colors.orange,
      scientificName: 'Oomycete - Phytophthora infestans',
      matchPercentage: '85%',
      actions: [
        RecommendationAction(
          icon: Icons.air,
          title: 'Improve air circulation',
          description: 'Ensure plants are adequately spaced to reduce moisture.',
        ),
        RecommendationAction(
          icon: Icons.science_outlined,
          title: 'Systemic Fungicide',
          description: 'Apply specialized late blight fungicides as soon as possible.',
        ),
      ],
    ),
    const HistoryItem(
      title: 'Healthy Corn',
      time: '3 days ago',
      icon: 'C',
      statusColor: Colors.green,
      scientificName: 'Zea mays',
      matchPercentage: '100%',
      actions: [
        RecommendationAction(
          icon: Icons.check_circle_outline,
          title: 'No issues detected',
          description: 'Your crop looks healthy! Continue your current maintenance schedule.',
        ),
      ],
    ),
    const HistoryItem(
      title: 'Wheat Rust',
      time: 'Oct 12',
      icon: 'W',
      statusColor: Colors.red,
      scientificName: 'Fungal Infection - Puccinia triticina',
      matchPercentage: '92%',
      actions: [
        RecommendationAction(
          icon: Icons.grass_outlined,
          title: 'Monitor surrounding fields',
          description: 'Rust spores can travel long distances via wind.',
        ),
        RecommendationAction(
          icon: Icons.medication_outlined,
          title: 'Targeted Sprays',
          description: 'Apply triazole or strobilurin based fungicides.',
        ),
      ],
    ),
  ];

  List<ForumPost> get forumPosts => List<ForumPost>.unmodifiable(_forumPosts);
  List<HistoryItem> get historyItems =>
      List<HistoryItem>.unmodifiable(_historyItems);

  void addForumPost({
    required String name,
    required String question,
    String icon = 'Q',
  }) {
    _forumPosts.insert(
      0,
      ForumPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        time: 'Just now',
        question: question,
        initials: name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        icon: icon,
      ),
    );
    notifyListeners();
  }

  void addReplyToPost(String postId, ForumReply reply) {
    final index = _forumPosts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final post = _forumPosts[index];
      _forumPosts[index] = post.copyWith(replies: [...post.replies, reply]);
      notifyListeners();
    }
  }

  void reactToReply(String postId, String replyId, {required bool isHelpful}) {
    final postIndex = _forumPosts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _forumPosts[postIndex];
      final replyIndex = post.replies.indexWhere((r) => r.id == replyId);
      if (replyIndex != -1) {
        final reply = post.replies[replyIndex];
        final updatedReplies = List<ForumReply>.from(post.replies);
        
        int newHelpfulCount = reply.helpfulCount;
        int newUselessCount = reply.uselessCount;
        bool newHasUpvoted = reply.hasUpvoted;
        bool newHasDownvoted = reply.hasDownvoted;

        if (isHelpful) {
          if (newHasUpvoted) {
            newHelpfulCount -= 1;
            newHasUpvoted = false;
          } else {
            newHelpfulCount += 1;
            newHasUpvoted = true;
            if (newHasDownvoted) {
              newUselessCount -= 1;
              newHasDownvoted = false;
            }
          }
        } else {
          if (newHasDownvoted) {
            newUselessCount -= 1;
            newHasDownvoted = false;
          } else {
            newUselessCount += 1;
            newHasDownvoted = true;
            if (newHasUpvoted) {
              newHelpfulCount -= 1;
              newHasUpvoted = false;
            }
          }
        }

        updatedReplies[replyIndex] = reply.copyWith(
          helpfulCount: newHelpfulCount,
          uselessCount: newUselessCount,
          hasUpvoted: newHasUpvoted,
          hasDownvoted: newHasDownvoted,
        );

        _forumPosts[postIndex] = post.copyWith(replies: updatedReplies);
        notifyListeners();
      }
    }
  }

  void saveDiagnosisToHistory({
    required String title,
    required Color statusColor,
    String icon = 'T',
    String scientificName = '',
    String matchPercentage = '0%',
    Uint8List? imageBytes,
    List<RecommendationAction> actions = const [],
  }) {
    _historyItems.insert(
      0,
      HistoryItem(
        title: title,
        time: 'Just now',
        icon: icon,
        statusColor: statusColor,
        scientificName: scientificName,
        matchPercentage: matchPercentage,
        imageBytes: imageBytes,
        actions: actions,
      ),
    );
    notifyListeners();
  }
}

class AgroAppScope extends InheritedNotifier<AgroAppState> {
  const AgroAppScope({
    super.key,
    required AgroAppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AgroAppState of(BuildContext context) {
    final AgroAppScope? scope = context
        .dependOnInheritedWidgetOfExactType<AgroAppScope>();
    assert(scope != null, 'AgroAppScope not found in context');
    return scope!.notifier!;
  }
}
