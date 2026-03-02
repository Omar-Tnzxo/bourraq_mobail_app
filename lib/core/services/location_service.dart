import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled and permissions are granted
  Future<bool> isLocationAvailable() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Request permissions and system dialog to enable location
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint(
        '📍 [LocationService] Checking location services and permissions...',
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
          '📍 [LocationService] Location services are disabled. System prompt might appear on request...',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('📍 [LocationService] Current permission: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('📍 [LocationService] Requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 [LocationService] Permission denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 [LocationService] Permission denied forever');
        // On Android, we can't show the native prompt anymore if it's denied forever
        return null;
      }

      debugPrint('📍 [LocationService] Getting position...');
      // This call usually triggers the native GMS Location Settings prompt if services are off
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      debugPrint('❌ [LocationService] Error getting current position: $e');
      if (e is LocationServiceDisabledException) {
        debugPrint('📍 [LocationService] Location Services are disabled');
      }
      return null;
    }
  }

  /// Prompt user to enable location if it's disabled
  Future<bool> requestEnableLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Open location settings
      await Geolocator.openLocationSettings();
      return false;
    }
    return true;
  }
}
