import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App settings: theme, haptics, sound, onboarding flag.
class SettingsService extends ChangeNotifier {
  static const _kTheme = 'theme_mode'; // system|light|dark
  static const _kVibrate = 'vibrate';
  static const _kBeep = 'beep';
  static const _kOnboarded = 'onboarded';

  String _themeMode = 'system';
  bool _vibrate = true;
  bool _beep = true;
  bool _onboarded = false;

  String get themeMode => _themeMode;
  bool get vibrate => _vibrate;
  bool get beep => _beep;
  bool get onboarded => _onboarded;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _themeMode = p.getString(_kTheme) ?? 'system';
    _vibrate = p.getBool(_kVibrate) ?? true;
    _beep = p.getBool(_kBeep) ?? true;
    _onboarded = p.getBool(_kOnboarded) ?? false;
    notifyListeners();
  }

  Future<void> setThemeMode(String v) async {
    _themeMode = v;
    (await SharedPreferences.getInstance()).setString(_kTheme, v);
    notifyListeners();
  }

  Future<void> setVibrate(bool v) async {
    _vibrate = v;
    (await SharedPreferences.getInstance()).setBool(_kVibrate, v);
    notifyListeners();
  }

  Future<void> setBeep(bool v) async {
    _beep = v;
    (await SharedPreferences.getInstance()).setBool(_kBeep, v);
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    _onboarded = true;
    (await SharedPreferences.getInstance()).setBool(_kOnboarded, true);
    notifyListeners();
  }
}
