import 'package:flutter/material.dart';

import '../models/managed_user.dart';
import '../services/api_client.dart';
import '../services/user_management_service.dart';

class ExpertPanelScreen extends StatefulWidget {
  const ExpertPanelScreen({super.key});

  @override
  State<ExpertPanelScreen> createState() => _ExpertPanelScreenState();
}

class _ExpertPanelScreenState extends State<ExpertPanelScreen> {
  bool _loading = true;
  String? _error;
  List<ManagedUser> _users = const [];

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
      final users = await UserManagementService.fetchExpertUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
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
        _error = 'Network error. Please check your connection.';
      });
    }
  }

  Future<void> _toggleVerify(ManagedUser user) async {
    final next = !user.isVerified;
    try {
      final updated = await UserManagementService.expertVerifyPaidUser(
        userId: user.id,
        isVerified: next,
      );
      if (!mounted) return;
      setState(() {
        _users = _users
            .map((u) => u.id == updated.id ? updated : u)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${updated.username}')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = _users.where((u) => u.role == 'paid').toList(growable: false);
    final others = _users.where((u) => u.role != 'paid').toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Panel'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _error != null
              ? _PanelError(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Premium Users (verify only)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (paid.isEmpty)
                      const Text('No premium users found.',
                          style: TextStyle(color: Colors.grey)),
                    ...paid.map((u) => _UserTile(
                          user: u,
                          trailing: Switch(
                            value: u.isVerified,
                            onChanged: (_) => _toggleVerify(u),
                          ),
                        )),
                    const SizedBox(height: 18),
                    const Text(
                      'Other Accounts (read-only)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (others.isEmpty)
                      const Text('No other accounts.',
                          style: TextStyle(color: Colors.grey)),
                    ...others.map((u) => _UserTile(
                          user: u,
                          trailing: Icon(
                            u.isVerified ? Icons.verified : Icons.info_outline,
                            color: u.isVerified ? Colors.green : Colors.grey,
                          ),
                        )),
                  ],
                ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.trailing});

  final ManagedUser user;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        title: Text(user.username),
        subtitle: Text('${user.roleLabel} • ${user.email}'),
        trailing: trailing,
      ),
    );
  }
}

class _PanelError extends StatelessWidget {
  const _PanelError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 54),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

