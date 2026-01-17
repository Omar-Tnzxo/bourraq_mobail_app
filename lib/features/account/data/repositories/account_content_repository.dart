import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_code_model.dart';
import '../models/faq_model.dart';

class AccountContentRepository {
  final SupabaseClient _supabase;

  AccountContentRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Cache for public.users.id
  String? _cachedPublicUserId;

  /// Get public.users.id from auth_user_id
  Future<String?> _getPublicUserId() async {
    if (_cachedPublicUserId != null) return _cachedPublicUserId;

    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (response != null) {
        _cachedPublicUserId = response['id'] as String;
        return _cachedPublicUserId;
      }
    } catch (e) {
      // User might not exist in public.users table
    }
    return null;
  }

  /// Fetch active promo codes
  Future<List<PromoCode>> getPromoCodes() async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .select()
          .eq('is_active', true)
          .gt('expiry_date', DateTime.now().toIso8601String());

      return (response as List)
          .map((json) => PromoCode.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch promo codes: $e');
    }
  }

  /// Fetch FAQs ordered by display_order
  Future<List<Faq>> getFaqs() async {
    try {
      final response = await _supabase
          .from('faqs')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List).map((json) => Faq.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch FAQs: $e');
    }
  }

  /// Submit a new area request
  Future<void> submitAreaRequest({
    required String governorate,
    required String city,
    required String areaName,
    String? additionalInfo,
  }) async {
    try {
      // Get the public.users.id (not auth.users.id)
      final userId = await _getPublicUserId();

      await _supabase.from('area_requests').insert({
        'user_id': userId,
        'governorate': governorate,
        'city': city,
        'area_name': areaName,
        'additional_info': additionalInfo,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit area request: $e');
    }
  }
}
