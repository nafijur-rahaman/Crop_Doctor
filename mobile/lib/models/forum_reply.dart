class ForumReply {
  const ForumReply({
    required this.id,
    required this.name,
    required this.initials,
    required this.time,
    required this.content,
    this.isExpert = false,
    this.helpfulCount = 0,
    this.uselessCount = 0,
    this.hasUpvoted = false,
    this.hasDownvoted = false,
    this.userId,
    this.userRole,
    this.backendId,
  });

  final String id;
  final String name;
  final String initials;
  final String time;
  final String content;
  final bool isExpert;
  final int helpfulCount;

  /// Downvote count is local-only (backend doesn't store it).
  final int uselessCount;
  final bool hasUpvoted;
  final bool hasDownvoted;
  final int? userId;
  final String? userRole;

  /// Numeric PK for like/unlike API calls.
  final int? backendId;

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final user = (json['user'] as String?) ?? 'User';
    final createdAt = (json['created_at'] as String?) ?? '';
    return ForumReply(
      id: id.toString(),
      backendId: id,
      name: user,
      initials: user.isNotEmpty ? user[0].toUpperCase() : '?',
      time: _formatTime(createdAt),
      content: (json['text'] as String?) ?? '',
      isExpert: (json['is_expert'] as bool?) ?? false,
      helpfulCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt(),
      userRole: json['user_role'] as String?,
    );
  }

  static String _formatTime(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      final dt2 = DateTime.parse(iso).toLocal();
      return '${dt2.day}/${dt2.month}/${dt2.year}';
    } catch (_) {
      return iso;
    }
  }

  ForumReply copyWith({
    String? id,
    String? name,
    String? initials,
    String? time,
    String? content,
    bool? isExpert,
    int? helpfulCount,
    int? uselessCount,
    bool? hasUpvoted,
    bool? hasDownvoted,
    int? userId,
    String? userRole,
    int? backendId,
  }) {
    return ForumReply(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      time: time ?? this.time,
      content: content ?? this.content,
      isExpert: isExpert ?? this.isExpert,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      uselessCount: uselessCount ?? this.uselessCount,
      hasUpvoted: hasUpvoted ?? this.hasUpvoted,
      hasDownvoted: hasDownvoted ?? this.hasDownvoted,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      backendId: backendId ?? this.backendId,
    );
  }
}
