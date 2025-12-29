import 'package:super_qubit/super_qubit.dart';
import 'theme_qubit.dart';

class SettingsSuperQubit extends SuperQubit {
  @override
  void init() {
    // Listen to theme changes
    listenTo<ThemeQubit>((state) {
      print('Theme changed: ${state.isDark ? "Dark" : "Light"} mode');
    });
  }

  // Convenience getters
  ThemeQubit get theme => getQubit<ThemeQubit>();
}
