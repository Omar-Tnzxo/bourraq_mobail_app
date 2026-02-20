import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/pages/data/models/app_page_model.dart';

class PagesRepository {
  final SupabaseClient _supabase;

  PagesRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  Future<AppPageModel> getPageBySlug(String slug) async {
    try {
      final response = await _supabase
          .from('app_pages')
          .select()
          .eq('slug', slug)
          .eq('is_active', true)
          .single();

      return AppPageModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load page: $e');
    }
  }
}
