/// نموذج العنوان - متوافق مع Supabase user_addresses table
class Address {
  final String id;
  final String userId;
  final String addressType; // home, work, other
  final String? areaId;
  final double latitude;
  final double longitude;
  final String? buildingName;
  final String? apartmentNumber;
  final String? floorNumber;
  final String? streetName;
  final String? landmark;
  final String addressLabel; // "المنزل", "العمل", etc.
  final String? phone;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    required this.id,
    required this.userId,
    required this.addressType,
    this.areaId,
    required this.latitude,
    required this.longitude,
    this.buildingName,
    this.apartmentNumber,
    this.floorNumber,
    this.streetName,
    this.landmark,
    required this.addressLabel,
    this.phone,
    this.isDefault = false,
    required this.createdAt,
  });

  /// إنشاء من Supabase JSON
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      addressType: json['address_type'] as String? ?? 'home',
      areaId: json['area_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      buildingName: json['building_name'] as String?,
      apartmentNumber: json['apartment_number'] as String?,
      floorNumber: json['floor_number'] as String?,
      streetName: json['street_name'] as String?,
      landmark: json['landmark'] as String?,
      addressLabel: json['address_label'] as String? ?? 'عنوان',
      phone: json['phone'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// تحويل إلى Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'address_type': addressType,
      'area_id': areaId,
      'latitude': latitude,
      'longitude': longitude,
      'building_name': buildingName,
      'apartment_number': apartmentNumber,
      'floor_number': floorNumber,
      'street_name': streetName,
      'landmark': landmark,
      'address_label': addressLabel,
      'phone': phone,
      'is_default': isDefault,
    };
  }

  /// نسخة معدلة
  Address copyWith({
    String? id,
    String? userId,
    String? addressType,
    String? areaId,
    double? latitude,
    double? longitude,
    String? buildingName,
    String? apartmentNumber,
    String? floorNumber,
    String? streetName,
    String? landmark,
    String? addressLabel,
    String? phone,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      addressType: addressType ?? this.addressType,
      areaId: areaId ?? this.areaId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      buildingName: buildingName ?? this.buildingName,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      floorNumber: floorNumber ?? this.floorNumber,
      streetName: streetName ?? this.streetName,
      landmark: landmark ?? this.landmark,
      addressLabel: addressLabel ?? this.addressLabel,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// العنوان الكامل للعرض
  String getFullAddress(String locale) {
    final parts = <String>[];
    if (streetName != null && streetName!.isNotEmpty) parts.add(streetName!);
    if (buildingName != null && buildingName!.isNotEmpty) {
      parts.add(buildingName!);
    }
    if (landmark != null && landmark!.isNotEmpty) parts.add(landmark!);

    if (parts.isNotEmpty) {
      final separator = locale == 'ar' ? '، ' : ', ';
      return parts.join(separator);
    }
    return locale == 'ar' ? 'موقع محدد على الخريطة' : 'Location on map';
  }

  /// تفاصيل المبنى
  String? getBuildingDetails(String locale) {
    final parts = <String>[];
    final floorLabel = locale == 'ar' ? 'الطابق' : 'Floor';
    final aptLabel = locale == 'ar' ? 'الشقة' : 'Apt';

    if (floorNumber != null && floorNumber!.isNotEmpty) {
      parts.add('$floorLabel: $floorNumber');
    }
    if (apartmentNumber != null && apartmentNumber!.isNotEmpty) {
      parts.add('$aptLabel: $apartmentNumber');
    }
    return parts.isNotEmpty ? parts.join(' • ') : null;
  }

  /// Backward compatibility getters (default Arabic)
  String get fullAddress => getFullAddress('ar');
  String? get buildingDetails => getBuildingDetails('ar');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Address(id: $id, label: $addressLabel, isDefault: $isDefault)';
}
