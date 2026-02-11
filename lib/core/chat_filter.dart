import 'constants.dart';

/// Chat restrictions: block numbers, emails, links. Whitelist basic punctuation. Strike system.
class ChatFilter {
  static final _linkPattern = RegExp(
    r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );
  static final _emailPattern = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );
  static final _phonePattern = RegExp(
    r'\+?[\d\s-]{10,}|(\d{3,}[\s-]?\d{3,}[\s-]?\d{4,})',
  );
  /// Allow letters, digits, basic punctuation. Block if contains link/email/phone.
  static final _allowedContent = RegExp(r"^[\p{L}\p{N}\s.,!?;:'\"()-]+$", unicode: true);

  /// Returns (isValid, violationType). violationType: 'link' | 'email' | 'number' | null.
  static ChatFilterResult validate(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return ChatFilterResult(valid: false, violation: 'empty');
    if (_linkPattern.hasMatch(trimmed)) return ChatFilterResult(valid: false, violation: 'link');
    if (_emailPattern.hasMatch(trimmed)) return ChatFilterResult(valid: false, violation: 'email');
    if (_phonePattern.hasMatch(trimmed)) return ChatFilterResult(valid: false, violation: 'number');
    if (!_allowedContent.hasMatch(trimmed)) return ChatFilterResult(valid: false, violation: 'disallowed');
    return ChatFilterResult(valid: true, violation: null);
  }

  static String? violationMessage(String? violation) {
    switch (violation) {
      case 'link':
        return 'Links are not allowed.';
      case 'email':
        return 'Email addresses are not allowed.';
      case 'number':
        return 'Phone numbers are not allowed.';
      case 'disallowed':
        return 'Only letters, numbers and basic punctuation are allowed.';
      case 'empty':
        return 'Message cannot be empty.';
      default:
        return null;
    }
  }

  static int get maxStrikes => AppConstants.chatMaxStrikesBeforeAction;
}

class ChatFilterResult {
  const ChatFilterResult({required this.valid, required this.violation});
  final bool valid;
  final String? violation;
}
