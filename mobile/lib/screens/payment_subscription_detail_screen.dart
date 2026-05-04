import 'package:flutter/material.dart';

import '../models/user_subscription_item.dart';
import '../services/api_client.dart';
import '../services/payment_history_service.dart';

class PaymentSubscriptionDetailScreen extends StatefulWidget {
  const PaymentSubscriptionDetailScreen({super.key, required this.id});

  final int id;

  @override
  State<PaymentSubscriptionDetailScreen> createState() =>
      _PaymentSubscriptionDetailScreenState();
}

class _PaymentSubscriptionDetailScreenState
    extends State<PaymentSubscriptionDetailScreen> {
  bool _loading = true;
  String? _error;
  UserSubscriptionItem? _item;

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
      final item = await PaymentHistoryService.getMine(widget.id);
      if (!mounted) return;
      setState(() {
        _item = item;
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
        _error = 'Failed to load subscription details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Details')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _item == null
                  ? const Center(child: Text('Not found.'))
                  : _Detail(item: _item!),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item});

  final UserSubscriptionItem item;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Row(label: 'Plan', value: item.plan.name),
        _Row(label: 'Price', value: '৳${item.plan.price.toStringAsFixed(2)}'),
        _Row(label: 'Duration', value: '${item.plan.durationDays} days'),
        _Row(label: 'Status', value: item.status),
        _Row(label: 'Active', value: item.isActive ? 'Yes' : 'No'),
        _Row(label: 'Transaction', value: item.transactionId),
        if ((item.startDate ?? '').isNotEmpty)
          _Row(label: 'Start', value: item.startDate!),
        if ((item.endDate ?? '').isNotEmpty)
          _Row(label: 'End', value: item.endDate!),
        if (item.createdAt.isNotEmpty)
          _Row(label: 'Created', value: item.createdAt),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 105,
              child: Text(label, style: const TextStyle(color: Colors.grey)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
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

