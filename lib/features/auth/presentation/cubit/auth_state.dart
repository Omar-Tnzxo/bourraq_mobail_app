import 'package:equatable/equatable.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state (during login, register, etc.)
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User successfully authenticated
class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final String name;
  final String? phone;
  final String authProvider; // 'google' or 'email'

  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.name,
    this.phone,
    this.authProvider = 'email',
  });

  bool get isGoogleAuth => authProvider == 'google';

  @override
  List<Object?> get props => [userId, email, name, phone, authProvider];
}

/// User not authenticated (logged out or session expired)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User browsing as guest (can view but cannot perform authenticated actions)
class AuthGuest extends AuthState {
  const AuthGuest();
}

/// OTP sent successfully (waiting for verification)
class AuthOtpSent extends AuthState {
  final String email;

  const AuthOtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Password reset OTP sent
class AuthPasswordResetOtpSent extends AuthState {
  final String email;

  const AuthPasswordResetOtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Password reset OTP verified
class AuthPasswordResetOtpVerified extends AuthState {
  const AuthPasswordResetOtpVerified();
}

/// Password reset successful
class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

/// Email update OTP sent
class AuthEmailUpdateOtpSent extends AuthState {
  final String email;

  const AuthEmailUpdateOtpSent({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Email update successful
class AuthEmailUpdateSuccess extends AuthState {
  const AuthEmailUpdateSuccess();
}

/// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
