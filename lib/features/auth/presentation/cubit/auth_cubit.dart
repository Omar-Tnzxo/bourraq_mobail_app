import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bourraq/features/auth/data/auth_repository.dart';
import 'auth_state.dart';

/// Auth Cubit - يدير حالة المصادقة في التطبيق
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial()) {
    _checkAuthStatus();
  }

  /// فحص حالة المصادقة عند بدء التطبيق
  Future<void> _checkAuthStatus() async {
    try {
      final user = _authRepository.getCurrentUser();
      final session = _authRepository.getCurrentSession();

      if (session != null && user != null) {
        // 1. Fetch User Profile from public.users
        final userProfile = await _authRepository.getUser(user.id);

        // 2. Determine Auth Provider
        String provider = 'email';
        if (user.appMetadata['provider'] != null) {
          provider = user.appMetadata['provider'] as String;
          // Fallback check identities
          provider = user.identities!.first.provider;
        }

        emit(
          AuthAuthenticated(
            userId: user.id, // Auth User ID
            email: user.email ?? '',
            name: userProfile?['name'] ?? user.userMetadata?['name'] ?? '',
            phone: userProfile?['phone'] ?? user.userMetadata?['phone'],
            authProvider: provider,
          ),
        );
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ [AuthCubit] Check Status Error: $e');
      emit(const AuthUnauthenticated());
    }
  }

  /// تسجيل مستخدم جديد (إرسال OTP)
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    print('🟢 [CUBIT] register() called');
    emit(const AuthLoading());

    try {
      print('🟢 [CUBIT] Calling AuthRepository.registerUser...');
      await _authRepository.registerUser(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      print('🟢 [CUBIT] Success! Emitting AuthOtpSent...');
      emit(AuthOtpSent(email: email));
    } catch (e) {
      print('🔴 [CUBIT] Error caught: $e');
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// التحقق من OTP
  Future<void> verifyOtpAndCreateAccount({
    required String email,
    required String otp,
    required String name,
    required String phone,
    required String password,
  }) async {
    emit(const AuthLoading());

    try {
      await _authRepository.verifyOTP(email: email, otp: otp);

      final user = _authRepository.getCurrentUser();

      if (user != null) {
        emit(
          AuthAuthenticated(
            userId: user.id,
            email: user.email ?? email,
            name: name,
          ),
        );
      } else {
        emit(const AuthError(message: 'فشل في الحصول على بيانات المستخدم'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// إعادة إرسال OTP
  Future<void> resendOtp(String email) async {
    try {
      await _authRepository.resendOtp(email: email);
      emit(AuthOtpSent(email: email));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<void> loginWithEmail(String email, String password) async {
    emit(const AuthLoading());

    try {
      await _authRepository.loginUser(email: email, password: password);

      final user = _authRepository.getCurrentUser();

      if (user != null) {
        // Fetch user profile from public.users (like Google login does)
        final userProfile = await _authRepository.getUser(user.id);

        emit(
          AuthAuthenticated(
            userId: user.id,
            email: user.email ?? email,
            name: userProfile?['name'] ?? user.userMetadata?['name'] ?? '',
            phone: userProfile?['phone'] ?? user.userMetadata?['phone'],
            authProvider: 'email',
          ),
        );
      } else {
        emit(const AuthError(message: 'فشل في الحصول على بيانات المستخدم'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// تسجيل الدخول عبر Google
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());

    try {
      final success = await _authRepository.signInWithGoogle();

      if (success) {
        // الحصول على بيانات المستخدم
        final user = _authRepository.getCurrentUser();
        final userProfile = user != null
            ? await _authRepository.getUser(user.id)
            : null;

        if (user != null) {
          emit(
            AuthAuthenticated(
              userId: user.id,
              email: user.email ?? '',
              name:
                  userProfile?['name'] ??
                  user.userMetadata?['name'] ??
                  user.userMetadata?['full_name'] ??
                  '',
              authProvider: 'google',
              phone: userProfile?['phone'],
            ),
          );
        } else {
          emit(const AuthError(message: 'فشل في الحصول على بيانات المستخدم'));
        }
      } else {
        emit(const AuthError(message: 'فشل في تسجيل الدخول عبر Google'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PASSWORD RESET METHODS
  // ═══════════════════════════════════════════════════════════════

  /// إرسال OTP لاستعادة كلمة المرور
  Future<void> sendPasswordResetOTP(String email) async {
    emit(const AuthLoading());

    try {
      await _authRepository.sendPasswordResetOTP(email: email);
      emit(AuthPasswordResetOtpSent(email: email));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// التحقق من OTP لاستعادة كلمة المرور
  Future<void> verifyPasswordResetOTP({
    required String email,
    required String otp,
  }) async {
    emit(const AuthLoading());

    try {
      await _authRepository.verifyPasswordResetOTP(email: email, otp: otp);
      emit(const AuthPasswordResetOtpVerified());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    emit(const AuthLoading());

    try {
      await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      emit(const AuthPasswordResetSuccess());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GUEST MODE
  // ═══════════════════════════════════════════════════════════════

  /// Enter guest mode (browse without account)
  void enterGuestMode() {
    emit(const AuthGuest());
  }

  /// Check if current user is a guest
  bool get isGuest => state is AuthGuest;

  /// Check if current user is authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  // ═══════════════════════════════════════════════════════════════
  // OTHER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Check auth status (للاستخدام في Splash)
  Future<void> checkAuthStatus() async {
    await _checkAuthStatus();
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// حذف الحساب
  Future<void> deleteAccount() async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(const AuthError(message: 'لا يوجد مستخدم مسجل دخول'));
      return;
    }

    try {
      await _authRepository.deleteAccount(user.id);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// تحديث الملف الشخصي
  Future<void> updateProfile({required String name, String? phone}) async {
    final user = _authRepository.getCurrentUser();
    if (user == null) {
      emit(const AuthError(message: 'لا يوجد مستخدم مسجل دخول'));
      return;
    }

    try {
      await _authRepository.updateProfile(
        userId: user.id,
        name: name,
        phone: phone,
      );

      // Refresh user data
      final updatedUser = await _authRepository.getUser(user.id);
      if (updatedUser != null) {
        emit(
          AuthAuthenticated(
            userId: updatedUser['id'] as String,
            name: updatedUser['name'] as String? ?? name,
            email: updatedUser['email'] as String? ?? '',
            phone: updatedUser['phone'] as String?,
            authProvider: (state as AuthAuthenticated).authProvider,
          ),
        );
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// طلب تغيير البريد الإلكتروني
  Future<void> requestEmailChange(String newEmail) async {
    emit(const AuthLoading());
    try {
      await _authRepository.updateEmail(newEmail: newEmail);
      emit(AuthEmailUpdateOtpSent(email: newEmail));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// تأكيد تغيير البريد الإلكتروني (OTP)
  Future<void> confirmEmailChange({
    required String newEmail,
    required String otp,
  }) async {
    emit(const AuthLoading());
    try {
      await _authRepository.verifyEmailChange(newEmail: newEmail, otp: otp);

      // Refresh user data (session is preserved, but we want updated email in state)
      final user = _authRepository.getCurrentUser();
      if (user != null) {
        // Force refresh from repository to get latest profile
        await _checkAuthStatus();
        emit(const AuthEmailUpdateSuccess());
        // After emitting success, we might want to ensure we're back in Authenticated state
        // _checkAuthStatus calls emit(AuthAuthenticated) which is good.
        // Wait: AuthEmailUpdateSuccess is ephemeral.
        // If we emit Success then subsequently Authenticated, UI listening for Success might miss it if too fast?
        // Better: Emit Success, let UI handle navigation, THEN UI triggers refresh or we just have updated data.
        // Actually: _checkAuthStatus emits Authenticated. That replaces Success.
        // So we should:
        // 1. Emit Success (UI shows dialog/navigates)
        // 2. UI listeners calls refresh on close or we do it implicitly?
        // Let's just emit Success. The Authenticated state will be restored when re-entering settings or via checkAuthStatus.
        // BUT, if we stay on settings screen, we need valid state.
        // Let's rely on _checkAuthStatus() being called by UI if needed, OR:
        // Just emit AuthEmailUpdateSuccess, and assume UI will pop/reload.
        // The previous state was AuthAuthenticated.
        // Let's refetch user to be safe.
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
