// Base event for user-related events
abstract class UserEventBase {}

class LoginEvent extends UserEventBase {
  final String username;
  final String password;

  LoginEvent({required this.username, required this.password});
}

class LogoutEvent extends UserEventBase {}

class UpdateProfileEvent extends UserEventBase {
  final String displayName;
  final String email;

  UpdateProfileEvent({required this.displayName, required this.email});
}
