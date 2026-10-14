import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_choice_mobile/media_permissions.dart';

void main() {
  PermissionRequest request(
    List<PermissionResourceType> resources, {
    String host = 'meet.jit.si',
  }) => PermissionRequest(
    origin: WebUri('https://$host/room'),
    resources: resources,
  );

  test(
    'iOS combined capture requests both OS permissions before granting',
    () async {
      final asked = <Permission>[];
      final response = await MediaPermissions.authorize(
        request([PermissionResourceType.CAMERA_AND_MICROPHONE]),
        ask: (permission) async {
          asked.add(permission);
          return true;
        },
      );
      expect(asked, [Permission.camera, Permission.microphone]);
      expect(response.action, PermissionResponseAction.GRANT);
      expect(response.resources, [
        PermissionResourceType.CAMERA_AND_MICROPHONE,
      ]);
    },
  );
  test(
    'One denied permission never grants a combined or separate capture request',
    () async {
      for (final resources in [
        [PermissionResourceType.CAMERA_AND_MICROPHONE],
        [PermissionResourceType.CAMERA, PermissionResourceType.MICROPHONE],
      ]) {
        for (final denied in [Permission.camera, Permission.microphone]) {
          final response = await MediaPermissions.authorize(
            request(resources),
            ask: (permission) async => permission != denied,
          );
          expect(response.action, PermissionResponseAction.DENY);
          expect(response.resources, isEmpty);
        }
      }
    },
  );
  test(
    'Android camera and microphone requests still grant approved resources',
    () async {
      final response = await MediaPermissions.authorize(
        request([
          PermissionResourceType.CAMERA,
          PermissionResourceType.MICROPHONE,
        ], host: 'crm.justsmartchoice.com'),
        ask: (_) async => true,
      );
      expect(response.action, PermissionResponseAction.GRANT);
      expect(response.resources, [
        PermissionResourceType.CAMERA,
        PermissionResourceType.MICROPHONE,
      ]);
    },
  );
  test(
    'Untrusted origins and unsupported resources never ask for OS access',
    () async {
      var asked = 0;
      for (final value in [
        request([
          PermissionResourceType.CAMERA,
        ], host: 'meet.jit.si.example.test'),
        request([
          PermissionResourceType.MICROPHONE,
        ], host: 'justsmartchoice.com'),
        request([]),
        request([PermissionResourceType.PROTECTED_MEDIA_ID]),
      ]) {
        final response = await MediaPermissions.authorize(
          value,
          ask: (_) async {
            asked++;
            return true;
          },
        );
        expect(response.action, PermissionResponseAction.DENY);
      }
      expect(asked, 0);
    },
  );
  test(
    'An OS permission failure denies access without an unhandled error',
    () async {
      final response = await MediaPermissions.authorize(
        request([PermissionResourceType.CAMERA]),
        ask: (_) async => throw StateError('OS unavailable'),
      );
      expect(response.action, PermissionResponseAction.DENY);
    },
  );
}
