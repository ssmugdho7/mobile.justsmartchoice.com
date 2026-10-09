import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'document_download.dart';
import 'navigation_policy.dart';
import 'quick_links.dart';
import 'site_unavailable.dart';

class CrmBrowser extends StatefulWidget {
  const CrmBrowser({
    super.key,
    this.windowId,
    this.onPageReady,
    this.initialUri,
    this.navigationDrawer,
    this.onAbout,
    this.onHome,
    this.onBrowserCreated,
    this.showAppBar = true,
    this.handleBack = true,
  });
  final int? windowId;
  final bool showAppBar;
  final bool handleBack;
  final Widget? navigationDrawer;
  final VoidCallback? onAbout;
  final VoidCallback? onHome;
  final void Function(InAppWebViewController)? onBrowserCreated;
  final Uri? initialUri;
  final Future<void> Function(InAppWebViewController)? onPageReady;
  @override
  State<CrmBrowser> createState() => _CrmBrowserState();
}

class _CrmBrowserState extends State<CrmBrowser> {
  String? _pdfScript;
  final _bridgeNonce = List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  @override
  void initState() {
    super.initState();
    // Do not log session URLs or PDF bridge payloads, including debug builds.
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    Future.wait([
      rootBundle.loadString('assets/pdf_download_bridge.js'),
      rootBundle.loadString('assets/public_site_shell.js'),
    ]).then((sources) {
      if (mounted) {
        final pdfSource = sources[0]
            .replaceAll('"__SC_NONCE__"', jsonEncode(_bridgeNonce))
            .replaceAll(
              '"__SC_ORIGIN__"',
              jsonEncode(NavigationPolicy.home.origin),
            );
        setState(() => _pdfScript = '$pdfSource\n${sources[1]}');
      }
    });
  }

