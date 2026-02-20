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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // This will NOT open the system dialog on its own in some versions,
        // but geolocator's getCurrentPosition often triggers it if service is off depending on settings.
        // Actually, we should call openLocationSettings() if we want them to enable it manually,
        // or just rely on getCurrentPosition which might prompt.
        // On Android, Geolocator.getCurrentPosition() usually triggers the "High Accuracy" prompt if possible.
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('❌ [LocationService] Error: $e');
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
