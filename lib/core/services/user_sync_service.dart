import 'package:supabase_flutter/supabase_flutter.dart';

/// خدمة مزامنة بيانات المستخدم
/// تضمن وجود سجل في public.users لكل مستخدم مسجل دخول
class UserSyncService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// مزامنة المستخدم الحالي - لو مسجل دخول ومفيش سجل في public.users ينشئ واحد
  /// يرجع true لو نجحت المزامنة أو المستخدم موجود، false لو فشلت
  Future<bool> syncCurrentUser() async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        print('⚠️ [UserSync] No authenticated user');
        return false;
      }

      print('🔵 [UserSync] Syncing user: ${authUser.id}');

      // فحص إذا كان المستخدم موجود بالفعل
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (existingUser != null) {
        // المستخدم موجود - تحديث last_login فقط
        print('✅ [UserSync] User already exists, updating last_login');
        await _supabase
            .from('users')
            .update({'last_login': DateTime.now().toUtc().toIso8601String()})
            .eq('auth_user_id', authUser.id);
        return true;
      }

      // المستخدم غير موجود - إنشاء سجل جديد
      return await _createUserProfile(authUser);
    } catch (e) {
      print('❌ [UserSync] Error syncing user: $e');
      return false;
    }
  }

  /// إنشاء سجل مستخدم جديد مع محاولات متعددة
  Future<bool> _createUserProfile(User authUser) async {
    // استخراج البيانات من auth user
    final metadata = authUser.userMetadata ?? {};
    final name =
        metadata['full_name'] ??
        metadata['name'] ??
        metadata['display_name'] ??
        authUser.email?.split('@').first ??
        '';

    final phone = metadata['phone'] ?? metadata['phone_number'] ?? '';

    // المحاولة 1: upsert
    try {
      await _supabase.from('users').upsert({
        'auth_user_id': authUser.id,
        'email': authUser.email ?? '',
        'name': name,
        'phone': phone,
        'is_email_verified': authUser.emailConfirmedAt != null,
        'last_login': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_user_id');
      print('✅ [UserSync] User synced successfully via upsert');
      return true;
    } catch (e) {
      print('⚠️ [UserSync] Upsert failed: $e');
    }

    // المحاولة 2: فحص وجود المستخدم بالإيميل
    if (authUser.email != null && authUser.email!.isNotEmpty) {
      try {
        final existingByEmail = await _supabase
            .from('users')
            .select('id')
            .eq('email', authUser.email!)
            .maybeSingle();

        if (existingByEmail != null) {
          // المستخدم موجود بنفس الإيميل - تحديث auth_user_id
          print('🔵 [UserSync] Found by email, updating auth_user_id...');
          await _supabase
              .from('users')
              .update({
                'auth_user_id': authUser.id,
                'is_email_verified': authUser.emailConfirmedAt != null,
                'last_login': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('email', authUser.email!);
          print('✅ [UserSync] User synced via email match');
          return true;
        }
      } catch (e) {
        print('⚠️ [UserSync] Email lookup failed: $e');
      }
    }

    // المحاولة 3: insert مباشر
    try {
      await _supabase.from('users').insert({
        'auth_user_id': authUser.id,
        'email': authUser.email ?? '',
        'name': name,
        'phone': phone,
        'is_email_verified': authUser.emailConfirmedAt != null,
        'last_login': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print('✅ [UserSync] User created via direct insert');
      return true;
    } catch (insertError) {
      print('❌ [UserSync] All sync attempts failed: $insertError');
      return false;
    }
  }
}
