import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abstract service for opening external URLs/URIs (web, maps, etc.)
abstract class UrlLauncherService {
  /// Opens the given [uri]. Returns true if launched successfully, false otherwise.
  Future<bool> open(Uri uri);
}

/// Real implementation of [UrlLauncherService] using [url_launcher].
class RealUrlLauncherService implements UrlLauncherService {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}

/// Fake implementation of [UrlLauncherService] for testing.
class FakeUrlLauncherService implements UrlLauncherService {
  final List<Uri> openedUris = [];
  bool shouldSucceed = true;

  @override
  Future<bool> open(Uri uri) async {
    if (shouldSucceed) {
      openedUris.add(uri);
      return true;
    }
    return false;
  }

  void clear() {
    openedUris.clear();
  }
}

/// Provider for [UrlLauncherService]. Defaults to [RealUrlLauncherService].
final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return RealUrlLauncherService();
});
