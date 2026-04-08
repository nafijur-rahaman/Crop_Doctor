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
  });

  final String id;
  final String name;
  final String initials;
  final String time;
  final String content;
  final bool isExpert;
  final int helpfulCount;
  final int uselessCount;
  final bool hasUpvoted;
  final bool hasDownvoted;

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
    );
  }
}

