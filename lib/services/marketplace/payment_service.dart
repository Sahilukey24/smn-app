import '../../config/app_config.dart';
import '../../core/constants.dart';

/// Razorpay integration. Use server-side order create + capture for production.
/// Client: create order → open Razorpay checkout → on success call backend to capture.
class PaymentService {
  /// Create Razorpay order for role verification (₹15).
  /// In production: call your backend which creates Razorpay order and returns order_id.
  Future<String?> createRoleVerificationPayment() async {
    if (AppConfig.razorpayKeyId.isEmpty) return null;
    // TODO: Call backend POST /create-order { amount: 1500 (paise), purpose: 'role_verification' }
    // Return razorpay_order_id for client checkout.
    return null;
  }

  /// Create Razorpay order for cart total (services + ₹49).
  /// In production: backend creates order, returns order_id; client opens checkout.
  Future<String?> createOrderPayment({
    required String orderId,
    required double amountInr,
  }) async {
    if (AppConfig.razorpayKeyId.isEmpty) return null;
    // amountInr = sum(services) + AppConstants.platformChargePerOrderInr
    // TODO: Backend creates Razorpay order, stores in payments table, returns razorpay_order_id
    return null;
  }

  /// Verify and capture payment (backend webhook or after client success).
  /// Webhook: Razorpay sends to your backend; backend verifies signature, updates payments + orders/roles.
  static double roleVerificationAmountInr() => AppConstants.roleVerificationFeeInr;
  static double platformChargeInr() => AppConstants.platformChargePerOrderInr;
}
