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
  });

  final String id;
  final String name;
  final String time;
  final String question;
  final String initials;
  final List<ForumReply> replies;
  final String icon;

  bool get hasExpertReply => replies.any((r) => r.isExpert);

  ForumPost copyWith({
    String? id,
    String? name,
    String? time,
    String? question,
    String? initials,
    List<ForumReply>? replies,
    String? icon,
  }) {
    return ForumPost(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      question: question ?? this.question,
      initials: initials ?? this.initials,
      replies: replies ?? this.replies,
      icon: icon ?? this.icon,
    );
  }
}
