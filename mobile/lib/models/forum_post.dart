class ForumPost {
  const ForumPost({
    required this.name,
    required this.time,
    required this.question,
    required this.initials,
    required this.hasExpertReply,
    required this.icon,
  });

  final String name;
  final String time;
  final String question;
  final String initials;
  final bool hasExpertReply;
  final String icon;
}
