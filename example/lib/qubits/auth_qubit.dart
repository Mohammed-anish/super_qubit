import 'package:super_qubit/super_qubit.dart';
import '../events/user_events.dart';
import '../states/user_states.dart';

class AuthQubit extends Qubit<UserEventBase, AuthState> {
  AuthQubit() : super(const AuthState()) {
    on<LoginEvent>((event, emit) async {
      emit(const AuthState(isLoggingIn: true));
      // Simulate login
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthState(
        isLoggedIn: true,
        username: event.username,
      ));
    });

    on<LogoutEvent>((event, emit) {
      emit(const AuthState());
    });
  }
}
