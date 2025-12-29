// Auth state
class AuthState {
  final bool isLoggedIn;
  final bool isLoggingIn;
  final String? username;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoggingIn = false,
    this.username,
  });
}

// Profile state
class ProfileState {
  final String? displayName;
  final String? email;

  const ProfileState({
    this.displayName,
    this.email,
  });
}
