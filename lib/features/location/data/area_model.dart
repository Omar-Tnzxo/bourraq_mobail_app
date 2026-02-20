/// نموذج المنطقة المدعومة
class Area {
  final String id;
  final String nameAr;
  final String nameEn;
  final String city;
  final String governorate;
  final String? cityAr;
  final String? cityEn;
  final String? governorateAr;
  final String? governorateEn;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final double deliveryFee;
  final String estimatedDeliveryTime;
  final bool isActive;

  const Area({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.city,
    required this.governorate,
    this.cityAr,
    this.cityEn,
    this.governorateAr,
    this.governorateEn,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.deliveryFee,
    this.estimatedDeliveryTime = '30-45',
    this.isActive = true,
  });

  /// الحصول على الاسم حسب اللغة
  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;

  /// الحصول على المدينة حسب اللغة
  String getCity(String locale) =>
      locale == 'ar' ? (cityAr ?? city) : (cityEn ?? city);

  /// الحصول على المحافظة حسب اللغة
  String getGovernorate(String locale) => locale == 'ar'
      ? (governorateAr ?? governorate)
      : (governorateEn ?? governorate);

  /// إنشاء من JSON
  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      city: json['city'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      cityAr: json['city_ar'] as String?,
      cityEn: json['city_en'] as String?,
      governorateAr: json['governorate_ar'] as String?,
      governorateEn: json['governorate_en'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 3.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 25.0,
      estimatedDeliveryTime:
          json['estimated_delivery_time'] as String? ?? '30-45',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'city': city,
      'governorate': governorate,
      'city_ar': cityAr,
      'city_en': cityEn,
      'governorate_ar': governorateAr,
      'governorate_en': governorateEn,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
      'delivery_fee': deliveryFee,
      'estimated_delivery_time': estimatedDeliveryTime,
      'is_active': isActive,
    };
  }

  @override
  String toString() => 'Area(id: $id, nameAr: $nameAr, nameEn: $nameEn)';
}
