import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/history_item.dart';
import '../models/scan_result.dart';
import '../services/api_client.dart';
import '../services/scan_service.dart';
import '../widgets/custom_notification.dart';
import 'forum_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    this.imageBytes,
    this.imageUrl,
    // New API path: pass crop and imageBytes → scan runs on load.
    this.prefetchedResult,
    this.crop,
    this.isHistoryView = false,
    // History view overrides (replaces API result display).
    this.diagnosisTitle,
    this.diagnosisColor,
    this.matchPercentage,
    this.actions,
  });

  final Uint8List? imageBytes;
  final String? imageUrl;
  final ScanResult? prefetchedResult;
  final String? crop;
  final bool isHistoryView;

  // History display overrides
  final String? diagnosisTitle;
  final Color? diagnosisColor;
  final String? matchPercentage;
  final List<RecommendationAction>? actions;

  /// True when history params are provided directly (no API call needed).
  bool get _hasHistoryData => diagnosisTitle != null;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  ScanResult? _result;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget._hasHistoryData || widget.prefetchedResult != null) {
      // History view: no API call needed.
      _result = widget.prefetchedResult;
      _loading = false;
    } else {
      _runScan();
    }
  }

  Future<void> _runScan() async {
    if (widget.imageBytes == null || widget.crop == null) {
      setState(() {
        _loading = false;
        _errorMessage = 'Missing image or crop information.';
      });
      return;
    }
    try {
      final result = await ScanService.submitScan(
        imageBytes: widget.imageBytes!,
        crop: widget.crop!,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Network error. Please check your connection.';
      });
    }
  }

  void _saveToHistory() {
    if (_result == null) return;
    final cropLetter =
        (widget.crop?.isNotEmpty == true) ? widget.crop![0].toUpperCase() : 'T';
    AgroAppScope.of(context).saveDiagnosisToHistory(
      title: _result!.diseaseName,
      statusColor: _result!.statusColor,
      icon: cropLetter,
      cropName: widget.crop ?? '',
      matchPercentage: _result!.confidencePercent,
      imageBytes: widget.imageBytes,
      actions: _result!.actions,
    );
    CustomNotification.show(context, 'Saved to history.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Analysis Result',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _loading
          ? const _LoadingView()
          : _errorMessage != null
              ? _ErrorView(
                  message: _errorMessage!,
                  onRetry: widget.isHistoryView ? null : () {
                    setState(() {
                      _loading = true;
                      _errorMessage = null;
                    });
                    _runScan();
                  },
                )
              : _buildResult(),
      bottomNavigationBar: (!widget.isHistoryView && !_loading && _errorMessage == null &&
              (widget._hasHistoryData || _result?.isOk == true))
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _saveToHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Save to History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildResult() {
    // Resolve display values: history overrides take priority over API result.
    final bool fromHistory = widget._hasHistoryData;
    final String displayTitle =
        widget.diagnosisTitle ?? _result?.diseaseName ?? 'Unknown';
    final Color displayColor =
        widget.diagnosisColor ?? _result?.statusColor ?? Colors.orange;
    final String displayConfidence =
        widget.matchPercentage ?? _result?.confidencePercent ?? '—';
    final List<RecommendationAction> displayActions =
        widget.actions ?? _result?.actions ?? const [];
    final bool displayIsHealthy = fromHistory
        ? displayTitle.toLowerCase().contains('healthy')
        : (_result?.isHealthy ?? false);

    // For API results, treat "not_a_plant" as a valid outcome (not an error UI).
    if (!fromHistory &&
        _result != null &&
        _result!.prediction.status == 'not_a_plant') {
      return _NotAPlantView(
        imageBytes: widget.imageBytes,
        message: _result!.prediction.message,
      );
    }

    // For API results, show status-specific cards for incomplete scans.
    if (!fromHistory && _result != null && !_result!.isOk) {
      return _StatusCard(prediction: _result!.prediction);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(25),
                  image: widget.imageBytes != null
                      ? DecorationImage(
                          image: MemoryImage(widget.imageBytes!),
                          fit: BoxFit.cover,
                        )
                      : (widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(widget.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: (widget.imageBytes == null &&
                        (widget.imageUrl == null ||
                            widget.imageUrl!.isEmpty))
                    ? const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            size: 60, color: Colors.grey))
                    : null,
              ),
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    displayConfidence,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  displayIsHealthy
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: displayColor,
                ),
              ),
            ],
          ),
          Text(
            'Crop: ${widget.crop ?? _result?.prediction.crop ?? ''}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 25),
          if (displayActions.isNotEmpty) ...[
            const Text(
              'Recommended Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...displayActions.map((a) => _ActionTile(action: a)),
          ] else if (displayIsHealthy) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Your crop appears healthy! Continue your current care routine.',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'No solution is available for this result yet. Please check back later.',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),
          // Ask an expert banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A191E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology_outlined,
                    color: Colors.white, size: 40),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need more help?',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Talk to a certified agronomist now.',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ForumScreen(
                          initialDraftQuestion:
                              'I need help with $displayTitle on my ${widget.crop ?? 'crop'}. What should I do next?',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A36C)),
                  child: const Text('Ask'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF00A36C)),
          SizedBox(height: 20),
          Text(
            'Analyzing your crop...',
            style: TextStyle(
                fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.prediction});

  final ScanPrediction prediction;

  @override
  Widget build(BuildContext context) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    switch (prediction.status) {
      case 'not_a_plant':
        title = 'Not a Plant Leaf';
        subtitle = prediction.message ??
            'Please upload a clear photo of a plant leaf.';
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case 'crop_mismatch':
        title = 'Crop Mismatch';
        subtitle = prediction.message ??
            'The detected crop does not match your selection. Please try again with the correct crop.';
        icon = Icons.compare_arrows_rounded;
        color = Colors.deepOrange;
        break;
      case 'low_confidence':
        title = 'Low Confidence';
        subtitle = prediction.message ??
            'The model is not confident enough. Try a clearer photo.';
        icon = Icons.help_outline_rounded;
        color = Colors.amber;
        break;
      default:
        title = 'Scan Incomplete';
        subtitle = prediction.message ?? 'An unknown issue occurred.';
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 72),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotAPlantView extends StatelessWidget {
  const _NotAPlantView({required this.imageBytes, this.message});

  final Uint8List? imageBytes;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(25),
              image: imageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(imageBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageBytes == null
                ? const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        size: 60, color: Colors.grey))
                : null,
          ),
          const SizedBox(height: 22),
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Not a Plant Leaf',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message ?? 'Please upload a clear photo of a plant leaf.',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

  final RecommendationAction action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: const Color(0xFF00A36C)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(action.description,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
