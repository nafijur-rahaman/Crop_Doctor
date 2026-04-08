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
    ),
    const HistoryItem(
      title: 'Healthy Potato',
      time: 'Yesterday',
      icon: 'P',
      statusColor: Colors.green,
    ),
    const HistoryItem(
      title: 'Apple Scab',
      time: 'Oct 12',
      icon: 'A',
      statusColor: Colors.orange,
    ),
    const HistoryItem(
      title: 'Powdery Mildew',
      time: 'Sept 28',
      icon: 'M',
      statusColor: Colors.red,
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
  }) {
    _historyItems.insert(
      0,
      HistoryItem(
        title: title,
        time: 'Just now',
        icon: icon,
        statusColor: statusColor,
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
