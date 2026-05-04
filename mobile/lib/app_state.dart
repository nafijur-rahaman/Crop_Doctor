import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'models/forum_post.dart';
import 'models/forum_reply.dart';
import 'models/history_item.dart';
import 'models/user_profile.dart';

class AgroAppState extends ChangeNotifier {
  // ── Auth state ──────────────────────────────────────────────────────────────
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  void setProfile(UserProfile p) {
    _profile = p;
    notifyListeners();
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }

  // ── Forum state (live API) ──────────────────────────────────────────────────
  final List<ForumPost> _forumPosts = [];

  List<ForumPost> get forumPosts => List<ForumPost>.unmodifiable(_forumPosts);

  void setForumPosts(List<ForumPost> posts) {
    _forumPosts
      ..clear()
      ..addAll(posts);
    notifyListeners();
  }

  void prependForumPost(ForumPost post) {
    _forumPosts.insert(0, post);
    notifyListeners();
  }

  void addReplyToPost(String postId, ForumReply reply) {
    final i = _forumPosts.indexWhere((p) => p.id == postId);
    if (i != -1) {
      _forumPosts[i] =
          _forumPosts[i].copyWith(replies: [..._forumPosts[i].replies, reply]);
      notifyListeners();
    }
  }

  void reactToReply(
    String postId,
    String replyId, {
    required bool isHelpful,
  }) {
    final pi = _forumPosts.indexWhere((p) => p.id == postId);
    if (pi == -1) return;
    final post = _forumPosts[pi];
    final ri = post.replies.indexWhere((r) => r.id == replyId);
    if (ri == -1) return;
    final reply = post.replies[ri];
    final updatedReplies = List<ForumReply>.from(post.replies);

    int helpful = reply.helpfulCount;
    int useless = reply.uselessCount;
    bool upvoted = reply.hasUpvoted;
    bool downvoted = reply.hasDownvoted;

    if (isHelpful) {
      if (upvoted) {
        helpful--;
        upvoted = false;
      } else {
        helpful++;
        upvoted = true;
        if (downvoted) {
          useless--;
          downvoted = false;
        }
      }
    } else {
      if (downvoted) {
        useless--;
        downvoted = false;
      } else {
        useless++;
        downvoted = true;
        if (upvoted) {
          helpful--;
          upvoted = false;
        }
      }
    }

    updatedReplies[ri] = reply.copyWith(
      helpfulCount: helpful,
      uselessCount: useless,
      hasUpvoted: upvoted,
      hasDownvoted: downvoted,
    );
    _forumPosts[pi] = post.copyWith(replies: updatedReplies);
    notifyListeners();
  }

  // ── History state (in-memory, populated from real scan results) ─────────────
  final List<HistoryItem> _historyItems = [];

  List<HistoryItem> get historyItems =>
      List<HistoryItem>.unmodifiable(_historyItems);

  void saveDiagnosisToHistory({
    required String title,
    required Color statusColor,
    String icon = 'T',
    String cropName = '',
    String scientificName = '',
    String matchPercentage = '0%',
    Uint8List? imageBytes,
    String? imageUrl,
    List<RecommendationAction> actions = const [],
  }) {
    _historyItems.insert(
      0,
      HistoryItem(
        title: title,
        time: 'Just now',
        icon: icon,
        statusColor: statusColor,
        cropName: cropName,
        scientificName: scientificName,
        matchPercentage: matchPercentage,
        imageBytes: imageBytes,
        imageUrl: imageUrl,
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
    final AgroAppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AgroAppScope>();
    assert(scope != null, 'AgroAppScope not found in context');
    return scope!.notifier!;
  }
}
