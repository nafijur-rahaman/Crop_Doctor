import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/forum_service.dart';
import '../widgets/custom_notification.dart';
import 'my_questions_screen.dart';
import 'question_detail_screen.dart';
import 'subscription_screen.dart';

/// Crops for the question form selector.
const List<String> _kCrops = [
  'Tomato', 'Potato', 'Corn', 'Wheat', 'Rice',
  'Apple', 'Grape', 'Pepper', 'Other',
];

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key, this.initialDraftQuestion});

  final String? initialDraftQuestion;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  bool _openedInitialDraft = false;
  final Set<String> _expandedPostIds = {};
  bool _loadingPosts = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_openedInitialDraft &&
        widget.initialDraftQuestion != null &&
        widget.initialDraftQuestion!.trim().isNotEmpty) {
      _openedInitialDraft = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openQuestionForm(prefilled: widget.initialDraftQuestion);
      });
    }
  }

  Future<void> _loadQuestions() async {
    if (!AuthService.isAuthenticated) {
      setState(() => _loadingPosts = false);
      return;
    }
    setState(() {
      _loadingPosts = true;
      _loadError = null;
    });
    try {
      final posts = await ForumService.getAllQuestions();
      if (!mounted) return;
      AgroAppScope.of(context).setForumPosts(posts);
      setState(() => _loadingPosts = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPosts = false;
        _loadError = 'Network error. Could not load questions.';
      });
    }
  }

  // ── Question form ────────────────────────────────────────────────────────────

  Future<void> _openQuestionForm({String? prefilled}) async {
    if (!AuthService.isAuthenticated) {
      CustomNotification.show(context, 'Please log in to post a question.');
      return;
    }
    if (!AuthService.isPremiumUser) {
      _showPremiumGate();
      return;
    }

    final questionCtrl = TextEditingController(text: prefilled ?? '');
    String selectedCrop = _kCrops.first;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
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
                  // Crop dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCrop,
                    decoration: InputDecoration(
                      labelText: 'Crop',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    items: _kCrops
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => selectedCrop = v ?? selectedCrop),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: questionCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Your Question',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final q = questionCtrl.text.trim();
                        if (q.isEmpty) {
                          CustomNotification.show(
                              ctx, 'Please enter your question.');
                          return;
                        }
                        Navigator.pop(ctx, true);
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
        });
      },
    );

    final question = questionCtrl.text.trim();
    questionCtrl.dispose();

    if (submitted != true || !mounted || question.isEmpty) return;

    try {
      final post = await ForumService.createQuestion(
        title: question,
        crop: selectedCrop,
      );
      if (!mounted) return;
      AgroAppScope.of(context).prependForumPost(post);
      CustomNotification.show(context, 'Question posted successfully!');
    } on ApiException catch (e) {
      if (mounted) CustomNotification.show(context, e.message);
    } catch (_) {
      if (mounted) {
        CustomNotification.show(context, 'Could not post question. Try again.');
      }
    }
  }

  // ── Reply form ───────────────────────────────────────────────────────────────

  Future<void> _openReplyForm(ForumPost post) async {
    if (!AuthService.isAuthenticated) {
      CustomNotification.show(context, 'Please log in to reply.');
      return;
    }
    if (!AuthService.isPremiumUser) {
      _showPremiumGate();
      return;
    }
    if (post.backendId == null) {
      CustomNotification.show(context, 'Cannot reply to this post.');
      return;
    }

    final replyCtrl = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
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
                controller: replyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Your Reply',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (replyCtrl.text.trim().isEmpty) {
                      CustomNotification.show(ctx, 'Please write a reply.');
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: const Text('Submit Reply',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final replyText = replyCtrl.text.trim();
    replyCtrl.dispose();

    if (submitted != true || !mounted || replyText.isEmpty) return;

    try {
      final reply = await ForumService.createAnswer(
        questionId: post.backendId!,
        text: replyText,
      );
      if (!mounted) return;
      AgroAppScope.of(context).addReplyToPost(post.id, reply);
      setState(() => _expandedPostIds.add(post.id));
      CustomNotification.show(context, 'Reply posted!');
    } on ApiException catch (e) {
      if (mounted) CustomNotification.show(context, e.message);
    } catch (_) {
      if (mounted) {
        CustomNotification.show(context, 'Could not post reply. Try again.');
      }
    }
  }

  void _toggleLike(ForumPost post, ForumReply reply) async {
    // Optimistic local toggle first
    AgroAppScope.of(context)
        .reactToReply(post.id, reply.id, isHelpful: true);

    if (reply.backendId != null) {
      try {
        await ForumService.toggleLike(reply.backendId!);
      } catch (_) {
        // Revert on failure
        if (mounted) {
          AgroAppScope.of(context)
              .reactToReply(post.id, reply.id, isHelpful: true);
        }
      }
    }
  }

  void _showPremiumGate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF00A36C)),
            SizedBox(width: 10),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'The Expert Forum is available for Premium users. Upgrade your account to ask questions and get expert advice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C)),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final posts = AgroAppScope.of(context).forumPosts;

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
        actions: [
          if (!_loadingPosts)
            IconButton(
              icon: const Icon(Icons.person_outline, color: Color(0xFF0A191E)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyQuestionsScreen()),
                );
              },
            ),
          if (!_loadingPosts)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF0A191E)),
              onPressed: _loadQuestions,
            ),
        ],
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _openQuestionForm,
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF00A36C)),
              label: const Text(
                'Ask a Question',
                style: TextStyle(
                    color: Color(0xFF00A36C), fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                side: const BorderSide(color: Color(0xFF00A36C), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildBody(posts)),
        ],
      ),
    );
  }

  Widget _buildBody(List<ForumPost> posts) {
    // Not logged in
    if (!AuthService.isAuthenticated) {
      return const _GateView(
        icon: Icons.login_outlined,
        title: 'Login Required',
        subtitle:
            'Please log in to view and participate in the Expert Forum.',
      );
    }
    // Not premium
    if (!AuthService.isPremiumUser) {
      return const _GateView(
        icon: Icons.lock_outline,
        title: 'Premium Feature',
        subtitle:
            'Upgrade to a Premium plan to access the Expert Forum and get help from certified agronomists.',
      );
    }
    if (_loadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00A36C)),
      );
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(_loadError!,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C)),
            ),
          ],
        ),
      );
    }
    if (posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('No questions yet.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text('Be the first to ask!',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: posts.length + 1,
      itemBuilder: (_, i) {
        if (i == posts.length) return const SizedBox(height: 80);
        return _buildForumCard(posts[i]);
      },
    );
  }

  Widget _buildForumCard(ForumPost post) {
    final isExpanded =
        post.hasExpertReply || _expandedPostIds.contains(post.id);

    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: () {
        if (post.backendId == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(questionId: post.backendId!),
          ),
        );
      },
      child: Container(
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
                      color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(post.time,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              if (post.crop != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.crop!,
                    style: const TextStyle(
                        color: Color(0xFF00A36C), fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.question,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF0A191E), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _openReplyForm(post),
                icon: const Icon(Icons.reply,
                    size: 18, color: Color(0xFF00A36C)),
                label: const Text('Reply',
                    style: TextStyle(color: Color(0xFF00A36C))),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              if (!isExpanded && post.replies.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      setState(() => _expandedPostIds.add(post.id)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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
          if (isExpanded && post.replies.isNotEmpty)
            ...post.replies.map((r) => _buildReplyItem(post, r)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyItem(ForumPost post, ForumReply reply) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 8),
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
                  child: Text(reply.initials,
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text(reply.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 8),
                Text(reply.time,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
            if (reply.isExpert)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 10, color: Color(0xFF00A36C)),
                      SizedBox(width: 4),
                      Text('Expert Reply',
                          style: TextStyle(
                              color: Color(0xFF00A36C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(reply.content,
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleLike(post, reply),
                    icon: Icon(
                      reply.hasUpvoted
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      size: 14,
                      color: reply.hasUpvoted
                          ? const Color(0xFF00A36C)
                          : Colors.grey,
                    ),
                    label: Text(
                      reply.helpfulCount > 0
                          ? '${reply.helpfulCount} Helpful'
                          : 'Helpful',
                      style: TextStyle(
                        color: reply.hasUpvoted
                            ? const Color(0xFF00A36C)
                            : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => AgroAppScope.of(context)
                        .reactToReply(post.id, reply.id, isHelpful: false),
                    icon: Icon(
                      reply.hasDownvoted
                          ? Icons.thumb_down_alt
                          : Icons.thumb_down_alt_outlined,
                      size: 14,
                      color: reply.hasDownvoted
                          ? Colors.redAccent
                          : Colors.grey,
                    ),
                    label: Text(
                      reply.uselessCount > 0
                          ? '${reply.uselessCount} Useless'
                          : 'Useless',
                      style: TextStyle(
                        color: reply.hasDownvoted
                            ? Colors.redAccent
                            : Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GateView extends StatelessWidget {
  const _GateView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFF00A36C)),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A191E))),
            const SizedBox(height: 10),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
