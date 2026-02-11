import 'constants.dart';

/// Platform pricing calculations.
class Pricing {
  Pricing._();

  /// Platform fee (6% of price).
  static double platformFee(double priceInr) =>
      (priceInr * AppConstants.platformFeePercent / 100);

  /// Gateway fee (2% of price).
  static double gatewayFee(double priceInr) =>
      (priceInr * AppConstants.gatewayFeePercent / 100);

  /// Creator receives: price - 6% - 2%.
  static double creatorReceives(double priceInr) =>
      priceInr - platformFee(priceInr) - gatewayFee(priceInr);

  /// Buyer pays per order: sum(service prices) + ₹49 platform charge.
  static double orderTotal(List<double> servicePricesInr) {
    final sum = servicePricesInr.fold<double>(0, (a, b) => a + b);
    return sum + AppConstants.platformChargePerOrderInr;
  }

  /// Validate service price (min ₹10).
  static bool isValidServicePrice(double priceInr) =>
      priceInr >= AppConstants.minServicePriceInr;
}
