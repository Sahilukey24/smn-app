import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/category_model.dart';
import '../../models/predefined_service_model.dart';
import '../../services/provider_service.dart';

/// Provider onboarding: category (role), max 4 service types, display name, bio 20-300,
/// base price, delivery days, portfolio links, instagram + youtube. Validation + preview before publish.
class ProviderSetupScreen extends StatefulWidget {
  const ProviderSetupScreen({
    super.key,
    this.profileId,
    this.role,
  });

  final String? profileId;
  final String? role;

  @override
  State<ProviderSetupScreen> createState() => _ProviderSetupScreenState();
}

class _ProviderSetupScreenState extends State<ProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _deliveryDaysController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _portfolioController = TextEditingController();

  final ProviderService _providerService = ProviderService();

  String? _selectedRole;
  final List<String> _selectedPredefinedIds = [];
  List<CategoryModel> _categories = [];
  List<PredefinedServiceModel> _predefinedServices = [];
  final List<Map<String, String>> _portfolioLinks = [];
  bool _loading = false;
  bool _loadingData = true;
  bool _showPreview = false;
  String? _error;
  String? _createdProfileId;

  static const _maxServiceTypes = AppConstants.providerMaxServiceTypes;
  static const _bioMin = AppConstants.providerBioMinLength;
  static const _bioMax = AppConstants.providerBioMaxLength;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.role ?? AppConstants.roleCreator;
    _loadData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _basePriceController.dispose();
    _deliveryDaysController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_selectedRole == null) {
      setState(() => _loadingData = false);
      return;
    }
    try {
      if (widget.profileId != null) {
        final prof = await _providerService.getProfile(widget.profileId!);
        if (prof != null) {
          _selectedRole = prof.role;
          _displayNameController.text = prof.displayName ?? '';
          _bioController.text = prof.bio ?? '';
          if (prof.basePriceInr != null) _basePriceController.text = prof.basePriceInr!.toStringAsFixed(0);
          if (prof.defaultDeliveryDays != null) _deliveryDaysController.text = prof.defaultDeliveryDays.toString();
          _instagramController.text = prof.instagramHandle ?? '';
          _youtubeController.text = prof.youtubeChannelId ?? '';
          if (prof.portfolioLinks != null) {
            for (final m in prof.portfolioLinks!) {
              if (m is Map && m['url'] != null) _portfolioLinks.add({'url': m['url'].toString(), 'label': (m['label'] ?? '').toString()});
            }
          }
          final ids = await _providerService.getProfilePredefinedServiceIds(widget.profileId!);
          _selectedPredefinedIds.addAll(ids);
        }
      }
      final client = Supabase.instance.client;
      final catRes = await client.from('categories').select().eq('role_type', _selectedRole!).order('sort_order');
      _categories = (catRes as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      final prefRes = await client
          .from('predefined_services')
          .select()
          .inFilter('category_id', _categories.map((c) => c.id).toList())
          .order('sort_order');
      _predefinedServices = (prefRes as List).map((e) => PredefinedServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    setState(() => _loadingData = false);
  }

  void _addPortfolioLink() {
    final url = _portfolioController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _portfolioLinks.add({'url': url, 'label': 'Portfolio'});
      _portfolioController.clear();
    });
  }

  bool get _canAddServiceType => _selectedPredefinedIds.length < _maxServiceTypes;

  Future<void> _saveDraft() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    _error = null;
    try {
      final role = _selectedRole!;
      final displayName = _displayNameController.text.trim();
      final bio = _bioController.text.trim();
      final basePrice = double.tryParse(_basePriceController.text.trim());
      final deliveryDays = int.tryParse(_deliveryDaysController.text.trim());
      final profileId = widget.profileId ?? _createdProfileId;

      if (profileId != null) {
        await _providerService.updateProviderProfile(
          profileId: profileId,
          displayName: displayName,
          bio: bio,
          basePriceInr: basePrice,
          deliveryDays: deliveryDays,
          portfolioLinks: _portfolioLinks.isEmpty ? null : _portfolioLinks,
        );
        await _providerService.linkSocialAccounts(
          profileId: profileId,
          instagramHandle: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
          youtubeHandle: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        );
        await _providerService.setServices(profileId: profileId, predefinedServiceIds: List.from(_selectedPredefinedIds));
      } else {
        final prof = await _providerService.createProviderProfile(
          role: role,
          displayName: displayName,
          bio: bio,
          basePriceInr: basePrice,
          deliveryDays: deliveryDays,
          portfolioLinks: _portfolioLinks.isEmpty ? null : _portfolioLinks,
        );
        if (prof != null) {
          _createdProfileId = prof.id;
          await _providerService.linkSocialAccounts(
            profileId: prof.id,
            instagramHandle: _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
            youtubeHandle: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
          );
          await _providerService.setServices(profileId: prof.id, predefinedServiceIds: List.from(_selectedPredefinedIds));
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  bool _validate() {
    if (_displayNameController.text.trim().isEmpty) {
      setState(() => _error = 'Display name required');
      return false;
    }
    final bio = _bioController.text.trim();
    if (bio.length < _bioMin || bio.length > _bioMax) {
      setState(() => _error = 'Bio must be $_bioMin–$_bioMax characters');
      return false;
    }
    if (_selectedPredefinedIds.isEmpty) {
      setState(() => _error = 'Select at least one service type');
      return false;
    }
    if (_selectedPredefinedIds.length > _maxServiceTypes) {
      setState(() => _error = 'Max $_maxServiceTypes service types');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _publish() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    _error = null;
    try {
      await _saveDraft();
      String? profileId = widget.profileId ?? _createdProfileId;
      if (profileId == null) {
        final list = await Supabase.instance.client.from('profiles').select('id').eq('user_id', Supabase.instance.client.auth.currentUser!.id).eq('role', _selectedRole!).limit(1);
        profileId = (list as List).isNotEmpty ? (list.first as Map)['id'] as String? : null;
      }
      if (profileId != null) {
        await _providerService.publishProfile(profileId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You\'re live!')));
          context.pop(true);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Provider setup')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_showPreview) {
      return Scaffold(
        appBar: AppBar(title: const Text('Preview')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayNameController.text.trim(), style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(_bioController.text.trim(), style: theme.textTheme.bodyMedium),
                      if (_basePriceController.text.trim().isNotEmpty)
                        Text('From ₹${_basePriceController.text.trim()}', style: theme.textTheme.bodyLarge),
                      if (_deliveryDaysController.text.trim().isNotEmpty)
                        Text('${_deliveryDaysController.text.trim()} days delivery', style: theme.textTheme.bodySmall),
                      if (_instagramController.text.trim().isNotEmpty)
                        Text('Instagram: ${_instagramController.text.trim()}', style: theme.textTheme.bodySmall),
                      if (_youtubeController.text.trim().isNotEmpty)
                        Text('YouTube: ${_youtubeController.text.trim()}', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _predefinedServices
                            .where((p) => _selectedPredefinedIds.contains(p.id))
                            .map((p) => Chip(label: Text(p.name)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _loading ? null : _publish, child: const Text('Publish & go live')),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => setState(() => _showPreview = false),
                child: const Text('Back to edit'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Provider setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Category (role)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  const ButtonSegment(value: 'creator', label: Text('Creator'), icon: Icon(Icons.person)),
                  const ButtonSegment(value: 'videographer', label: Text('Videographer'), icon: Icon(Icons.videocam)),
                  const ButtonSegment(value: 'freelancer', label: Text('Freelancer'), icon: Icon(Icons.work)),
                ],
                selected: {_selectedRole ?? 'creator'},
                onSelectionChanged: (s) {
                  setState(() {
                    _selectedRole = s.first;
                    _selectedPredefinedIds.clear();
                    _loadData();
                  });
                },
              ),
              const SizedBox(height: 20),
              Text('Service types (max $_maxServiceTypes)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedServices.map((p) {
                  final selected = _selectedPredefinedIds.contains(p.id);
                  return FilterChip(
                    label: Text(p.name),
                    selected: selected,
                    onSelected: _canAddServiceType || selected
                        ? (v) {
                            setState(() {
                              if (v) {
                                if (_selectedPredefinedIds.length < _maxServiceTypes) _selectedPredefinedIds.add(p.id);
                              } else {
                                _selectedPredefinedIds.remove(p.id);
                              }
                            });
                          }
                        : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio ($_bioMin–$_bioMax characters)',
                  border: const OutlineInputBorder(),
                  counterText: '${_bioController.text.length}/$_bioMax',
                ),
                maxLength: _bioMax,
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().length < _bioMin) return 'Min $_bioMin characters';
                  if (v.length > _bioMax) return 'Max $_bioMax characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(labelText: 'Base price (₹)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryDaysController,
                decoration: const InputDecoration(labelText: 'Delivery days', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instagramController,
                decoration: const InputDecoration(labelText: 'Instagram handle', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _youtubeController,
                decoration: const InputDecoration(labelText: 'YouTube channel', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text('Portfolio links', style: theme.textTheme.titleSmall),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _portfolioController,
                      decoration: const InputDecoration(hintText: 'URL', border: OutlineInputBorder()),
                      onFieldSubmitted: (_) => _addPortfolioLink(),
                    ),
                  ),
                  IconButton(onPressed: _addPortfolioLink, icon: const Icon(Icons.add)),
                ],
              ),
              if (_portfolioLinks.isNotEmpty)
                ..._portfolioLinks.asMap().entries.map((e) => ListTile(
                      title: Text(e.value['url'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => _portfolioLinks.removeAt(e.key)),
                      ),
                    )),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : () => _validate() ? setState(() => _showPreview = true) : null,
                child: const Text('Preview'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : _saveDraft,
                child: const Text('Save draft'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
