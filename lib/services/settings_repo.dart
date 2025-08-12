import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepo {
  static const _keySound = 'sound';
  Future<bool> getSoundEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keySound) ?? true;
  }
  Future<void> setSoundEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keySound, v);
  }
}
