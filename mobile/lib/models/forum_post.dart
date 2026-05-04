import 'forum_reply.dart';

class ForumPost {
  const ForumPost({
    required this.id,
    required this.name,
    required this.time,
    required this.question,
    required this.initials,
    this.replies = const [],
    required this.icon,
    this.backendId,
    this.crop,
    this.userId,
    this.userRole,
  });

  final String id;
  final String name;
  final String time;
  final String question;
  final String initials;
  final List<ForumReply> replies;
  final String icon;

  /// The numeric PK from the backend, needed when posting answers.
  final int? backendId;
  final String? crop;
  final int? userId;
  final String? userRole;

  bool get hasExpertReply => replies.any((r) => r.isExpert);

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num).toInt();
    final user = (json['user'] as String?) ?? 'User';
    final title = (json['title'] as String?) ?? '';
    final description = (json['description'] as String?) ?? '';
    final crop = (json['crop'] as String?) ?? '';
    final createdAt = (json['created_at'] as String?) ?? '';
    final answers = (json['answers'] as List?) ?? [];

    return ForumPost(
      id: id.toString(),
      backendId: id,
      name: user,
      time: _formatTime(createdAt),
      question: description.isNotEmpty ? description : title,
      initials: user.isNotEmpty ? user[0].toUpperCase() : '?',
      icon: crop.isNotEmpty ? crop[0].toUpperCase() : 'Q',
      crop: crop,
      userId: (json['user_id'] as num?)?.toInt(),
      userRole: json['user_role'] as String?,
      replies: answers
          .map((a) => ForumReply.fromJson(a as Map<String, dynamic>))
          .toList(),
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
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  ForumPost copyWith({
    String? id,
    String? name,
    String? time,
    String? question,
    String? initials,
    List<ForumReply>? replies,
    String? icon,
    int? backendId,
    String? crop,
    int? userId,
    String? userRole,
  }) {
    return ForumPost(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      question: question ?? this.question,
      initials: initials ?? this.initials,
      replies: replies ?? this.replies,
      icon: icon ?? this.icon,
      backendId: backendId ?? this.backendId,
      crop: crop ?? this.crop,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
    );
  }
}
