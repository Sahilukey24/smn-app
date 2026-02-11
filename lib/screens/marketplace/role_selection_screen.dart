import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/marketplace/auth_service.dart';
import '../../services/marketplace/payment_service.dart';

class MarketplaceRoleSelectionScreen extends StatefulWidget {
  const MarketplaceRoleSelectionScreen({super.key});

  @override
  State<MarketplaceRoleSelectionScreen> createState() => _MarketplaceRoleSelectionScreenState();
}

class _MarketplaceRoleSelectionScreenState extends State<MarketplaceRoleSelectionScreen> {
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();

  String? _selectedRole;
  bool _loading = false;
  String? _error;

  static const _roles = [
    (AppConstants.roleBusinessOwner, 'Business Owner', 'Hire creators & freelancers', Icons.business_center_outlined),
    (AppConstants.roleCreator, 'Creator', 'Offer influencer services', Icons.face_retouching_natural),
    (AppConstants.roleVideographer, 'Videographer', 'Video services + demos', Icons.videocam_outlined),
    (AppConstants.roleFreelancer, 'Freelancer', 'Design, dev, writing, more', Icons.code),
  ];

  @override
  void initState() {
    super.initState();
    _authService.ensureUser();
  }

  Future<void> _payAndContinue() async {
    if (_selectedRole == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.ensureUser();
      // In production: open Razorpay checkout for ₹15; on success call backend → setRolePaid
      final orderId = await _paymentService.createRoleVerificationPayment();
      if (orderId != null) {
        // TODO: Open Razorpay checkout; on success:
        await _authService.setRolePaid(_selectedRole!);
        if (mounted) _navigateAfterRole();
      } else {
        // Demo: simulate payment success
        await _authService.setRolePaid(_selectedRole!);
        if (mounted) _navigateAfterRole();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  void _navigateAfterRole() {
    if (_selectedRole == AppConstants.roleBusinessOwner) {
      context.go('/marketplace');
    } else {
      context.go('/profile/create', extra: _selectedRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose role')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '₹${AppConstants.roleVerificationFeeInr.toInt()} per role verification',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a role to continue. Payment unlocks profile creation for providers.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
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
              ..._roles.map((r) {
                final value = r.$1;
                final label = r.$2;
                final desc = r.$3;
                final icon = r.$4;
                final selected = _selectedRole == value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedRole = value),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(icon, size: 32, color: theme.colorScheme.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _selectedRole != null && !_loading ? _payAndContinue : null,
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Pay ₹${AppConstants.roleVerificationFeeInr.toInt()} & continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
