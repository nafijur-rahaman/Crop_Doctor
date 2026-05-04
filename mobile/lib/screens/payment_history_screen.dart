import 'package:flutter/material.dart';

import '../models/user_subscription_item.dart';
import '../services/api_client.dart';
import '../services/payment_history_service.dart';
import 'payment_subscription_detail_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<UserSubscriptionItem> _items = const [];

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
      final items = await PaymentHistoryService.listMine();
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
        _error = 'Failed to load payment history.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(
                      child: Text('No payments yet.',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, i) {
                        final s = _items[i];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              '${s.plan.name} • ৳${s.plan.price.toStringAsFixed(0)}',
                            ),
                            subtitle: Text(
                              'Status: ${s.status} • Active: ${s.isActive ? 'Yes' : 'No'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PaymentSubscriptionDetailScreen(id: s.id),
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
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

