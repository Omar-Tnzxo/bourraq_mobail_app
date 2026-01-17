import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ConnectivityService - Manages network connectivity status
///
/// Singleton service that:
/// 1. Monitors network connectivity changes
/// 2. Provides stream for UI updates
/// 3. Offers quick isOnline check
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  // Stream controller for connectivity status
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get onStatusChange => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);

    debugPrint('✅ [CONNECTIVITY] Service initialized, online: $_isOnline');
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Consider online if any connection is available (not none)
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      debugPrint(
        '🌐 [CONNECTIVITY] Status changed: ${_isOnline ? "ONLINE" : "OFFLINE"}',
      );
      _statusController.add(_isOnline);
    }
  }

  /// Check connectivity (useful for one-time checks)
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    return _isOnline;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