  Future<bool> _exportPdf(List<dynamic> args) async {
    if (args.length < 2 || args[0] != _bridgeNonce) return false;
    final page = await _web?.getUrl();
    if (!mounted || page == null || !NavigationPolicy.isCrm(page)) return false;
    if (args[1] == 'error') {
      _message(
        'Unable to download this PDF. Check your CRM login and try again.',
      );
      return true;
    }
    if (args.length != 4 ||
        args[1] != 'save' ||
        args[2] is! String ||
        args[3] is! String ||
        (args[3] as String).length > 14 * 1024 * 1024 ||
        _downloading) {
      return false;
    }
    setState(() => _downloading = true);
    try {
      final document = await _downloads.savePdfBytes(
        base64Decode(args[3] as String),
        args[2] as String,
      );
      _saved(document);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _saved(SavedDocument document) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${document.name} saved to Downloads'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () async {
            try {
              await _downloads.open(document);
            } catch (_) {
              _message(
                'Saved to Downloads. Install a compatible viewer to open this file.',
              );
            }
          },
        ),
      ),
    );
  }

  InAppWebViewController? _web;
  final _downloads = DocumentDownload();
  Uri _current = NavigationPolicy.home;
  double _progress = 0;
  bool _unavailable = false, _httpError = false, _downloading = false;
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _retry() async {
    setState(() {
      _unavailable = false;
      _progress = 0;
    });
    await _web?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_current.toString())),
    );
  }

  Future<void> _portal(String path) async {
    final url = NavigationPolicy.home.resolve(path);
    await _web?.loadUrl(urlRequest: URLRequest(url: WebUri(url.toString())));
  }

  Future<void> _openQuickLink(QuickLink link) async {
    if (link == QuickLink.callOffice) {
      try {
        if (await launchUrl(link.uri, mode: LaunchMode.externalApplication)) {
          return;
        }
      } catch (_) {}
      _message('Call our office at (727) 755-3786.');
      return;
    }
    await _portal(link.destination);
  }

  void _info() => showAboutDialog(
    context: context,
    applicationName: 'Smart Choice Mobile',
    applicationVersion: '0.5.0',
    children: const [
      Text(
        'CRM: crm.justsmartchoice.com\nApp downloads: mobile.justsmartchoice.com\nUses your existing CRM account and records.',
      ),
    ],
  );

  Future<void> _back() async {
    if (await _web?.canGoBack() ?? false) {
      await _web?.goBack();
      return;
    }
    if (!mounted) return;
    if (widget.windowId != null) {
      Navigator.of(context).pop();
      return;
    }
    if (widget.onHome != null) {
      widget.onHome!();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Smart Choice?'),
        content: const Text(
          'You can reopen the app to return to the mobile CRM.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close app'),
          ),
        ],
      ),
    );
    if (leave == true) await SystemNavigator.pop();
  }

  Future<NavigationActionPolicy> _navigate(NavigationAction action) async {
    final uri = action.request.url;
    if (uri == null) return NavigationActionPolicy.CANCEL;
    final decision = NavigationPolicy.decide(uri);
    if (decision == NavigationDecision.internal) {
      return NavigationActionPolicy.ALLOW;
    }
    if (decision == NavigationDecision.external &&
        action.isForMainFrame != false) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _message('No app can open this link.');
      }
    } else if (action.isForMainFrame != false) {
      _message('This link is outside the mobile CRM environment.');
    }
    return NavigationActionPolicy.CANCEL;
  }

  Future<PermissionResponse> _media(PermissionRequest request) async {
    final approved = <PermissionResourceType>[];
    if (NavigationPolicy.canUseMedia(request.origin)) {
      for (final resource in request.resources) {
        final permission = resource == PermissionResourceType.CAMERA
            ? Permission.camera
            : resource == PermissionResourceType.MICROPHONE
            ? Permission.microphone
            : null;
        if (permission != null && await permission.request().isGranted) {
          approved.add(resource);
        }
      }
    }
    return PermissionResponse(
      resources: approved,
      action: approved.isEmpty
          ? PermissionResponseAction.DENY
          : PermissionResponseAction.GRANT,
    );
  }

  Future<void> _download(DownloadStartRequest request) async {
    if (_downloading) {
      _message('A document is already downloading.');
      return;
    }
    if (!NavigationPolicy.isCrm(request.url)) {
      _message('Only mobile CRM documents can be saved.');
      return;
    }
    setState(() => _downloading = true);
    try {
      final cookies = await CookieManager.instance().getCookies(
        url: request.url,
      );
      final document = await _downloads.save(
        request.url,
        cookie: cookies.map((c) => '${c.name}=${c.value}').join('; '),
        userAgent: request.userAgent ?? 'SmartChoiceMobile',
        filename: request.suggestedFilename,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${document.name} saved to Downloads'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              try {
                await _downloads.open(document);
              } catch (_) {
                _message(
                  'Saved to Downloads. Install a compatible viewer to open this file.',
                );
              }
            },
          ),
        ),
      );
    } catch (_) {
      _message(
        'Unable to download. Check your connection and CRM login, then try again.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.handleBack || widget.windowId != null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.handleBack) _back();
    },
    child: Scaffold(
      drawer: widget.navigationDrawer,
      appBar: !widget.showAppBar
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                tooltip: widget.windowId != null ? 'Close window' : 'Back',
                icon: Icon(
                  widget.windowId != null ? Icons.close : Icons.arrow_back,
                ),
                onPressed: widget.windowId != null
                    ? () => Navigator.of(context).pop()
                    : _back,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart Choice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  if (MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                    const Text(
                      'Mobile CRM',
                      style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                    ),
                ],
              ),
              actions: [
                if (widget.navigationDrawer != null)
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Open navigation',
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                if (_downloading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'Reload page',
                  icon: const Icon(Icons.refresh),
                  onPressed: _retry,
                ),
                QuickLinksMenu(
                  onSelected: _openQuickLink,
                  onAbout: widget.onAbout ?? _info,
                ),
              ],
            ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_pdfScript == null)
              const Center(child: CircularProgressIndicator()),
            if (_pdfScript != null)
              InAppWebView(
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    source: _pdfScript!,
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    forMainFrameOnly: true,
                  ),
                ]),
                windowId: widget.windowId,
                initialUrlRequest: widget.windowId == null
                    ? URLRequest(
                        url: WebUri(
                          (widget.initialUri != null &&
                                      NavigationPolicy.isAppPage(
                                        widget.initialUri!,
                                      )
                                  ? widget.initialUri!
                                  : NavigationPolicy.home)
                              .toString(),
                        ),
                      )
                    : null,
                initialSettings: InAppWebViewSettings(
                  // Retain server-issued sessions in the platform cookie store.
                  incognito: false,
                  sharedCookiesEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  useShouldInterceptRequest: true,
                  useOnDownloadStart: true,
                  supportMultipleWindows: true,
                  javaScriptCanOpenWindowsAutomatically: false,
                  mediaPlaybackRequiresUserGesture: true,
                  allowsInlineMediaPlayback: true,
                  mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
                  allowFileAccess: false,
                  allowContentAccess: true,
                ),
                onWebViewCreated: (controller) {
                  _web = controller;
                  widget.onBrowserCreated?.call(controller);
                  controller.addJavaScriptHandler(
                    handlerName: 'scExportPdf',
                    callback: _exportPdf,
                  );
                },
                shouldOverrideUrlLoading: (controller, action) =>
                    _navigate(action),
                // Android doesn't call shouldOverrideUrlLoading for POST actions.
                // Block development CRM hosts at the request layer too, including
                // forms, frames and scripts that contain a stale absolute URL.
                shouldInterceptRequest: (controller, request) async {
                  if (NavigationPolicy.isOtherCrm(request.url)) {
                    return WebResourceResponse(
                      statusCode: 403,
                      reasonPhrase: 'Wrong CRM environment',
                      contentType: 'text/plain',
                      contentEncoding: 'utf-8',
                    );
                  }
                  return null;
                },
                onLoadStart: (controller, url) async {
                  if (url == null || url.toString() == 'about:blank') return;
                  if (NavigationPolicy.decide(url) !=
                      NavigationDecision.internal) {
                    await controller.stopLoading();
                    _message(
                      'This app opens the Smart Choice website, CRM and meeting rooms.',
                    );
                    if (widget.windowId == null) {
                      await controller.loadUrl(
                        urlRequest: URLRequest(
                          url: WebUri(
                            (widget.initialUri != null &&
                                        NavigationPolicy.isAppPage(
                                          widget.initialUri!,
                                        )
                                    ? widget.initialUri!
                                    : NavigationPolicy.home)
                                .toString(),
                          ),
                        ),
                      );
                    }
                    return;
                  }
                  if (mounted) {
                    setState(() {
                      _current = url;
                      _unavailable = false;
                      _httpError = false;
                    });
                  }
                },
                onLoadStop: (controller, url) async {
                  if (mounted) setState(() => _progress = 1);
                  await widget.onPageReady?.call(controller);
                },
                onProgressChanged: (controller, progress) {
                  if (mounted) setState(() => _progress = progress / 100);
                },
                onReceivedError: (controller, request, error) {
                  if (request.isForMainFrame == true && mounted) {
                    setState(() {
                      _unavailable = true;
                      _httpError = false;
                    });
                  }
                },
                onReceivedHttpError: (controller, request, response) {
                  if (request.isForMainFrame == true &&
                      (response.statusCode ?? 0) >= 400 &&
                      mounted) {
                    setState(() {
                      _unavailable = true;
                      _httpError = true;
                    });
                  }
                },
                // Default Android certificate validation remains enabled.
                onPermissionRequest: (controller, request) => _media(request),
                onDownloadStartRequest: (controller, request) =>
                    _download(request),
                onCreateWindow: (controller, action) async {
                  if (!mounted || action.hasGesture != true) return false;
                  final url = action.request.url;
                  if (url != null &&
                      url.toString() != 'about:blank' &&
                      NavigationPolicy.decide(url) !=
                          NavigationDecision.internal) {
                    await _navigate(action);
                    return false;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CrmBrowser(windowId: action.windowId),
                    ),
                  );
                  return true;
                },
                onCloseWindow: (controller) {
                  if (widget.windowId != null && mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            if (_progress < 1 && !_unavailable)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 3,
                ),
              ),
            if (_unavailable)
              Positioned.fill(
                child: SiteUnavailable(onRetry: _retry, httpError: _httpError),
              ),
          ],
        ),
      ),
    ),
  );
}
