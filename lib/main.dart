import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'services/onboarding_service.dart';
import 'services/marketplace/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final url = SupabaseConfig.supabaseUrl;
  final anonKey = SupabaseConfig.supabaseAnonKey;
  if (url.isEmpty || anonKey.isEmpty) {
    debugPrint(
      'SMN: Supabase not configured. Run with:\n'
      '  flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY',
    );
  }
  await Supabase.initialize(
    url: url.isEmpty ? 'https://placeholder.supabase.co' : url,
    anonKey: anonKey.isEmpty ? 'placeholder' : anonKey,
  );

  await OnboardingService().ensureLoaded();
  if (Supabase.instance.client.auth.currentUser != null) {
    await MarketplaceAuthService().ensureUser();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const SMNApp());
}
