import 'package:flutter/material.dart';

import '../models/disease_solution_item.dart';
import '../models/plant.dart';
import '../services/api_client.dart';
import '../services/catalog_service.dart';

class SolutionsLibraryScreen extends StatefulWidget {
  const SolutionsLibraryScreen({super.key});

  @override
  State<SolutionsLibraryScreen> createState() => _SolutionsLibraryScreenState();
}

class _SolutionsLibraryScreenState extends State<SolutionsLibraryScreen> {
  bool _loadingPlants = true;
  bool _loadingSolutions = false;
  String? _error;

  List<Plant> _plants = const [];
  Plant? _selectedPlant;
  List<DiseaseSolutionItem> _solutions = const [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    setState(() {
      _loadingPlants = true;
      _error = null;
    });
    try {
      final plants = await CatalogService.fetchPlants();
      if (!mounted) return;
      setState(() {
        _plants = plants;
        _selectedPlant = plants.isNotEmpty ? plants.first : null;
        _loadingPlants = false;
      });
      await _loadSolutions();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlants = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPlants = false;
        _error = 'Failed to load catalog. Please try again.';
      });
    }
  }

  Future<void> _loadSolutions() async {
    final plantId = _selectedPlant?.id;
    setState(() {
      _loadingSolutions = true;
      _error = null;
    });
    try {
      final items = await CatalogService.fetchSolutions(plantId: plantId);
      if (!mounted) return;
      setState(() {
        _solutions = items;
        _loadingSolutions = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSolutions = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSolutions = false;
        _error = 'Failed to load solutions. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solutions Library')),
      body: _loadingPlants
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A36C)),
            )
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadPlants)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: DropdownButtonFormField<int>(
                        value: _selectedPlant?.id,
                        items: _plants
                            .map((p) => DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(p.name),
                                ))
                            .toList(growable: false),
                        onChanged: (id) {
                          final plant =
                              _plants.firstWhere((p) => p.id == id);
                          setState(() => _selectedPlant = plant);
                          _loadSolutions();
                        },
                        decoration: const InputDecoration(
                          labelText: 'Plant',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _loadingSolutions
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF00A36C)),
                            )
                          : _solutions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No solutions found for this plant.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _solutions.length,
                                  itemBuilder: (context, i) =>
                                      _SolutionCard(item: _solutions[i]),
                                ),
                    ),
                  ],
                ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.item});

  final DiseaseSolutionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.diseaseName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if ((item.organic ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Organic', style: TextStyle(color: Color(0xFF00A36C))),
              Text(item.organic!.trim()),
            ],
            if ((item.chemical ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Chemical',
                  style: TextStyle(color: Color(0xFF00A36C))),
              Text(item.chemical!.trim()),
            ],
            if ((item.tips ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Tips', style: TextStyle(color: Color(0xFF00A36C))),
              Text(item.tips!.trim()),
            ],
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

