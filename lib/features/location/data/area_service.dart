import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'area_model.dart';

/// خدمة إدارة المناطق المدعومة - Geofencing
class AreaService {
  static const String _tableName = 'areas';
  static const double _earthRadiusKm = 6371.0;

  final SupabaseClient _supabase = Supabase.instance.client;

  /// كاش المناطق المدعومة
  List<Area>? _cachedAreas;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// جلب جميع المناطق المدعومة (مع كاش)
  Future<List<Area>> getSupportedAreas({bool forceRefresh = false}) async {
    // تحقق من الكاش
    if (!forceRefresh &&
        _cachedAreas != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedAreas!;
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('is_active', true)
          .order('name_ar');

      _cachedAreas = (response as List)
          .map((json) => Area.fromJson(json))
          .where(
            (area) =>
                area.latitude != 0 && area.longitude != 0 && area.radiusKm > 0,
          )
          .toList();
      _cacheTime = DateTime.now();

      return _cachedAreas!;
    } catch (e) {
      print('❌ [AreaService] Error fetching areas: $e');
      return _cachedAreas ?? [];
    }
  }

  /// الكشف عن المنطقة من الإحداثيات
  /// يُرجع المنطقة إذا كان الموقع داخل نطاقها، أو null إذا كان خارج كل المناطق
  Future<Area?> detectAreaFromCoordinates(double lat, double lng) async {
    final areas = await getSupportedAreas();

    Area? closestArea;
    double closestDistance = double.infinity;

    for (final area in areas) {
      final distance = calculateDistanceKm(
        lat,
        lng,
        area.latitude,
        area.longitude,
      );

      // إذا كان الموقع داخل نطاق المنطقة
      if (distance <= area.radiusKm) {
        // اختر الأقرب إذا كان هناك تداخل بين المناطق
        if (distance < closestDistance) {
          closestDistance = distance;
          closestArea = area;
        }
      }
    }

    return closestArea;
  }

  /// التحقق من أن الموقع داخل منطقة مدعومة
  Future<bool> isLocationSupported(double lat, double lng) async {
    final area = await detectAreaFromCoordinates(lat, lng);
    return area != null;
  }

  /// جلب منطقة بواسطة ID
  Future<Area?> getAreaById(String areaId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', areaId)
          .maybeSingle();

      if (response != null) {
        return Area.fromJson(response);
      }
    } catch (e) {
      print('❌ [AreaService] Error fetching area by id: $e');
    }
    return null;
  }

  /// التحقق من أن المنطقة نشطة
  Future<bool> isAreaActive(String areaId) async {
    final area = await getAreaById(areaId);
    return area?.isActive ?? false;
  }

  /// حساب المسافة بين نقطتين بالكيلومتر (Haversine Formula)
  double calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// تحويل من درجات إلى راديان
  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// مسح الكاش
  void clearCache() {
    _cachedAreas = null;
    _cacheTime = null;
  }

  /// الحصول على أقرب منطقة مدعومة (حتى لو خارج النطاق)
  Future<({Area area, double distanceKm})?> getNearestArea(
    double lat,
    double lng,
  ) async {
    final areas = await getSupportedAreas();
    if (areas.isEmpty) return null;

    Area? nearest;
    double minDistance = double.infinity;

    for (final area in areas) {
      final distance = calculateDistanceKm(
        lat,
        lng,
        area.latitude,
        area.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = area;
      }
    }

    if (nearest != null) {
      return (area: nearest, distanceKm: minDistance);
    }
    return null;
  }
}
