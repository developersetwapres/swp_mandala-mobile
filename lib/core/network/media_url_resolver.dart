import '../config/app_config.dart';

abstract final class MediaUrlResolver {
  static String resolve(String rawUrl) {
    final raw = Uri.tryParse(rawUrl.trim());
    if (raw == null || !raw.hasScheme || AppConfig.mediaBaseUrl.isEmpty) {
      return rawUrl;
    }
    final configuredBase = Uri.tryParse(AppConfig.mediaBaseUrl);
    if (configuredBase == null || !configuredBase.hasScheme) return rawUrl;
    return configuredBase
        .replace(path: raw.path, query: raw.query, fragment: raw.fragment)
        .toString();
  }
}
