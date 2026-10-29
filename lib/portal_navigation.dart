import 'package:flutter/material.dart';

import 'navigation_policy.dart';

/// Only locations reported by the embedded document's verified origin/source
/// reach this history. Returning to an earlier page trims forward entries.
class PortalHistory {
  PortalHistory(Uri initial) : _pages = [_canonical(initial)];
  static Uri _canonical(Uri uri) =>
      uri.path.length > 1 && uri.path.endsWith('/')
      ? uri.replace(path: uri.path.substring(0, uri.path.length - 1))
      : uri;
  final List<Uri> _pages;
  Uri get current => _pages.last;
  Uri? get previous => _pages.length > 1 ? _pages[_pages.length - 2] : null;
  void visit(Uri uri) {
    uri = _canonical(uri);
    if (uri == current) return;
    final index = _pages.lastIndexOf(uri);
    if (index >= 0) {
      _pages.removeRange(index + 1, _pages.length);
    } else {
      _pages.add(uri);
      if (_pages.length > 100) _pages.removeAt(0);
    }
  }
}

class PortalBackController {
  Future<bool> Function()? onBack;
  Future<bool> goBack() async => await onBack?.call() ?? false;
}

class PortalFrameController {
  bool overlayOpen = false;
  VoidCallback? closeOverlay;
}

bool isUserPortal(Uri uri) =>
    NavigationPolicy.isCrm(uri) &&
    !uri.path.startsWith('/appointly/appointments_public');

Future<bool> confirmLeavePortal(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this portal?'),
        content: const Text(
          'You’re about to leave this portal. This does not sign you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay here'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave portal'),
          ),
        ],
      ),
    ) ??
    false;
