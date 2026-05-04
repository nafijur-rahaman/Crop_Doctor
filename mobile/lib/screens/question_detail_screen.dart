import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import '../services/api_client.dart';
import '../services/forum_service.dart';
import '../widgets/custom_notification.dart';
import '../app_state.dart';
import '../services/auth_service.dart';

class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final int questionId;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  bool _loading = true;
  String? _error;
  ForumPost? _post;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await ForumService.getQuestion(widget.questionId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load question.';
      });
    }
  }

  Future<void> _addReply() async {
    final post = _post;
    if (post == null || post.backendId == null) return;
    final int backendId = post.backendId!;
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Write an answer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Type your answer...',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A36C),
                  ),
                  child: const Text('Post'),
                ),
              )
            ],
          ),
        ),
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || text.isEmpty) return;

    try {
      final reply = await ForumService.createAnswer(
        questionId: backendId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        _post = _post!.copyWith(replies: [..._post!.replies, reply]);
      });
      CustomNotification.show(context, 'Answer posted!');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Could not post answer.');
    }
  }

  Future<void> _editQuestion() async {
    final post = _post;
    if (post == null || post.backendId == null) return;
    final int backendId = post.backendId!;
    final titleCtrl = TextEditingController(text: post.question);
    final cropCtrl = TextEditingController(text: post.crop ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Question',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cropCtrl,
              decoration: const InputDecoration(
                labelText: 'Crop',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final title = titleCtrl.text.trim();
    final crop = cropCtrl.text.trim();
    titleCtrl.dispose();
    cropCtrl.dispose();
    if (ok != true || title.isEmpty || crop.isEmpty) return;

    try {
      await ForumService.updateQuestion(
        id: backendId,
        title: title,
        crop: crop,
        description: title,
      );
      await _load();
      if (!mounted) return;
      CustomNotification.show(context, 'Question updated.');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Update failed.');
    }
  }

  Future<void> _deleteQuestion() async {
    final post = _post;
    if (post == null || post.backendId == null) return;
    final int backendId = post.backendId!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This will remove the question and its answers permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ForumService.deleteQuestion(backendId);
      if (!mounted) return;
      CustomNotification.show(context, 'Question deleted.');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Delete failed.');
    }
  }

  Future<void> _toggleLike(ForumReply reply) async {
    if (reply.backendId == null) return;
    try {
      await ForumService.toggleLike(reply.backendId!);
      await _load(); // refresh counts
    } catch (_) {}
  }

  Future<void> _editReply(ForumReply reply) async {
    if (reply.backendId == null) return;
    final ctrl = TextEditingController(text: reply.content);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit answer'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || text.isEmpty) return;

    try {
      await ForumService.updateAnswer(id: reply.backendId!, text: text);
      await _load();
      if (!mounted) return;
      CustomNotification.show(context, 'Answer updated.');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Update failed.');
    }
  }

  Future<void> _deleteReply(ForumReply reply) async {
    if (reply.backendId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete answer?'),
        content: const Text('This will remove the answer permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ForumService.deleteAnswer(reply.backendId!);
      await _load();
      if (!mounted) return;
      CustomNotification.show(context, 'Answer deleted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Delete failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AgroAppScope.of(context).profile;
    final canManageQuestion = profile != null &&
        (_post?.userId == profile.id || AuthService.role == 'superadmin');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Details'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (canManageQuestion)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editQuestion();
                if (v == 'delete') _deleteQuestion();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReply,
        backgroundColor: const Color(0xFF00A36C),
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _post == null
                  ? const Center(child: Text('Not found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_post!.question,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(
                                  'Crop: ${_post!.crop ?? ''} • ${_post!.time}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text('Answers',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 10),
                        if (_post!.replies.isEmpty)
                          const Text('No answers yet.',
                              style: TextStyle(color: Colors.grey)),
                        ..._post!.replies.map(
                          (r) => Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(r.name),
                              subtitle: Text(r.content),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${r.helpfulCount}'),
                                  IconButton(
                                    onPressed: () => _toggleLike(r),
                                    icon: const Icon(Icons.thumb_up_alt_outlined),
                                  ),
                                  if (profile != null &&
                                      (r.userId == profile.id ||
                                          AuthService.role == 'superadmin'))
                                    PopupMenuButton<String>(
                                      onSelected: (v) {
                                        if (v == 'edit') _editReply(r);
                                        if (v == 'delete') _deleteReply(r);
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
            ),
          ],
        ),
      ),
    );
  }
}
