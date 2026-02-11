import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors.dart';
import '../../repositories/cart_repository.dart';

/// Cart: 1 cart = 1 creator. Uses [CartRepository].
class CartService {
  CartService() : _repo = CartRepository(Supabase.instance.client);

  final CartRepository _repo;

  Future<String?> getCartProfileId() => _repo.getCartProfileId();
  Future<List<CartItemDto>> getCartItems() => _repo.getCartItems();
  Future<double> getTotalInr() => _repo.getTotalInr();
  Future<int> getItemCount() => _repo.getItemCount();
  Future<void> removeFromCart(String serviceId) => _repo.removeFromCart(serviceId);
  Future<void> clearCart() => _repo.clearCart();

  /// Add to cart. Throws [CartCreatorMismatchException] if cart already has items from another creator.
  Future<bool> addToCart(String serviceId, String serviceProfileId) async {
    try {
      return await _repo.addToCart(serviceId, serviceProfileId);
    } on CartCreatorMismatchException {
      rethrow;
    } catch (_) {
      return false;
    }
  }
}
