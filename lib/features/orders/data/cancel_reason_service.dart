import 'package:supabase_flutter/supabase_flutter.dart';

/// Model for cancel reason from Supabase
class CancelReason {
  final String id;
  final String textAr;
  final String textEn;
  final int sortOrder;

  const CancelReason({
    required this.id,
    required this.textAr,
    required this.textEn,
    required this.sortOrder,
  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    return CancelReason(
      id: json['id'] as String,
      textAr: json['text_ar'] as String,
      textEn: json['text_en'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Get localized text based on language code
  String getText(String languageCode) {
    return languageCode == 'ar' ? textAr : textEn;
  }
}

/// Service for fetching cancel reasons from Supabase
class CancelReasonService {
  final SupabaseClient _supabase;

  CancelReasonService([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client;

  /// Get all active cancel reasons ordered by sort_order
  Future<List<CancelReason>> getCancelReasons() async {
    try {
      final response = await _supabase
          .from('cancel_reasons')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List)
          .map((json) => CancelReason.fromJson(json))
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}
