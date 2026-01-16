import 'package:super_qubit/super_qubit.dart';
import 'auth_qubit.dart';
import 'profile_qubit.dart';
import '../events/user_events.dart';

class UserSuperQubit extends SuperQubit {
  UserSuperQubit() {
    // When user logs in, load their profile
    listenTo<AuthQubit>((state) {
      if (state.isLoggedIn && state.username != null) {
        dispatch<ProfileQubit, UpdateProfileEvent>(
          UpdateProfileEvent(
            displayName: state.username!,
            email: '${state.username}@example.com',
          ),
        );
      }
    });

    // Parent-level event handler for logging
    on<AuthQubit, LoginEvent>((event, emit) {
      // Log analytics
      print('User login attempt: ${event.username}');
    });
  }

  // Convenience getters
  AuthQubit get auth => getQubit<AuthQubit>();
  ProfileQubit get profile => getQubit<ProfileQubit>();
}
