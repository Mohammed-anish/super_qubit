import 'package:super_qubit/super_qubit.dart';
import '../events/settings_events.dart';
import '../states/settings_states.dart';

class ThemeQubit extends Qubit<SettingsEventBase, ThemeState> {
  ThemeQubit() : super(const ThemeState()) {
    on<ToggleThemeEvent>((event, emit) {
      emit(ThemeState(isDark: !state.isDark));
    });

    on<SetThemeEvent>((event, emit) {
      emit(ThemeState(isDark: event.isDark));
    });
  }
}
