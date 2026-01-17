import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// ErrorHandler - Converts technical errors to user-friendly translation keys
///
/// This utility maps various exception types and error messages to
/// appropriate translation keys that can be displayed to users.
class ErrorHandler {
  /// Get a user-friendly error translation key from any exception
  static String getErrorKey(dynamic error) {
    final message = error.toString().toLowerCase();

    // Handle specific exception types first
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    if (error is SocketException) {
      return 'errors.network';
    }

    // Network/Connection errors
    if (_isNetworkError(message)) {
      return 'errors.network';
    }

    // Timeout errors
    if (_isTimeoutError(message)) {
      return 'errors.timeout';
    }

    // Server errors
    if (_isServerError(message)) {
      return 'errors.server';
    }

    // Not found errors
    if (_isNotFoundError(message)) {
      return 'errors.not_found';
    }

    // Default fallback
    return 'errors.general';
  }

  /// Handle Supabase Auth errors
  static String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login') ||
        message.contains('credentials') ||
        message.contains('invalid email or password')) {
      return 'auth.errors.invalid_credentials';
    }

    if (message.contains('already registered') ||
        message.contains('already in use')) {
      return 'auth.errors.email_already_in_use';
    }

    if (message.contains('expired')) {
      return 'auth.errors.otp_invalid';
    }

    if (message.contains('invalid') && message.contains('otp')) {
      return 'auth.errors.otp_invalid';
    }

    if (message.contains('rate limit')) {
      return 'errors.rate_limit';
    }

    if (message.contains('jwt') || message.contains('token')) {
      return 'common.session_expired';
    }

    return 'errors.general';
  }

  /// Handle Supabase Postgrest errors
  static String _handlePostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();

    if (message.contains('connection') || message.contains('network')) {
      return 'errors.network';
    }

    if (message.contains('not found') || error.code == 'PGRST116') {
      return 'errors.not_found';
    }

    if (message.contains('timeout')) {
      return 'errors.timeout';
    }

    return 'errors.server';
  }

  /// Check if error is network-related
  static bool _isNetworkError(String message) {
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection refused') ||
        message.contains('connection failed') ||
        message.contains('no internet') ||
        message.contains('unreachable') ||
        message.contains('failed host lookup') ||
        message.contains('errno = 7') || // Connection refused
        message.contains('errno = 101') || // Network unreachable
        message.contains('errno = 110'); // Connection timed out
  }

  /// Check if error is timeout-related
  static bool _isTimeoutError(String message) {
    return message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('time out');
  }

  /// Check if error is server-related
  static bool _isServerError(String message) {
    return message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('504') ||
        message.contains('internal server') ||
        message.contains('bad gateway') ||
        message.contains('service unavailable');
  }

  /// Check if error is not-found-related
  static bool _isNotFoundError(String message) {
    return message.contains('not found') ||
        message.contains('404') ||
        message.contains('does not exist');
  }

  /// Log error for debugging without exposing to user
  static void logError(dynamic error, {String? context}) {
    // Only log in debug mode
    assert(() {
      final contextStr = context != null ? '[$context] ' : '';
      print('❌ ${contextStr}Error: $error');
      return true;
    }());
  }
}
