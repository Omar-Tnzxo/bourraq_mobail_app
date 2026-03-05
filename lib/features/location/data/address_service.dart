import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/services/cache_service.dart';
import 'address_model.dart';

/// خدمة إدارة العناوين - متصلة بـ Supabase
class AddressService {
  static const int maxAddresses = 5;
  static const String _tableName = 'user_addresses';

  final SupabaseClient _supabase = Supabase.instance.client;

  /// كاش للـ public.users.id
  String? _cachedPublicUserId;

  /// الحصول على auth user id
  String? get _authUserId => _supabase.auth.currentUser?.id;

  /// جلب public.users.id من auth_user_id
  /// إذا لم يوجد سجل، يتم إنشاؤه تلقائياً
  Future<String?> _getPublicUserId() async {
    // لو موجود في الكاش، ارجعه
    if (_cachedPublicUserId != null) return _cachedPublicUserId;

    final authId = _authUserId;
    if (authId == null) return null;

    try {
      // محاولة جلب السجل الموجود
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (response != null) {
        _cachedPublicUserId = response['id'] as String;
        return _cachedPublicUserId;
      }

      // السجل غير موجود - ننشئه تلقائياً
      print('⚠️ [AddressService] User not found in public.users, creating...');

      final authUser = _supabase.auth.currentUser;
      if (authUser == null) return null;

      // إنشاء سجل جديد للمستخدم
      final insertResponse = await _supabase
          .from('users')
          .insert({
            'auth_user_id': authId,
            'email': authUser.email ?? '',
            'name':
                authUser.userMetadata?['full_name'] ??
                authUser.userMetadata?['name'] ??
                authUser.email?.split('@').first ??
                '',
            'phone': authUser.userMetadata?['phone'] ?? '',
            'is_email_verified': authUser.emailConfirmedAt != null,
            'last_login': DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      _cachedPublicUserId = insertResponse['id'] as String;
      print('✅ [AddressService] User record created: $_cachedPublicUserId');
      return _cachedPublicUserId;
    } catch (e) {
      print('❌ [AddressService] Error getting/creating public user id: $e');

      // محاولة أخيرة - ربما تم إنشاء السجل بالتوازي
      try {
        final retryResponse = await _supabase
            .from('users')
            .select('id')
            .eq('auth_user_id', authId)
            .maybeSingle();

        if (retryResponse != null) {
          _cachedPublicUserId = retryResponse['id'] as String;
          return _cachedPublicUserId;
        }
      } catch (_) {}
    }
    return null;
  }

  /// جلب جميع العناوين للمستخدم الحالي
  Future<List<Address>> getAddresses() async {
    final userId = await _getPublicUserId();
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from(_tableName)
          .select('*, areas(*)')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Address.fromJson(json)).toList();
    } catch (e) {
      print('❌ [AddressService] Error fetching addresses: $e');
      return [];
    }
  }

  /// الحصول على العنوان الافتراضي
  Future<Address?> getDefaultAddress() async {
    final userId = await _getPublicUserId();
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from(_tableName)
          .select('*, areas(*)')
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (response != null) {
        return Address.fromJson(response);
      }

      // لو مفيش عنوان افتراضي، رجّع أول عنوان
      final firstResponse = await _supabase
          .from(_tableName)
          .select('*, areas(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return firstResponse != null ? Address.fromJson(firstResponse) : null;
    } catch (e) {
      print('❌ [AddressService] Error getting default address: $e');
      return null;
    }
  }

  /// الحصول على معرف المنطقة النشط (للمستخدم أو الضيف)
  Future<String?> getActiveAreaId() async {
    // 1. محاولة الحصول عليه من العنوان الافتراضي للمستخدم المسجل
    final defaultAddress = await getDefaultAddress();
    if (defaultAddress?.areaId != null) {
      return defaultAddress!.areaId;
    }

    // 2. محاولة الحصول عليه من الكاش المحلي (للضيف)
    try {
      final fromCache = CacheService().get<String>('active_area_id');
      return fromCache;
    } catch (_) {
      return null;
    }
  }

  /// تعيين معرف المنطقة النشط يدوياً (للتخزين المؤقت)
  Future<void> setActiveAreaId(String areaId) async {
    await CacheService().set('active_area_id', areaId);
  }

  /// نتيجة إضافة عنوان
  static const String resultSuccess = 'success';
  static const String resultUserNotFound = 'user_not_found';
  static const String resultMaxReached = 'max_reached';
  static const String resultError = 'error';

