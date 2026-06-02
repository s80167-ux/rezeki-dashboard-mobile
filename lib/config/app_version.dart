import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  const AppVersion._();

  static Future<String> releaseLabel() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isEmpty) {
      throw StateError('Package version must be non-empty.');
    }

    return 'Release $version';
  }
}
