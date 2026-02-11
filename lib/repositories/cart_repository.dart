import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/errors.dart';
import '../core/pricing.dart';
import '../models/service_model.dart';

/// 1 cart = 1 creator. Enforces same profile_id for all cart items.
class CartRepository {
  CartRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String?> _getOrCreateCartId({String? profileId}) async {
    if (_userId == null) return null;
    try {
      final existing = await _client.from('carts').select('id, profile_id').eq('user_id', _userId!).maybeSingle();
      if (existing != null) {
        final existingProfileId = existing['profile_id'] as String?;
        if (profileId != null && existingProfileId != null && existingProfileId != profileId) {
          throw CartCreatorMismatchException();
        }
        if (profileId != null && existingProfileId == null) {
          await _client.from('carts').update({'profile_id': profileId, 'updated_at': DateTime.now().toIso8601String()}).eq('id', existing['id']);
        }
        return existing['id'] as String;
      }
      final res = await _client.from('carts').insert({
        'user_id': _userId!,
        if (profileId != null) 'profile_id': profileId,
      }).select('id').single();
      return res['id'] as String;
    } catch (e) {
      if (e is CartCreatorMismatchException) rethrow;
      return null;
    }
  }

  /// Returns current cart profile_id if any (so UI can show "same creator only").
  Future<String?> getCartProfileId() async {
    final cartId = await _getOrCreateCartId();
    if (cartId == null) return null;
    final row = await _client.from('carts').select('profile_id').eq('id', cartId).maybeSingle();
    return row?['profile_id'] as String?;
  }

  Future<List<CartItemDto>> getCartItems() async {
    final cartId = await _getOrCreateCartId();
    if (cartId == null) return [];
    try {
      final res = await _client
          .from('cart_items')
          .select('service_id, quantity, services(*)')
          .eq('cart_id', cartId);
      final list = <CartItemDto>[];
      for (final row in res as List) {
        final map = row as Map<String, dynamic>;
        final svc = map['services'];
        if (svc != null) {
          list.add(CartItemDto(
            service: ServiceModel.fromJson(svc as Map<String, dynamic>),
            quantity: (map['quantity'] as num?)?.toInt() ?? 1,
          ));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Add service to cart. Enforces 1 creator: if cart has items from another profile, throws.
  Future<bool> addToCart(String serviceId, String serviceProfileId) async {
    final cartId = await _getOrCreateCartId(profileId: serviceProfileId);
    if (cartId == null) return false;
    try {
      await _client.from('cart_items').upsert({
        'cart_id': cartId,
        'service_id': serviceId,
        'quantity': 1,
      }, onConflict: 'cart_id,service_id');
      return true;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> removeFromCart(String serviceId) async {
    final cartId = await _getOrCreateCartId();
    if (cartId == null) return;
    await _client.from('cart_items').delete().eq('cart_id', cartId).eq('service_id', serviceId);
    final remaining = await _client.from('cart_items').select('id').eq('cart_id', cartId);
    if ((remaining as List).isEmpty) {
      await _client.from('carts').update({'profile_id': null, 'updated_at': DateTime.now().toIso8601String()}).eq('id', cartId);
    }
  }

  Future<void> clearCart() async {
    final cartId = await _getOrCreateCartId();
    if (cartId == null) return;
    await _client.from('cart_items').delete().eq('cart_id', cartId);
    await _client.from('carts').update({'profile_id': null, 'updated_at': DateTime.now().toIso8601String()}).eq('id', cartId);
  }

  Future<double> getTotalInr() async {
    final items = await getCartItems();
    final prices = <double>[];
    for (final item in items) {
      for (var i = 0; i < item.quantity; i++) {
        prices.add(item.service.priceInr);
      }
    }
    return Pricing.orderTotal(prices);
  }

  Future<int> getItemCount() async {
    final items = await getCartItems();
    return items.fold(0, (a, b) => a + b.quantity);
  }
}

class CartItemDto {
  const CartItemDto({required this.service, this.quantity = 1});
  final ServiceModel service;
  final int quantity;
}
