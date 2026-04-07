import 'package:flutter/material.dart';

import 'models/forum_post.dart';
import 'models/history_item.dart';

class AgroAppState extends ChangeNotifier {
  final List<ForumPost> _forumPosts = <ForumPost>[
    const ForumPost(
      name: 'Alhanullah Sajib',
      time: '1 hr ago',
      question:
          'My wheat leaves are turning yellow at the tips. Is this nutrient deficiency or a disease?',
      initials: 'A',
      hasExpertReply: true,
      icon: 'W',
    ),
    const ForumPost(
      name: 'Vasha Quddus',
      time: '3 hrs ago',
      question:
          'Used copper fungicide 2 days ago but the tomato blight is spreading. What should I do next?',
      initials: 'V',
      hasExpertReply: false,
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
    bool hasExpertReply = false,
    String icon = 'Q',
  }) {
    _forumPosts.insert(
      0,
      ForumPost(
        name: name,
        time: 'Just now',
        question: question,
        initials: name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
        hasExpertReply: hasExpertReply,
        icon: icon,
      ),
    );
    notifyListeners();
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
