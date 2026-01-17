import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SessionManager - Handles JWT token refresh and session validation
///
/// This service:
/// 1. Monitors auth state changes
/// 2. Automatically refreshes expired tokens
/// 3. Provides session validation before API calls
/// 4. Emits events when session expires (for navigation to login)
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream controller for session expiry events
  final _sessionExpiredController = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  StreamSubscription<AuthState>? _authSubscription;
  bool _isRefreshing = false;

  /// Initialize session manager - call once at app startup
  void initialize() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        debugPrint('🔴 [SESSION] User signed out or deleted');
        _sessionExpiredController.add(null);
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🟢 [SESSION] Token refreshed successfully');
      }
    });

    debugPrint('✅ [SESSION] SessionManager initialized');
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
    _sessionExpiredController.close();
  }

  /// Check if current session is valid
  bool get isSessionValid {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    return !session.isExpired;
  }

  /// Get current user ID (null if not authenticated)
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Ensure session is valid before making API calls
  /// Returns true if session is valid, false if user needs to re-login
  Future<bool> ensureValidSession() async {
    final session = _supabase.auth.currentSession;

    // No session at all
    if (session == null) {
      debugPrint('🔴 [SESSION] No session found');
      return false;
    }

    // Session is still valid
    if (!session.isExpired) {
      return true;
    }

    // Session expired, try to refresh
    return await refreshSession();
  }

  /// Attempt to refresh the session
  /// Returns true on success, false on failure
  Future<bool> refreshSession() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh
      await Future.delayed(const Duration(milliseconds: 500));
      return isSessionValid;
    }

    _isRefreshing = true;

    try {
      debugPrint('🔵 [SESSION] Attempting token refresh...');

      final response = await _supabase.auth.refreshSession();

      if (response.session != null) {
        debugPrint('✅ [SESSION] Token refreshed successfully');
        _isRefreshing = false;
        return true;
      } else {
        debugPrint('🔴 [SESSION] Refresh returned null session');
        _sessionExpiredController.add(null);
        _isRefreshing = false;
        return false;
      }
    } catch (e) {
      debugPrint('❌ [SESSION] Token refresh failed: $e');
      _sessionExpiredController.add(null);
      _isRefreshing = false;
      return false;
    }
  }

  /// Handle Supabase errors - check if JWT related and try to refresh
  /// Returns true if error was a JWT error (handled or session expired)
  /// Returns false if not a JWT error
  Future<bool> handleSupabaseError(dynamic error) async {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('jwt expired') ||
        errorStr.contains('pgrst303') ||
        errorStr.contains('invalid jwt') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('401')) {
      debugPrint('🟡 [SESSION] JWT error detected, attempting refresh...');

      // Try to refresh the session before giving up
      final refreshed = await refreshSession();

      if (refreshed) {
        debugPrint(
          '✅ [SESSION] Token refreshed after JWT error, retry operation',
        );
        return true; // Caller should retry the operation
      }

      // Refresh failed, trigger session expired
      debugPrint('🔴 [SESSION] Refresh failed, triggering session expired');
      _sessionExpiredController.add(null);
      return true;
    }

    return false;
  }

  /// Execute a Supabase operation with automatic session validation
  /// If session is expired, attempts refresh before executing
  /// Throws SessionExpiredException if refresh fails
  Future<T> executeWithSession<T>(Future<T> Function() operation) async {
    // First, ensure we have a valid session
    final isValid = await ensureValidSession();

    if (!isValid) {
      throw SessionExpiredException('Session expired. Please login again.');
    }

    try {
      return await operation();
    } catch (e) {
      // Check if it's a JWT error
      final wasJwtError = await handleSupabaseError(e);
      if (wasJwtError && !isSessionValid) {
        throw SessionExpiredException('Session expired. Please login again.');
      } else if (wasJwtError && isSessionValid) {
        // Session was refreshed successfully, retry
        return await operation();
      }
      rethrow;
    }
  }
}

/// Exception thrown when session has expired
class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException(this.message);

  @override
  String toString() => message;
}
