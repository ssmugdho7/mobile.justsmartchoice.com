import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'portal_surface_native.dart'
    if (dart.library.js_interop) 'portal_surface_web.dart';
import 'public_site_native.dart'
    if (dart.library.js_interop) 'public_site_web.dart';
import 'navigation_policy.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.onPageReady, this.publicPageBuilder});
  final Widget Function(Uri)? publicPageBuilder;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _page = 0;
  bool _dark = false;
  bool _aboutOpened = false;
  Uri? _portal;
  InAppWebViewController? _controller;
  InAppWebViewController? _homeController;
  InAppWebViewController? _aboutController;
  Future<void> _back() async {
    final controller = _page == 1 ? _aboutController : _homeController;
    if (await controller?.canGoBack() ?? false) {
      await controller!.goBack();
      return;
    }
    if (!mounted) return;
    if (_page == 1) {
      _select(0);
      return;
    }
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Smart Choice?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close app'),
          ),
        ],
      ),
    );
    if (close == true) await SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _restoreTheme();
  }

  Future<void> _restoreTheme() async {
    try {
      final dark = await SharedPreferencesAsync().getBool('darkMode') ?? false;
      if (mounted) setState(() => _dark = dark);
    } catch (_) {
      /* A preference failure must not block navigation. */
    }
  }

  Future<void> _setDark(bool value) async {
    setState(() => _dark = value);
    try {
      await SharedPreferencesAsync().setBool('darkMode', value);
    } catch (_) {}
  }

  void _select(int page) => setState(() {
    _page = page;
    if (page == 1) _aboutOpened = true;
  });
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
    shape: const RoundedRectangleBorder(),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Row(
              children: [
                Image.asset(
                  'assets/brand/smart-choice-logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Smart Choice USA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          _navItem(Icons.home, 'Home', () => _select(0)),
          _navItem(Icons.info_outline, 'About', () => _select(1)),
          const Divider(thickness: 3, height: 24),
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.brightness_4),
            value: _dark,
            onChanged: _setDark,
          ),
        ],
      ),
    ),
  );
  Widget _navItem(IconData icon, String title, VoidCallback action) => Builder(
    builder: (context) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.of(context).pop();
        action();
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: _dark ? ThemeData.dark(useMaterial3: true) : Theme.of(context),
    child: PopScope(
      canPop: _page == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _page != 2) _back();
      },
      child: Scaffold(
        appBar: _page == 2
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(
                  _page == 0 ? 'Smart Choice USA' : 'About',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                leading: _page == 1
                    ? IconButton(
                        tooltip: 'Back to Home',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _select(0),
                      )
                    : null,
                actions: [
                  PopupMenuButton<String>(
                    tooltip: 'Choose CRM portal',
                    onSelected: _openPortal,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: '/admin',
                        child: Text('Staff portal'),
                      ),
                      PopupMenuItem(
                        value: '/clients',
                        child: Text('Customer portal'),
                      ),
                    ],
                  ),
                ],
              ),
        drawer: _page == 0 ? _drawer() : null,
        body: IndexedStack(
          index: _page,
          children: [
            widget.publicPageBuilder?.call(NavigationPolicy.websiteHome) ??
                PublicSiteView(
                  uri: NavigationPolicy.websiteHome,
                  onPageReady: widget.onPageReady,
                  onBrowserCreated: (controller) =>
                      _homeController = controller,
                ),
            _aboutOpened
                ? widget.publicPageBuilder?.call(
                        NavigationPolicy.websiteAbout,
                      ) ??
                      PublicSiteView(
                        uri: NavigationPolicy.websiteAbout,
                        onPageReady: widget.onPageReady,
                        onBrowserCreated: (controller) =>
                            _aboutController = controller,
                      )
                : const SizedBox.shrink(),
            _portal == null
                ? const SizedBox.shrink()
                : PortalSurface(
                    initialUri: _portal,
                    handleBack: _page == 2,
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
    ),
  );
}
