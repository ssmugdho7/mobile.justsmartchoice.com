import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'portal_surface_native.dart'
    if (dart.library.js_interop) 'portal_surface_web.dart';

import 'package:flutter/foundation.dart';

import 'navigation_policy.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.onPageReady});
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _page = 0;
  Uri? _portal;
  InAppWebViewController? _controller;

  void _select(int page) => setState(() => _page = page);
  Future<void> _openPortal(String path) async {
    final uri = NavigationPolicy.home.resolve(path);
    if (_controller != null) {
      await _controller!.loadUrl(
        urlRequest: URLRequest(url: WebUri(uri.toString())),
      );
    }
    if (mounted) {
      setState(() {
        _portal = uri;
        _page = 2;
      });
    }
  }

  Widget _drawer() => Drawer(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.roofing, size: 44, color: Color(0xff107566)),
                SizedBox(height: 12),
                Text(
                  'Smart Choice Mobile',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text('Your CRM, wherever you work.'),
              ],
            ),
          ),
          _navItem(Icons.home_outlined, 'Home', _page == 0, () => _select(0)),
          _navItem(Icons.info_outline, 'About', _page == 1, () => _select(1)),
          const Divider(),
          _navItem(
            Icons.work_outline,
            'Staff portal',
            false,
            () => _openPortal('/admin'),
          ),
          _navItem(
            Icons.person_outline,
            'Customer portal',
            false,
            () => _openPortal('/clients'),
          ),
        ],
      ),
    ),
  );

  Widget _navItem(
    IconData icon,
    String title,
    bool selected,
    VoidCallback action,
  ) => Builder(
    builder: (context) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: selected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selectedTileColor: const Color(0xffdcefe9),
      onTap: () {
        Navigator.of(context).pop();
        action();
      },
    ),
  );

  Widget _home() => _content([
    const Icon(Icons.roofing, size: 72, color: Color(0xff107566)),
    const SizedBox(height: 24),
    Text(
      'Welcome to Smart Choice',
      style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 12),
    const Text(
      'Manage your work, projects and documents from your phone.',
      style: TextStyle(fontSize: 17, height: 1.6),
    ),
    const SizedBox(height: 28),
    FilledButton.icon(
      onPressed: () => _openPortal('/admin'),
      icon: const Icon(Icons.work_outline),
      label: const Text('Open staff portal'),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: () => _openPortal('/clients'),
      icon: const Icon(Icons.person_outline),
      label: const Text('Open customer portal'),
    ),
    const SizedBox(height: 24),
    const Text(
      'Use your existing CRM account. Your projects and records stay in the same Smart Choice CRM.',
      style: TextStyle(height: 1.6),
    ),
    const SizedBox(height: 16),
    TextButton(
      onPressed: () => _select(1),
      child: const Text('About Smart Choice Mobile'),
    ),
  ]);

  Widget _about() => _content([
    Text(
      'About Smart Choice Mobile',
      style: Theme.of(context).textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: 16),
    const Text(
      'A mobile companion for Smart Choice Contractors CRM.',
      style: TextStyle(fontSize: 18, height: 1.6),
    ),
    const SizedBox(height: 24),
    const Text(
      'Access your staff or customer portal, review projects, download documents and open video meetings using your existing account.',
      style: TextStyle(height: 1.7),
    ),
    const SizedBox(height: 20),
    const Text(
      'Your CRM permissions still apply. Actions in the app affect your live CRM records.',
      style: TextStyle(height: 1.7),
    ),
    const Divider(height: 48),
    const Text(
      kIsWeb
          ? 'Interface preview · Version 0.3.0'
          : 'Version 0.3.0 · Android testing build',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    const SizedBox(height: 12),
    const SelectableText(
      'CRM: crm.justsmartchoice.com\nApp downloads: mobile.justsmartchoice.com',
      style: TextStyle(height: 1.8),
    ),
    const SizedBox(height: 24),
    OutlinedButton.icon(
      onPressed: () => _select(0),
      icon: const Icon(Icons.home_outlined),
      label: const Text('Back to Home'),
    ),
  ]);

  Widget _content(List<Widget> children) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xffdbe5e1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _page != 1,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _page == 1) _select(0);
    },
    child: Scaffold(
      appBar: _page == 2
          ? null
          : AppBar(title: Text(_page == 0 ? 'Home' : 'About')),
      drawer: _page == 2 ? null : _drawer(),
      body: IndexedStack(
        index: _page,
        children: [
          _home(),
          _about(),
          _portal == null
              ? const SizedBox.shrink()
              : PortalSurface(
                  initialUri: _portal,
                  navigationDrawer: _drawer(),
                  onAbout: () => _select(1),
                  onHome: () => _select(0),
                  onBrowserCreated: (controller) => _controller = controller,
                  onPageReady: (controller) async {
                    _controller = controller;
                    await widget.onPageReady?.call(controller);
                  },
                ),
        ],
      ),
    ),
  );
}
