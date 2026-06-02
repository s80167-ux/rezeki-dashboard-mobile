import 'dart:convert';

import 'package:flutter/services.dart';

class AppVersion {
  const AppVersion._();

  static Future<String> releaseLabel() async {
    final packageJson = await rootBundle.loadString('package.json');
    final packageData = jsonDecode(packageJson) as Map<String, dynamic>;
    final version = packageData['version'];
    if (version is! String || version.trim().isEmpty) {
      throw StateError('package.json must include a non-empty version.');
    }

    return 'Release ${version.trim()}';
  }
}
