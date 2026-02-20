import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bourraq/core/services/session_manager.dart';
import 'package:bourraq/core/services/analytics_service.dart';

/// Auth Repository - Supabase Native OTP
class AuthRepository {
  final SupabaseClient _supabase;
  final SessionManager _sessionManager = SessionManager();

  // Web Client ID من Google Cloud Console
  static const String _webClientId =
      '2744601197-bcu7kjhv7eb5klo3vb4vlkt9ppq5gbbu.apps.googleusercontent.com';

  AuthRepository(this._supabase);

  /// تسجيل مستخدم جديد - Supabase Email OTP
  Future<void> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print('🔵 [AUTH] Starting registration with email OTP...');

      //  تخزين بيانات المستخدم مؤقتاً في metadata
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
        emailRedirectTo: null, // نستخدم OTP بدل link
      );

      if (response.user == null) {
        throw Exception('auth.error_register_failed');
      }

      // Check if user already exists (Supabase returns user with empty identities)
      // This happens when email is already registered
      if (response.user!.identities == null ||
          response.user!.identities!.isEmpty) {
        print('⚠️ [AUTH] User already exists: $email');
        throw Exception('auth.error_email_already_in_use');
      }

      print('✅ [AUTH] OTP email sent successfully via Supabase');
      print('📧 Check email: $email for OTP code');
    } on AuthException catch (e) {
      print('❌ [AUTH] Error: ${e.message}');
      if (e.message.contains('already registered')) {
        throw Exception('auth.error_email_already_in_use');
      }
      throw Exception('auth.error_otp_send_failed');
    }
  }

  /// إعادة إرسال OTP
  Future<void> resendOtp({required String email}) async {
    try {
      print('🔵 [AUTH] Resending OTP to $email...');

      await _supabase.auth.resend(type: OtpType.signup, email: email);

      print('✅ [AUTH] OTP resent successfully!');
    } on AuthException catch (e) {
      print('❌ [AUTH] Resend error: ${e.message}');
      throw Exception('auth.error_otp_send_failed');
    }
  }

  /// التحقق من OTP وإنشاء Profile
  Future<Session> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔵 [AUTH] Verifying OTP...');

      // التحقق من OTP
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      );

      if (response.session == null) {
        throw Exception('auth.error_verify_otp_failed');
      }

      final user = response.user!;
      print('✅ [AUTH] OTP verified successfully!');
      print('🔵 [AUTH] User ID: ${user.id}');
      print('🔵 [AUTH] Creating user profile...');

      // إنشاء Profile في users table
      final name = user.userMetadata?['name'] ?? '';
      final phone = user.userMetadata?['phone'] ?? '';

      try {
        // استخدام upsert لتجنب أخطاء duplicate
        await _supabase.from('users').upsert({
          'auth_user_id': user.id,
          'name': name,
          'email': email,
          'phone': phone,
          'is_email_verified': true,
          'last_login': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'auth_user_id');

        print('✅ [AUTH] User profile created/updated!');
      } catch (dbError) {
        print('⚠️ [AUTH] Failed to create profile in users table: $dbError');
        // لا نرمي exception هنا لأن الـ auth تم بنجاح
        // المستخدم يمكنه استخدام التطبيق وسيتم إنشاء profile لاحقاً
      }

      // Track signup analytics
      AnalyticsService().trackSignUp(method: 'email');
      AnalyticsService().setUserId(user.id);

      return response.session!;
    } on AuthException catch (e) {
      print('❌ [AUTH] Auth Error: ${e.message}');
      if (e.message.contains('expired')) {
        throw Exception('auth.error_otp_invalid');
      }
      if (e.message.contains('invalid')) {
        throw Exception('auth.error_otp_invalid');
      }
      throw Exception('auth.error_verify_otp_failed');
    } catch (e) {
      print('❌ [AUTH] Unexpected Error: $e');
      throw Exception('errors.general');
    }
  }

  /// تسجيل الدخول
  Future<Session> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception('auth.error_invalid_credentials');
      }

      await _supabase
          .from('users')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('auth_user_id', response.user!.id);

      // Track login analytics
      AnalyticsService().trackLogin(method: 'email');
      AnalyticsService().setUserId(response.user!.id);

      return response.session!;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception('auth.error_invalid_credentials');
      }
      throw Exception('auth.login_failed');
    }
  }

  /// تسجيل الدخول عبر Google - Native Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      print('🔵 [AUTH] Starting Google Sign-In...');

      // 1. إنشاء Google Sign-In instance
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // على Android: لا نمرر clientId، نستخدم serverClientId فقط
        // الـ SDK يأخذ client ID من google-services.json تلقائياً
        serverClientId: _webClientId,
        scopes: ['email', 'profile'],
      );

      // 2. تسجيل الدخول مع Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('⚠️ [AUTH] Google Sign-In cancelled by user');
        return false;
      }

      print('🔵 [AUTH] Google user: ${googleUser.email}');

      // 3. الحصول على authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('فشل في الحصول على ID Token');
      }

      // 4. إرسال ID Token إلى Supabase
      print('🔵 [AUTH] Sending ID Token to Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.session == null) {
        throw Exception('فشل في تسجيل الدخول');
      }

      print('✅ [AUTH] Google Sign-In successful!');

      // 5. إنشاء/تحديث user profile في جدول users
      final user = response.user;
      if (user != null) {
        await _ensureUserProfileExists(
          authUserId: user.id,
          email: user.email ?? googleUser.email,
          name: googleUser.displayName ?? '',
        );
      }

      return true;
    } on AuthException catch (e) {
      print('❌ [AUTH] Supabase Auth Error: ${e.message}');
      throw Exception('auth.error_google_login_failed');
    } catch (e) {
      print('❌ [AUTH] Google Sign-In Error: $e');
      throw Exception('auth.error_google_login_failed');
    }
  }

  /// ضمان وجود سجل المستخدم في public.users
  /// يتعامل مع حالات التعارض ويحاول طرق بديلة
  Future<void> _ensureUserProfileExists({
    required String authUserId,
    required String email,
    required String name,
  }) async {
    print('🔵 [AUTH] Ensuring user profile exists for: $authUserId');

    // المحاولة 1: upsert بناءً على auth_user_id
    try {
      await _supabase.from('users').upsert({
        'auth_user_id': authUserId,
        'email': email,
        'name': name,
        'phone': '', // Google لا يوفر رقم الهاتف
        'is_email_verified': true,
        'last_login': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'auth_user_id');
      print('✅ [AUTH] User profile created/updated via auth_user_id upsert');
      return;
    } catch (e) {
      print('⚠️ [AUTH] First upsert attempt failed: $e');
    }

    // المحاولة 2: فحص وجود سجل بنفس الـ email وتحديثه
    try {
      final existingByEmail = await _supabase
          .from('users')
          .select('id, auth_user_id')
          .eq('email', email)
          .maybeSingle();

      if (existingByEmail != null) {
        // المستخدم موجود بنفس الإيميل - تحديث auth_user_id
        print(
          '🔵 [AUTH] Found existing user by email, updating auth_user_id...',
        );
        await _supabase
            .from('users')
            .update({
              'auth_user_id': authUserId,
              'name': name,
              'is_email_verified': true,
              'last_login': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('email', email);
        print('✅ [AUTH] User profile updated via email match');
        return;
      }
    } catch (e) {
      print('⚠️ [AUTH] Email lookup/update failed: $e');
    }

    // المحاولة 3: insert مباشر
    try {
      print('🔵 [AUTH] Attempting direct insert...');
      await _supabase.from('users').insert({
        'auth_user_id': authUserId,
        'email': email,
        'name': name,
        'phone': '',
        'is_email_verified': true,
        'last_login': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print('✅ [AUTH] User profile created via direct insert');
      return;
    } catch (e) {
      print('❌ [AUTH] All attempts to create user profile failed!');
      print('❌ [AUTH] Final error: $e');
      // لا نرمي exception لأن Auth نجح - المستخدم يمكنه استخدام التطبيق
      // الـ sync سيحاول مرة أخرى في Splash Screen
    }
  }

  Future<void> logout() async {
    await AnalyticsService().trackLogout();
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() => _supabase.auth.currentUser;

  Session? getCurrentSession() => _supabase.auth.currentSession;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> deleteAccount(String userId) async {
    try {
      // Track account deletion
      await AnalyticsService().trackDeleteAccount();

      // Call the secure RPC function
      await _supabase.rpc('delete_user_account');

      // Sign out locally
      await _supabase.auth.signOut();
    } catch (e) {
      print('❌ [AUTH] Delete Account Error: $e');
      throw Exception('auth.error_delete_account_failed');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PASSWORD RESET METHODS
  // ═══════════════════════════════════════════════════════════════

  /// إرسال OTP لاستعادة كلمة المرور - يستخدم Supabase signInWithOtp
  Future<void> sendPasswordResetOTP({required String email}) async {
    try {
      print('🔵 [AUTH] Sending password reset OTP...');

      // استخدام signInWithOtp - يرسل OTP (6 أرقام) مثل التسجيل
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // لا نريد إنشاء مستخدم جديد
      );

      print('✅ [AUTH] Password reset OTP sent');
      print('📧 Check email: $email for OTP code');
    } on AuthException catch (e) {
      print('❌ [AUTH] Auth Error: ${e.message}');
      if (e.message.contains('not found') ||
          e.message.contains('User not found') ||
          e.message.contains('Unable to validate')) {
        throw Exception('auth.error_invalid_credentials');
      }
      throw Exception('auth.error_otp_send_failed');
    } catch (e) {
      print('❌ [AUTH] Error: $e');
      throw Exception('errors.general');
    }
  }

  /// التحقق من OTP لاستعادة كلمة المرور
  Future<void> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    try {
      print('🔵 [AUTH] Verifying password reset OTP...');

      // التحقق من OTP عبر Supabase
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (response.session == null) {
        throw Exception('auth.error_otp_invalid');
      }

      print('✅ [AUTH] Password reset OTP verified');
    } on AuthException catch (e) {
      print('❌ [AUTH] Auth Error: ${e.message}');
      if (e.message.contains('expired')) {
        throw Exception('auth.error_otp_invalid');
      }
      if (e.message.contains('invalid')) {
        throw Exception('auth.error_otp_invalid');
      }
      throw Exception('auth.error_otp_invalid');
    } catch (e) {
      print('❌ [AUTH] Error: $e');
      rethrow;
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print('🔵 [AUTH] Resetting password...');

      // تحديث كلمة المرور - المستخدم مسجل دخول بعد verifyOTP
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      print('✅ [AUTH] Password reset successfully');
    } on AuthException catch (e) {
      print('❌ [AUTH] Auth error: ${e.message}');
      if (e.message.contains('different from the old password')) {
        throw Exception(
          'auth.error_password_same_as_old',
        ); // Will be translated
      }
      throw Exception('auth.error_password_reset_failed');
    } catch (e) {
      print('❌ [AUTH] Error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EMAIL CHANGE METHODS
  // ═══════════════════════════════════════════════════════════════

  /// طلب تغيير البريد الإلكتروني (يرسل OTP للبريد الجديد)
  Future<void> updateEmail({required String newEmail}) async {
    try {
      print('🔵 [AUTH] Requesting email change to: $newEmail');

      // Ensure session is fresh
      final session = _supabase.auth.currentSession;
      if (session == null || session.isExpired) {
        print('⚠️ [AUTH] Session expired or null. Refreshing...');
        await _supabase.auth.refreshSession();
      }

      final response = await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      if (response.user == null) {
        throw Exception('auth.error_update_email_failed');
      }

      print('✅ [AUTH] Email change requested. OTP sent to $newEmail');
    } on AuthException catch (e) {
      print('❌ [AUTH] Update User Error: ${e.message}');
      if (e.message.contains('already registered')) {
        throw Exception('auth.error_email_already_in_use');
      }
      // Handle "Invalid JWT" or "Unauthorized" specifically if needed
      if (e.message.contains('Invalid JWT') ||
          e.message.contains('Unauthorized')) {
        // Attempt one more refresh and retry
        try {
          print(
            '⚠️ [AUTH] Invalid JWT on update. Retrying after force refresh...',
          );
          await _supabase.auth.refreshSession();
          final retryResponse = await _supabase.auth.updateUser(
            UserAttributes(email: newEmail),
          );
          if (retryResponse.user != null) {
            print('✅ [AUTH] Retry successful. OTP sent.');
            return;
          }
        } catch (retryError) {
          print('❌ [AUTH] Retry failed: $retryError');
        }
      }
      throw Exception('auth.error_update_email_failed');
    } catch (e) {
      print('❌ [AUTH] Error: $e');
      rethrow;
    }
  }

  /// التحقق من OTP وتثبيت البريد الجديد
  Future<void> verifyEmailChange({
    required String newEmail,
    required String otp,
  }) async {
    try {
      print('🔵 [AUTH] Verifying email change OTP...');

      final response = await _supabase.auth.verifyOTP(
        email: newEmail,
        token: otp,
        type: OtpType.emailChange,
      );

      if (response.session == null) {
        throw Exception('auth.error_otp_invalid');
      }

      final user = response.user!;
      print('✅ [AUTH] Email change verified successfully');

      // Manual sync to public.users
      print('🔵 [AUTH] Syncing new email to public.users...');
      await _supabase
          .from('users')
          .update({'email': newEmail, 'auth_user_id': user.id})
          .eq('auth_user_id', user.id);

      print('✅ [AUTH] public.users synced successfully');
    } on AuthException catch (e) {
      print('❌ [AUTH] Verify Error: ${e.message}');
      if (e.message.contains('invalid') || e.message.contains('expired')) {
        throw Exception('auth.error_otp_invalid');
      }
      throw Exception('auth.error_verify_email_failed');
    } catch (e) {
      print('❌ [AUTH] Error: $e');
      rethrow;
    }
  }

  /// تحديث الملف الشخصي
  Future<void> updateProfile({
    required String userId,
    required String name,
    String? phone,
  }) async {
    try {
      print('🔵 [AUTH] Updating profile for user: $userId');

      await _supabase
          .from('users')
          .update({
            'name': name,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('auth_user_id', userId);

      print('✅ [AUTH] Profile updated successfully');
    } catch (e) {
      print('❌ [AUTH] Error updating profile: $e');
      throw Exception('auth.error_update_profile_failed');
    }
  }

  /// جلب بيانات المستخدم
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      // Ensure session is valid before fetching user
      final isValid = await _sessionManager.ensureValidSession();
      if (!isValid) {
        print('🔴 [AUTH] Session expired, cannot fetch user');
        return null;
      }

      print('🔵 [AUTH] Fetching user data: $userId');

      final response = await _supabase
          .from('users')
          .select()
          .eq('auth_user_id', userId)
          .maybeSingle();

      print('✅ [AUTH] User data fetched: ${response != null}');
      return response;
    } catch (e) {
      // Handle JWT errors gracefully - try refresh first
      await _sessionManager.handleSupabaseError(e);
      print('❌ [AUTH] Error fetching user: $e');
      return null;
    }
  }
}
