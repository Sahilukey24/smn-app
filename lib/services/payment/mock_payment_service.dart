/// Fake payment for product-first MVP. No Razorpay, no backend.
class MockPaymentService {
  MockPaymentService._();
  static final MockPaymentService instance = MockPaymentService._();

  /// Simulates payment success after 2 seconds.
  Future<bool> simulatePayment() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return true;
  }

  /// Pay (mock). Returns true after 2 seconds.
  Future<bool> pay() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return true;
  }
}
