import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../component/loader_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// A generic full-screen WebView used for in-app browsing
/// (Virtual Try-On, consultations, info pages, etc.).
///
/// When [vtryonProductHandle] is provided the WebView injects a fetch
/// interceptor that captures the selectionId returned by VTryOn's own API
/// and caches it in SharedPreferences under [_prefKey].  On the next tap
/// the caller can read the cache and pre-fill the URL so "Start Generating"
/// is enabled from the first frame.
class SimpleWebScreen extends StatefulWidget {
  final String title;
  final String url;

  /// If set, activates the VTryOn selectionId auto-capture for this product.
  final String? vtryonProductHandle;

  const SimpleWebScreen({
    super.key,
    required this.title,
    required this.url,
    this.vtryonProductHandle,
  });

  static String prefKey(String handle) => 'vtryon_sel_$handle';

  @override
  State<SimpleWebScreen> createState() => _SimpleWebScreenState();
}

class _SimpleWebScreenState extends State<SimpleWebScreen> {
  InAppWebViewController? _webController;
  bool _loading = true;

  // Intercepts window.fetch and forwards any selectionId from VTryOn's API
  // calls back to Flutter via a JS channel. Handles multiple response formats
  // and URL patterns so the selectionId is cached for the next product visit.
  static const _fetchInterceptJs = r'''
(function() {
  function extractSid(d) {
    if (!d) return null;
    return d.selectionId || d.selection_id ||
      (d.selection && (d.selection.id || d.selection.selectionId)) ||
      (d.data && (d.data.selectionId || d.data.id || d.data.selection_id)) ||
      null;
  }
  function isVtryonUrl(url) {
    return url.includes('vtryon') &&
      (url.includes('selection') || url.includes('tryon') || url.includes('product'));
  }
  try {
    var _f = window.fetch;
    window.fetch = function() {
      var args = arguments;
      var p = _f.apply(this, args);
      try {
        var url = String(args[0] && args[0].url ? args[0].url : args[0] || '');
        if (isVtryonUrl(url)) {
          p.then(function(r) { return r.clone().json(); })
           .then(function(d) {
             var sid = extractSid(d);
             if (sid) {
               console.log('[VTryOn] intercept captured selectionId: ' + sid + ' from ' + url);
               window.flutter_inappwebview.callHandler('VTryOnCapture', String(sid));
             }
           })
           .catch(function() {});
        }
      } catch(_) {}
      return p;
    };
  } catch(_) {}
  // Also intercept XMLHttpRequest in case VTryOn uses XHR instead of fetch.
  try {
    var _XHR = window.XMLHttpRequest;
    window.XMLHttpRequest = function() {
      var xhr = new _XHR();
      var _open = xhr.open.bind(xhr);
      var _url = '';
      xhr.open = function(method, url) {
        _url = String(url || '');
        return _open.apply(xhr, arguments);
      };
      xhr.addEventListener('load', function() {
        try {
          if (isVtryonUrl(_url)) {
            var d = JSON.parse(xhr.responseText);
            var sid = extractSid(d);
            if (sid) {
              console.log('[VTryOn] XHR intercept captured selectionId: ' + sid + ' from ' + _url);
              window.flutter_inappwebview.callHandler('VTryOnCapture', String(sid));
            }
          }
        } catch(_) {}
      });
      return xhr;
    };
    window.XMLHttpRequest.prototype = _XHR.prototype;
  } catch(_) {}
})();
''';

  Future<void> _handleBack() async {
    if (_webController != null && await _webController!.canGoBack()) {
      await _webController!.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = widget.vtryonProductHandle;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(widget.title, style: AppTextStyles.headlineSmall),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: _handleBack,
            color: AppColors.textPrimary,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
              ),
              // Inject intercept before any page script runs.
              initialUserScripts: handle != null
                  ? UnmodifiableListView([
                      UserScript(
                        source: _fetchInterceptJs,
                        injectionTime:
                            UserScriptInjectionTime.AT_DOCUMENT_START,
                      ),
                    ])
                  : null,
              onWebViewCreated: (c) {
                _webController = c;
                if (handle != null) {
                  c.addJavaScriptHandler(
                    handlerName: 'VTryOnCapture',
                    callback: (args) async {
                      final id = args.isNotEmpty ? args.first as String? : null;
                      if (id != null && id.isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                            SimpleWebScreen.prefKey(handle), id);
                        debugPrint('[VTryOn] cached selectionId for $handle: $id');
                      }
                      return null;
                    },
                  );
                }
              },
              onPermissionRequest: (_, request) async => PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              ),
              onLoadStart: (_, __) {
                if (mounted) setState(() => _loading = true);
              },
              onLoadStop: (_, __) {
                if (mounted) setState(() => _loading = false);
              },
              onReceivedError: (_, __, ___) {
                if (mounted) setState(() => _loading = false);
              },
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: LoaderWidget(size: 32)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
