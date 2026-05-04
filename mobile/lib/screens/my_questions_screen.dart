import 'package:flutter/material.dart';

import '../models/forum_post.dart';
import '../services/api_client.dart';
import '../services/forum_service.dart';
import '../widgets/custom_notification.dart';
import 'question_detail_screen.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() => _MyQuestionsScreenState();
}

class _MyQuestionsScreenState extends State<MyQuestionsScreen> {
  bool _loading = true;
  String? _error;
  List<ForumPost> _items = const [];

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
      final items = await ForumService.getMyQuestions();
      if (!mounted) return;
      setState(() {
        _items = items;
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
        _error = 'Failed to load your questions.';
      });
    }
  }

  Future<void> _deleteQuestion(ForumPost post) async {
    final id = post.backendId;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete question?'),
        content: const Text('This will remove the question permanently.'),
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
      await ForumService.deleteQuestion(id);
      if (!mounted) return;
      setState(() => _items = _items.where((p) => p.backendId != id).toList(growable: false));
      CustomNotification.show(context, 'Question deleted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      CustomNotification.show(context, e.message);
    } catch (_) {
      if (!mounted) return;
      CustomNotification.show(context, 'Delete failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Questions'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A36C)))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(child: Text('No questions yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final p = _items[i];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(p.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('Crop: ${p.crop ?? ''} • ${p.time}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'delete') _deleteQuestion(p);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                            onTap: () {
                              if (p.backendId == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuestionDetailScreen(questionId: p.backendId!),
                                ),
                              );
                            },
                          ),
                        );
                      },
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

