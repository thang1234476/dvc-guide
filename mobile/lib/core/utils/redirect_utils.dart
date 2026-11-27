/// Returns [from] path if it starts with '/' and NOT with '//'.
/// Otherwise returns fallback path (default: '/').
String sanitizeRedirectUri(String? from, {String fallback = '/'}) {
  if (from == null || from.isEmpty) {
    return fallback;
  }
  // Bắt đầu bằng '/' và KHÔNG bắt đầu bằng '//'
  if (from.startsWith('/') && !from.startsWith('//')) {
    return from;
  }
  return fallback;
}
