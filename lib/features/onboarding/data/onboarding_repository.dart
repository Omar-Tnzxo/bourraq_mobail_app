import 'package:supabase_flutter/supabase_flutter.dart';
import 'onboarding_screen_model.dart';

/// Repository for fetching onboarding screens from Supabase
class OnboardingRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active onboarding screens ordered by display_order
  Future<List<OnboardingScreenModel>> getOnboardingScreens() async {
    try {
      final response = await _supabase
          .from('onboarding_screens')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .limit(4); // Max 4 screens as per requirements

      return (response as List)
          .map((json) => OnboardingScreenModel.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ [OnboardingRepository] Error fetching screens: $e');
      return [];
    }
  }
}
