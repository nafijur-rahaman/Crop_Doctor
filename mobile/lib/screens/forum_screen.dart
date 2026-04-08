import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import '../widgets/custom_notification.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key, this.initialDraftQuestion});

  final String? initialDraftQuestion;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  bool _openedInitialDraft = false;
  final Set<String> _expandedPostIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_openedInitialDraft &&
        widget.initialDraftQuestion != null &&
        widget.initialDraftQuestion!.trim().isNotEmpty) {
      _openedInitialDraft = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openQuestionForm(prefilledQuestion: widget.initialDraftQuestion);
        }
      });
    }
  }

  Future<void> _openQuestionForm({String? prefilledQuestion}) async {
    final TextEditingController nameController = TextEditingController(
      text: 'Tanjid Nafis',
    );
    final TextEditingController questionController = TextEditingController(
      text: prefilledQuestion ?? '',
    );

    final Map<String, String>? result =
        await showModalBottomSheet<Map<String, String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ask a Question',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A191E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: questionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Question',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          final String question = questionController.text
                              .trim();

                          if (name.isEmpty || question.isEmpty) {
                            CustomNotification.show(
                              context,
                              'Please fill out both fields.',
                            );
                            return;
                          }

                          Navigator.pop(context, <String, String>{
                            'name': name,
                            'question': question,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A36C),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text(
                          'Submit Question',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

    nameController.dispose();
    questionController.dispose();

    if (result == null || !mounted) {
      return;
    }

    AgroAppScope.of(
      context,
    ).addForumPost(name: result['name']!, question: result['question']!);

    CustomNotification.show(context, 'Your question was added locally.');
  }

  Future<void> _openReplyForm(ForumPost post) async {
    final TextEditingController nameController = TextEditingController(
      text: 'Tanjid Nafis',
    );
    final TextEditingController replyController = TextEditingController();

    final Map<String, String>? result =
        await showModalBottomSheet<Map<String, String>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Write a Reply',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A191E),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: replyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Reply',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final String name = nameController.text.trim();
                          final String reply = replyController.text.trim();

                          if (name.isEmpty || reply.isEmpty) {
                            CustomNotification.show(
                              context,
                              'Please fill out both fields.',
                            );
                            return;
                          }

                          Navigator.pop(context, <String, String>{
                            'name': name,
                            'reply': reply,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A36C),
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text(
                          'Submit Reply',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

    nameController.dispose();
    replyController.dispose();

    if (result == null || !mounted) {
      return;
    }

    AgroAppScope.of(context).addReplyToPost(
      post.id,
      ForumReply(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        initials: result['name']!.isEmpty ? '?' : result['name']!.substring(0, 1).toUpperCase(),
        time: 'Just now',
        content: result['reply']!,
      ),
    );

    // Auto expand so the user sees their new reply
    setState(() {
      _expandedPostIds.add(post.id);
    });

    CustomNotification.show(context, 'Your reply was added.');
  }

  @override
  Widget build(BuildContext context) {
    final List<ForumPost> posts = AgroAppScope.of(context).forumPosts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Expert Forum',
          style: TextStyle(
            color: Color(0xFF0A191E),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Ask questions, get help from agronomists.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _openQuestionForm,
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF00A36C),
              ),
              label: const Text(
                'Ask a Question',
                style: TextStyle(
                  color: Color(0xFF00A36C),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Color(0xFF00A36C), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return const SizedBox(height: 80);
                }

                return _buildForumCard(posts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumCard(ForumPost post) {
    bool isExpanded = post.hasExpertReply || _expandedPostIds.contains(post.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[100],
                child: Text(
                  post.initials,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    post.time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            post.question,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0A191E),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openReplyForm(post),
                icon: const Icon(Icons.reply, size: 18, color: Color(0xFF00A36C)),
                label: const Text('Reply', style: TextStyle(color: Color(0xFF00A36C))),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (!isExpanded && post.replies.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedPostIds.add(post.id);
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View ${post.replies.length} Replies',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              if (isExpanded || post.replies.isEmpty)
                Text(
                  '${post.replies.length} Replies',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          if (isExpanded && post.replies.isNotEmpty) ...[
            const SizedBox(height: 5),
            ...post.replies.map((reply) => _buildReplyItem(post, reply)),
          ]
        ],
      ),
    );
  }

  Widget _buildReplyItem(ForumPost post, ForumReply reply) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, left: 10.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                  child: Text(
                    reply.initials,
                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reply.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  reply.time,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            if (reply.isExpert)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 10,
                        color: Color(0xFF00A36C),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Expert Reply',
                        style: TextStyle(
                          color: Color(0xFF00A36C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                 reply.content,
                 style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF0A191E)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      AgroAppScope.of(context).reactToReply(post.id, reply.id, isHelpful: true);
                    },
                    icon: Icon(
                      reply.hasUpvoted ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, 
                      size: 14, 
                      color: reply.hasUpvoted ? const Color(0xFF00A36C) : Colors.grey,
                    ),
                    label: Text(
                      '${reply.helpfulCount > 0 ? reply.helpfulCount : ""} Helpful'.trim(), 
                      style: TextStyle(
                        color: reply.hasUpvoted ? const Color(0xFF00A36C) : Colors.grey, 
                        fontSize: 11,
                        fontWeight: reply.hasUpvoted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {
                      AgroAppScope.of(context).reactToReply(post.id, reply.id, isHelpful: false);
                    },
                    icon: Icon(
                      reply.hasDownvoted ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined, 
                      size: 14, 
                      color: reply.hasDownvoted ? Colors.redAccent : Colors.grey,
                    ),
                    label: Text(
                      '${reply.uselessCount > 0 ? reply.uselessCount : ""} Useless'.trim(), 
                      style: TextStyle(
                        color: reply.hasDownvoted ? Colors.redAccent : Colors.grey, 
                        fontSize: 11,
                        fontWeight: reply.hasDownvoted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ]
              )
            )
          ],
        ),
      ),
    );
  }
}
