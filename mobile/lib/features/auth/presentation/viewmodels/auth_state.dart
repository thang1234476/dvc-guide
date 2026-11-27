import 'package:equatable/equatable.dart';
import '../../data/models/auth_user.dart';

enum AuthStatus {
  initial,
  guest,
  authenticated,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isGuest => status == AuthStatus.guest;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? Function()? user,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, errorMessage];
}
