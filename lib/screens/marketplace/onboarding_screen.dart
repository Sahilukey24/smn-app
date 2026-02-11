import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';

class MarketplaceOnboardingScreen extends StatefulWidget {
  const MarketplaceOnboardingScreen({super.key});

  @override
  State<MarketplaceOnboardingScreen> createState() => _MarketplaceOnboardingScreenState();
}

class _MarketplaceOnboardingScreenState extends State<MarketplaceOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    ('Connect & Grow', 'Business owners find creators. Creators, videographers and freelancers offer services.', Icons.handshake_outlined),
    ('Set Your Price', 'Minimum ₹10 per service. You set prices; we handle payments and payouts.', Icons.currency_rupee),
    ('Deadline by Calendar', 'No chat before payment. Negotiate delivery only via calendar.', Icons.calendar_today),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.$3, size: 80, color: theme.colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(
                          p.$1,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.$2,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        await OnboardingService().setOnboardingSeen();
                        if (mounted) context.go('/login');
                      }
                    },
                    child: Text(_currentPage < _pages.length - 1 ? 'Next' : 'Get started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
