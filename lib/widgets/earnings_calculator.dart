import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/pricing.dart';

/// Real-time earnings: If price = X, platform 6%, gateway 2%, you receive = X - 6% - 2%.
class EarningsCalculator extends StatelessWidget {
  const EarningsCalculator({
    super.key,
    required this.priceInr,
    this.label = 'You receive',
  });

  final double priceInr;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = Pricing.platformFee(priceInr);
    final gateway = Pricing.gatewayFee(priceInr);
    final receive = Pricing.creatorReceives(priceInr);
    final valid = Pricing.isValidServicePrice(priceInr);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings breakdown',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _row(theme, 'Price', '₹${priceInr.toStringAsFixed(0)}'),
            _row(theme, 'Platform (${AppConstants.platformFeePercent}%)', '- ₹${platform.toStringAsFixed(0)}'),
            _row(theme, 'Gateway (${AppConstants.gatewayFeePercent}%)', '- ₹${gateway.toStringAsFixed(0)}'),
            const Divider(height: 24),
            _row(
              theme,
              label,
              '₹${receive.toStringAsFixed(0)}',
              isBold: true,
            ),
            if (!valid) ...[
              const SizedBox(height: 8),
              Text(
                'Minimum price is ₹${AppConstants.minServicePriceInr.toInt()}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : null,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
