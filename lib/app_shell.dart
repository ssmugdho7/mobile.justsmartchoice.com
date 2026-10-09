import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'portal_surface_native.dart'
    if (dart.library.js_interop) 'portal_surface_web.dart';
import 'public_site_native.dart'
    if (dart.library.js_interop) 'public_site_web.dart';
import 'navigation_policy.dart';
import 'quick_links.dart';
import 'landing_page.dart';
import 'launch_intro.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.onPageReady,
    this.publicPageBuilder,
    this.afterIntro,
  });
  final Widget Function(Uri)? publicPageBuilder;
  final Future<void> Function()? afterIntro;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _page = 3;
  bool _introFinished = false;
  bool _shopOpened = false;
  bool _dark = false;
  bool _aboutOpened = false;
  Uri? _portal;
  InAppWebViewController? _controller;
  InAppWebViewController? _homeController;
  InAppWebViewController? _aboutController;
  Future<void> _back() async {
    final controller = _page == 1
        ? _aboutController
        : (_page == 0 ? _homeController : null);
    if (await controller?.canGoBack() ?? false) {
      await controller!.goBack();
      return;
    }
    if (!mounted) return;
    if (_page == 1 || _page == 0) {
      _select(3);
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
    if (page == 0) _shopOpened = true;
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

  Future<void> _openQuickLink(QuickLink link) async {
    if (link == QuickLink.callOffice) {
      try {
        if (await launchUrl(link.uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call our office at (727) 755-3786.')),
        );
      }
      return;
    }
    await _openPortal(link.destination);
  }

  Future<void> _settings() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'App settings',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: _dark,
                onChanged: (value) {
                  _setDark(value);
                  updateSheet(() {});
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _select(1);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawer() => Drawer(
    backgroundColor: _dark ? const Color(0xff202020) : Colors.white,
    shape: const RoundedRectangleBorder(),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50, bottom: 26),
            child: Row(
              children: [
                Image.asset(
                  'assets/brand/smart-choice-logo.png',
                  width: 55,
                  height: 55,
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
          _navItem(Icons.home, 'Home', () => _select(3)),
          _navItem(Icons.shopping_bag_outlined, 'Shop', () => _select(0)),
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
      minTileHeight: 40,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontSize: 16)),
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
        appBar: _page == 2 || _page == 3
            ? null
            : AppBar(
                leadingWidth: 48,
                titleSpacing: 0,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(
                  _page == 0 ? 'Shop' : 'About',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                leading: _page == 1
                    ? IconButton(
                        tooltip: 'Back to Home',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _select(3),
                      )
                    : null,
                actions: [QuickLinksMenu(onSelected: _openQuickLink)],
              ),
        drawer: _page == 0 ? _drawer() : null,
        body: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 420),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: !_introFinished
              ? LaunchIntro(
                  key: const ValueKey('launch-intro'),
                  afterIntro: widget.afterIntro,
                  onFinished: () => setState(() => _introFinished = true),
                )
              : IndexedStack(
                  key: const ValueKey('app-pages'),
                  index: _page,
                  children: [
                    !_shopOpened
                        ? const SizedBox.shrink()
                        : widget.publicPageBuilder?.call(
                                NavigationPolicy.websiteHome,
                              ) ??
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
                            onHome: () => _select(3),
                            onBrowserCreated: (controller) =>
                                _controller = controller,
                            onPageReady: (controller) async {
                              _controller = controller;
                              await widget.onPageReady?.call(controller);
                            },
                          ),
                    LandingPage(
                      onEmployee: () => _openQuickLink(QuickLink.staff),
                      onClient: () => _openQuickLink(QuickLink.customer),
                      onAppointment: () =>
                          _openQuickLink(QuickLink.appointment),
                      onContact: () => _openPortal(
                        NavigationPolicy.websiteHome
                            .resolve('/contacts.php')
                            .toString(),
                      ),
                      onToolbox: () => _openQuickLink(QuickLink.toolbox),
                      onShop: () => _select(0),
                      onSettings: _settings,
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
