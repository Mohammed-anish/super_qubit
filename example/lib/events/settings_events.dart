// Base event for settings-related events
abstract class SettingsEventBase {}

class ToggleThemeEvent extends SettingsEventBase {}

class SetThemeEvent extends SettingsEventBase {
  final bool isDark;

  SetThemeEvent(this.isDark);
}
