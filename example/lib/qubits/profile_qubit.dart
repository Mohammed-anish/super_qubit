import 'package:super_qubit/super_qubit.dart';
import 'auth_qubit.dart';
import '../events/user_events.dart';
import '../states/user_states.dart';

class ProfileQubit extends Qubit<UserEventBase, ProfileState> {
  ProfileQubit() : super(const ProfileState()) {
    on<UpdateProfileEvent>((event, emit) {
      emit(ProfileState(displayName: event.displayName, email: event.email));
    });

    // Sibling-to-Sibling Communication: Children can also listen to siblings!
    // This is useful for purely reactive dependencies between Qubits.
    // Now safe in the constructor due to lazy parent-linking.
    listenTo<AuthQubit>((authState) {
      if (!authState.isLoggedIn) {
        // Automatically clear profile when logged out
        add(UpdateProfileEvent(displayName: null, email: null));
      }
    });
  }
}
