import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../services/marketplace/auth_service.dart';
import '../../services/marketplace/cart_service.dart';
import '../../services/marketplace/profile_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();

  List<ProfileModel> _profiles = [];
  String? _filterRole;
  bool _loading = true;
  int _cartCount = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      bool isAdmin = false;
      if (uid != null) {
        final u = await Supabase.instance.client.from('users').select('is_admin').eq('id', uid).maybeSingle();
        isAdmin = (u as Map<String, dynamic>?)?['is_admin'] as bool? ?? false;
      }
      final profiles = await _profileService.listLiveProfiles(role: _filterRole);
      final count = await _cartService.getItemCount();
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _cartCount = count;
          _isAdmin = isAdmin;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMN Marketplace'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => context.push('/admin'),
              tooltip: 'Admin',
            ),
          IconButton(
            icon: Badge(
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () => context.push('/dashboard/business'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip(theme, null, 'All'),
                _chip(theme, AppConstants.roleCreator, 'Creators'),
                _chip(theme, AppConstants.roleVideographer, 'Videographers'),
                _chip(theme, AppConstants.roleFreelancer, 'Freelancers'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? Center(child: Text('No profiles yet', style: theme.textTheme.bodyLarge))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _profiles.length,
                          itemBuilder: (context, i) {
                            final p = _profiles[i];
                            return Card(
                              child: ListTile(
                                title: Text(p.displayName ?? 'Provider'),
                                subtitle: Text(p.role),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/profile/${p.id}'),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ThemeData theme, String? value, String label) {
    final selected = _filterRole == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _filterRole = value;
            _load();
          });
        },
      ),
    );
  }
}
