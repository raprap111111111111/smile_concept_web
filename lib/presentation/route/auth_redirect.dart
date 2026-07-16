// lib/presentation/route/auth_redirect.dart

/// Post-auth destination handoff.
///
/// Auth pages are a detour, not a destination: a visitor clicks a CTA, gets
/// asked to log in, and expects to land where they were headed. The CTA states
/// that destination as a `next` query param on the auth URL, and the router
/// consumes it once auth succeeds. In the URL rather than in a provider so it
/// survives a refresh mid-login.
class AuthRedirect {
  AuthRedirect._();

  /// Query param carrying the post-auth destination.
  static const String param = 'next';

  /// Where the booking CTAs are headed.
  static const String bookingForm = '/appointment-patient-form';

  /// Auth URL that returns to [destination] once the user is authenticated.
  static String path(String authPath, String destination) =>
      '$authPath?$param=${Uri.encodeQueryComponent(destination)}';

  /// The destination from [queryParameters], or null if absent or unusable.
  ///
  /// Only same-origin absolute paths are honored. `next` is attacker-supplied
  /// (it rides in a link), so anything that could leave the app — a scheme, a
  /// host, a protocol-relative `//evil.com` — is dropped rather than followed.
  static String? resolve(Map<String, String> queryParameters) {
    final next = queryParameters[param];
    if (next == null || next.isEmpty) return null;
    if (!next.startsWith('/') || next.startsWith('//')) return null;
    if (Uri.tryParse(next)?.hasScheme ?? true) return null;
    return next;
  }
}
