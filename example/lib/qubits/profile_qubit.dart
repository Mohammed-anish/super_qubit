import 'package:super_qubit/super_qubit.dart';
import '../events/user_events.dart';
import '../states/user_states.dart';

class ProfileQubit extends Qubit<UserEventBase, ProfileState> {
  ProfileQubit() : super(const ProfileState()) {
    on<UpdateProfileEvent>((event, emit) {
      emit(ProfileState(displayName: event.displayName, email: event.email));
    });
  }
}
