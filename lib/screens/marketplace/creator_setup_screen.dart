import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/pricing.dart';
import '../../models/category_model.dart';
import '../../models/predefined_service_model.dart';
import '../../services/marketplace/category_service.dart';
import '../../services/marketplace/profile_service.dart';
import '../../widgets/earnings_calculator.dart';

class CreatorSetupScreen extends StatefulWidget {
  const CreatorSetupScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<CreatorSetupScreen> createState() => _CreatorSetupScreenState();
}

class _CreatorSetupScreenState extends State<CreatorSetupScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProfileService _profileService = ProfileService();

  List<CategoryModel> _categories = [];
  Map<String, List<PredefinedServiceModel>> _servicesByCategory = {};
  Map<String, double> _prices = {};
  Set<String> _selectedCategoryIds = {};
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cats = await _categoryService.getCategoriesByRole(AppConstants.roleCreator);
      final map = <String, List<PredefinedServiceModel>>{};
      for (final c in cats) {
        final svcs = await _categoryService.getPredefinedServices(c.id);
        map[c.id] = svcs;
      }
      if (mounted) {
        setState(() {
          _categories = cats;
          _servicesByCategory = map;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
        for (final s in _servicesByCategory[id] ?? []) {
          _prices.remove(s.id);
        }
      } else if (_selectedCategoryIds.length < AppConstants.creatorMaxCategories) {
        _selectedCategoryIds.add(id);
      }
    });
  }

  Future<void> _saveAndGoLive() async {
    final invalid = _prices.entries.where((e) => !Pricing.isValidServicePrice(e.value)).toList();
    if (invalid.isNotEmpty) {
      setState(() => _error = 'Minimum price is ₹${AppConstants.minServicePriceInr.toInt()} for all services.');
      return;
    }
    setState(() => _saving = true);
    try {
      for (final e in _prices.entries) {
        final predefinedId = e.key;
        final price = e.value;
        String name = 'Service';
        for (final list in _servicesByCategory.values) {
          for (final s in list) {
            if (s.id == predefinedId) {
              name = s.name;
              break;
            }
          }
        }
        await _profileService.addCreatorService(
          profileId: widget.profileId,
          name: name,
          priceInr: price,
        );
      }
      if (_prices.isEmpty) {
        setState(() => _error = 'Add at least one service with price.');
        setState(() => _saving = false);
        return;
      }
      await _profileService.setProfileLive(widget.profileId, true);
      if (mounted) context.go('/dashboard/provider');
    } catch (_) {
      setState(() => _error = 'Failed to save');
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Creator profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select up to ${AppConstants.creatorMaxCategories} categories, then set price for each service (min ₹${AppConstants.minServicePriceInr.toInt()}).',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
              ),
              const SizedBox(height: 16),
            ],
            ..._categories.map((cat) {
              final selected = _selectedCategoryIds.contains(cat.id);
              final services = _servicesByCategory[cat.id] ?? [];
              return Card(
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: selected,
                        onChanged: (v) => _toggleCategory(cat.id),
                      ),
                      Expanded(child: Text(cat.name)),
                    ],
                  ),
                  children: [
                    ...services.map((s) {
                      final price = _prices[s.id] ?? AppConstants.minServicePriceInr;
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(child: Text(s.name)),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: price.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '₹',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) {
                                  final n = double.tryParse(v);
                                  if (n != null) setState(() => _prices[s.id] = n);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (selected && services.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: EarningsCalculator(
                          priceInr: _prices[services.first.id] ?? AppConstants.minServicePriceInr,
                          label: 'You receive (per service)',
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _saveAndGoLive,
              child: _saving
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save & go live'),
            ),
          ],
        ),
      ),
    );
  }
}
