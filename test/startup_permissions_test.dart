import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_choice_mobile/startup_permissions.dart';

void main() {
  test(
    'first launch asks in order and later launches preserve the decision',
    () async {
      var completed = false;
      final requests = <Permission>[];
      final setup = StartupPermissions(
        hasCompleted: () async => completed,
        markCompleted: () async => completed = true,
        request: (permission) async => requests.add(permission),
      );
      await setup.run();
      expect(requests, [
        Permission.microphone,
        Permission.notification,
        Permission.camera,
      ]);
      await setup.run();
      expect(requests.length, 3);
    },
  );
}
