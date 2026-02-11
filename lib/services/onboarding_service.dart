import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _keyOnboardingSeen = 'smn_onboarding_seen';
  static bool _cachedSeen = false;
  static bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedSeen = prefs.getBool(_keyOnboardingSeen) ?? false;
    _loaded = true;
  }

  bool hasSeenOnboarding() => _cachedSeen;

  Future<void> setOnboardingSeen() async {
    _cachedSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingSeen, true);
  }
}