  /// إضافة عنوان جديد - ترجع نوع النتيجة
  Future<String> addAddress({
    required String addressLabel,
    required String addressType,
    String? streetName,
    String? buildingName,
    String? floorNumber,
    String? apartmentNumber,
    String? landmark,
    String? phone,
    required double latitude,
    required double longitude,
    String? areaId,
    bool setAsDefault = false,
  }) async {
    final userId = await _getPublicUserId();
    if (userId == null) {
      print('❌ [AddressService] User not found in database');
      return resultUserNotFound;
    }

    try {
      // تحقق من الحد الأقصى
      final currentAddresses = await getAddresses();
      if (currentAddresses.length >= maxAddresses) {
        print('❌ [AddressService] Max addresses reached ($maxAddresses)');
        return resultMaxReached;
      }

      // إذا كان هذا أول عنوان أو setAsDefault، اجعله افتراضي
      final shouldBeDefault = currentAddresses.isEmpty || setAsDefault;

      // إذا كان سيصبح افتراضي، أزل الافتراضي من الباقي
      if (shouldBeDefault && currentAddresses.isNotEmpty) {
        await _supabase
            .from(_tableName)
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      // إضافة العنوان الجديد
      await _supabase.from(_tableName).insert({
        'user_id': userId,
        'address_type': addressType,
        'address_label': addressLabel,
        'street_name': streetName,
        'building_name': buildingName,
        'floor_number': floorNumber,
        'apartment_number': apartmentNumber,
        'landmark': landmark,
        'phone': phone,
        'latitude': latitude,
        'longitude': longitude,
        'area_id': areaId,
        'is_default': shouldBeDefault,
      });

      print('✅ [AddressService] Address added: $addressLabel');
      return resultSuccess;
    } catch (e) {
      print('❌ [AddressService] Error adding address: $e');
      return resultError;
    }
  }

  /// تحديث عنوان
  Future<bool> updateAddress(Address address) async {
    final userId = await _getPublicUserId();
    if (userId == null) return false;

    try {
      // إذا سيصبح افتراضي، أزل الافتراضي من الباقي
      if (address.isDefault) {
        await _supabase
            .from(_tableName)
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', address.id);
      }

      await _supabase
          .from(_tableName)
          .update(address.toJson())
          .eq('id', address.id)
          .eq('user_id', userId);

      print('✅ [AddressService] Address updated: ${address.addressLabel}');
      return true;
    } catch (e) {
      print('❌ [AddressService] Error updating address: $e');
      return false;
    }
  }

  /// تعيين عنوان كافتراضي
  Future<bool> setDefaultAddress(String addressId) async {
    final userId = await _getPublicUserId();
    if (userId == null) return false;

    try {
      // أزل الافتراضي من كل العناوين
      await _supabase
          .from(_tableName)
          .update({'is_default': false})
          .eq('user_id', userId);

      // عيّن العنوان الجديد كافتراضي
      await _supabase
          .from(_tableName)
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);

      print('✅ [AddressService] Default address set: $addressId');
      return true;
    } catch (e) {
      print('❌ [AddressService] Error setting default: $e');
      return false;
    }
  }

  /// حذف عنوان
  Future<bool> deleteAddress(String addressId) async {
    final userId = await _getPublicUserId();
    if (userId == null) return false;

    try {
      // احصل على العنوان المحذوف لنعرف لو كان افتراضي
      final addressResponse = await _supabase
          .from(_tableName)
          .select('is_default')
          .eq('id', addressId)
          .eq('user_id', userId)
          .maybeSingle();

      final wasDefault = addressResponse?['is_default'] == true;

      // احذف العنوان
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);

      // إذا كان العنوان المحذوف هو الافتراضي، اجعل أول عنوان متبقي افتراضي
      if (wasDefault) {
        final remaining = await getAddresses();
        if (remaining.isNotEmpty) {
          await setDefaultAddress(remaining.first.id);
        }
      }

      print('✅ [AddressService] Address deleted: $addressId');
      return true;
    } catch (e) {
      print('❌ [AddressService] Error deleting address: $e');
      return false;
    }
  }

  /// هل يمكن إضافة عنوان جديد؟
  Future<bool> canAddMoreAddresses() async {
    final addresses = await getAddresses();
    return addresses.length < maxAddresses;
  }

  /// عدد العناوين المتبقية
  Future<int> getRemainingAddressSlots() async {
    final addresses = await getAddresses();
    return maxAddresses - addresses.length;
  }
}
