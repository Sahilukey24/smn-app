import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../../models/predefined_service_model.dart';

class CategoryService {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CategoryModel>> getCategoriesByRole(String roleType) async {
    try {
      final res = await _client
          .from('categories')
          .select()
          .eq('role_type', roleType)
          .order('sort_order');
      return (res as List).map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PredefinedServiceModel>> getPredefinedServices(String categoryId) async {
    try {
      final res = await _client
          .from('predefined_services')
          .select()
          .eq('category_id', categoryId)
          .order('sort_order');
      return (res as List).map((e) => PredefinedServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
