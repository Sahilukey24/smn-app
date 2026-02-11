import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';

/// Create service: title, description, price, delivery days, category, sample image/video. Save to services.
class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({
    super.key,
    this.profileId,
  });

  final String? profileId;

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _deliveryDaysController = TextEditingController();

  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  String? _demoImageUrl;
  String? _demoVideoUrl;
  String? _profileId;
  String? _profileRole;
  bool _loading = false;
  bool _loadingCategories = true;
  String? _error;

  static const _bucket = 'service-samples';

  @override
  void initState() {
    super.initState();
    _resolveProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _deliveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _resolveProfile() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _loadingCategories = false;
        _error = 'Not logged in';
      });
      return;
    }
    String? profileId = widget.profileId;
    String? role;
    if (profileId == null) {
      final res = await client.from('profiles').select('id, role').eq('user_id', userId).limit(1).maybeSingle();
      if (res != null) {
        profileId = res['id'] as String;
        role = res['role'] as String?;
      }
    } else {
      final res = await client.from('profiles').select('role').eq('id', profileId).maybeSingle();
      role = res?['role'] as String?;
    }
    setState(() {
      _profileId = profileId;
      _profileRole = role;
    });
    await _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (_profileRole == null) {
      setState(() => _loadingCategories = false);
      return;
    }
    try {
      var res = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('role_type', _profileRole!)
          .order('sort_order');
      var categories = (res as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
      if (_profileId != null) {
        final pps = await Supabase.instance.client
            .from('profile_predefined_services')
            .select('predefined_services(category_id)')
            .eq('profile_id', _profileId!);
        final allowedCategoryIds = <String>{};
        for (final r in pps as List) {
          final nested = r['predefined_services'];
          if (nested != null && nested is Map && nested['category_id'] != null) {
            allowedCategoryIds.add(nested['category_id'] as String);
          }
        }
        if (allowedCategoryIds.isNotEmpty) {
          categories = categories.where((c) => allowedCategoryIds.contains(c.id)).toList();
        }
      }
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    await _uploadFile(File(x.path), 'image', (url) => setState(() => _demoImageUrl = url));
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    await _uploadFile(File(result.files.single.path!), 'video', (url) => setState(() => _demoVideoUrl = url));
  }

  Future<void> _uploadFile(File file, String type, void Function(String url) onUrl) async {
    setState(() => _error = null);
    try {
      final client = Supabase.instance.client;
      final path = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split(RegExp(r'[/\\]')).last}';
      await client.storage.from(_bucket).upload(path, file, fileOptions: FileOptions(upsert: true));
      final url = client.storage.from(_bucket).getPublicUrl(path);
      onUrl(url);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profileId == null) return;
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price < AppConstants.minServicePriceInr) {
      setState(() => _error = 'Price must be at least ₹${AppConstants.minServicePriceInr}');
      return;
    }
    final deliveryDays = int.tryParse(_deliveryDaysController.text.trim());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('services').insert({
        'profile_id': _profileId!,
        'name': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'price_inr': price,
        'delivery_days': deliveryDays,
        'category_id': _selectedCategoryId,
        'demo_image_url': _demoImageUrl,
        'demo_video_url': _demoVideoUrl,
        'is_active': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service created')));
        context.pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingCategories) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create service')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_profileId == null && _error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create service')),
        body: Center(child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Create service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final n = double.tryParse(v.trim());
                  if (n == null || n < AppConstants.minServicePriceInr) return 'Min ₹${AppConstants.minServicePriceInr}';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deliveryDaysController,
                decoration: const InputDecoration(
                  labelText: 'Delivery days',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Select —')),
                  ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 20),
              Text('Sample image / video', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Image'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Video'),
                  ),
                ],
              ),
              if (_demoImageUrl != null || _demoVideoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${_demoImageUrl != null ? "Image set. " : ""}${_demoVideoUrl != null ? "Video set." : ""}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
