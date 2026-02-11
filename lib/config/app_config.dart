/// External API keys – use --dart-define or env. Never commit secrets.
class AppConfig {
  AppConfig._();

  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
  static const String razorpayKeySecret = String.fromEnvironment(
    'RAZORPAY_KEY_SECRET',
    defaultValue: '',
  );
  static const String msg91AuthKey = String.fromEnvironment(
    'MSG91_AUTH_KEY',
    defaultValue: '',
  );
  static const String instagramAccessToken = String.fromEnvironment(
    'INSTAGRAM_ACCESS_TOKEN',
    defaultValue: '',
  );
  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: '',
  );
}
