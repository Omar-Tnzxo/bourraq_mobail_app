import 'package:supabase_flutter/supabase_flutter.dart';

class DbHelper {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Resets the database state for a fresh test run by calling the seed script.
  /// Note: In a real Supabase environment, this might require a custom RPC or edge function
  /// if Direct SQL is restricted for security. For QA purposes, we assume access.
  static Future<void> resetToSeed() async {
    // Note: Actual logic depends on how seed.sql is exposed.
    // Usually, we'd use a reset function or delete/insert via RPC.
    try {
      await _client.rpc('reset_test_data');
    } catch (e) {
      print(
        'Warning: reset_test_data RPC not found. Ensure it is defined in Supabase.',
      );
    }
  }

  /// Verifies current pilot debt in the database.
  static Future<double> getPilotDebt(String pilotId) async {
    final response = await _client
        .from('pilots')
        .select('debt_amount')
        .eq('id', pilotId)
        .single();
    return (response['debt_amount'] as num).toDouble();
  }

  /// Updates product availability for FR-027 tests.
  static Future<void> setProductAvailability(
    int productId,
    bool isAvailable,
  ) async {
    await _client
        .from('partner_products')
        .update({'is_available': isAvailable})
        .eq('id', productId);
  }
}
