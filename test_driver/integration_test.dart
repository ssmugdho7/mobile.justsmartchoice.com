import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final directory = Directory('dist/screenshots');
    await directory.create(recursive: true);
    if (data?['screenshotPng'] is String) {
      await File('${directory.path}/mobile-app.png')
          .writeAsBytes(base64Decode(data!['screenshotPng'] as String));
    }
  },
);
