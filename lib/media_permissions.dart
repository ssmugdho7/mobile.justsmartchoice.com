import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';

import 'navigation_policy.dart';

/// iOS grants or denies the entire WebKit capture request. Never grant a
/// combined camera/microphone request after only one OS permission succeeds.
class MediaPermissions {
  static Future<PermissionResponse> authorize(
    PermissionRequest request, {
    required Future<bool> Function(Permission) ask,
  }) async {
    PermissionResponse denied() => PermissionResponse(
      resources: const [],
      action: PermissionResponseAction.DENY,
    );
    if (!NavigationPolicy.canUseMedia(request.origin) ||
        request.resources.isEmpty) {
      return denied();
    }
    final permissions = <Permission>{};
    for (final resource in request.resources) {
      if (resource == PermissionResourceType.CAMERA) {
        permissions.add(Permission.camera);
      } else if (resource == PermissionResourceType.MICROPHONE) {
        permissions.add(Permission.microphone);
      } else if (resource == PermissionResourceType.CAMERA_AND_MICROPHONE) {
        permissions.addAll([Permission.camera, Permission.microphone]);
      } else {
        return denied();
      }
    }
    try {
      for (final permission in permissions) {
        if (!await ask(permission)) return denied();
      }
    } catch (_) {
      return denied();
    }
    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.GRANT,
    );
  }
}
