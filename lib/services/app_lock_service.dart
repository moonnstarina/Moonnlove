import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static const _enabledKey = 'app_lock_enabled';
  static const _pinKey = 'app_lock_pin';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> isEnabled() async =>
      (await _prefs).getBool(_enabledKey) ?? false;

  Future<bool> isPinSet() async =>
      (await _prefs).getString(_pinKey)?.isNotEmpty == true;

  Future<String?> getPin() async => (await _prefs).getString(_pinKey);

  Future<void> enable(String pin) async {
    final prefs = await _prefs;
    await prefs.setBool(_enabledKey, true);
    await prefs.setString(_pinKey, pin);
  }

  Future<void> changePin(String pin) async {
    final prefs = await _prefs;
    await prefs.setString(_pinKey, pin);
  }

  Future<void> disable() async {
    final prefs = await _prefs;
    await prefs.setBool(_enabledKey, false);
    await prefs.remove(_pinKey);
  }

  Future<bool> verify(String pin) async =>
      (await getPin()) == pin;
}
