import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bourraq/core/utils/error_handler.dart';
import 'models/contact_option_model.dart';

/// Service for fetching and managing dynamic contact options from Supabase.
///
/// Contact options are cached after first fetch and can be refreshed manually.
class ContactOptionService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ContactOption> _options = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  /// List of all active contact options
  List<ContactOption> get options => _options;

  /// Whether options are currently being loaded
  bool get isLoading => _isLoading;

  /// Error message if fetch failed
  String? get error => _error;

  /// Whether options have been fetched at least once
  bool get hasFetched => _hasFetched;

  /// Fetches all active contact options from Supabase.
  ///
  /// Results are cached. Use [forceRefresh] to bypass cache.
  Future<void> fetchOptions({bool forceRefresh = false}) async {
    // Return cached data if available and not forcing refresh
    if (_hasFetched && !forceRefresh && _options.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('contact_options')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      _options = (response as List)
          .map((json) => ContactOption.fromJson(json))
          .toList();
      _hasFetched = true;
      _error = null;
    } catch (e) {
      _error = ErrorHandler.getErrorKey(e);
      debugPrint('Error fetching contact options: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the cached options
  void clearCache() {
    _options = [];
    _hasFetched = false;
    notifyListeners();
  }
}
