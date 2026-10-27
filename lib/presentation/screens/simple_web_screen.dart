import 'dart:collection';
import 'package:flutter/foundation.dart';
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

  /// The earthlyjewels.co CDN URL for the product image. Used to pre-warm the
  /// VTryOn session cookie before VTryOn's React app calls the selection detail
  /// API — matching what vtryon-storefront.js does on a real product page visit.
  final String? vtryonCdnUrl;

  const SimpleWebScreen({
    super.key,
    required this.title,
    required this.url,
    this.vtryonProductHandle,
    this.vtryonCdnUrl,
  });

  static String prefKey(String handle) => 'vtryon_sel_$handle';

  @override
  State<SimpleWebScreen> createState() => _SimpleWebScreenState();
}

class _SimpleWebScreenState extends State<SimpleWebScreen> {
  InAppWebViewController? _webController;
  bool _loading = true;

  // Builds an AT_DOCUMENT_START script that:
  // 1. Pre-warms the VTryOn session by replicating the call vtryon-storefront.js
  //    makes on product pages (same-origin here → cookie sticks).
  // 2. Delays VTryOn's own /api/tryon/selection/<UUID> call until (1) completes.
  // 3. Adds ?shop=... to that call as an extra guard.
  // 4. Captures any selectionId from VTryOn API responses for caching.
  // ignore: avoid_unused_parameters
  static String _buildInterceptScript(String cdnUrl) {
    return """
(function() {
  var _shop = 'y7srws-f4.myshopify.com';

  // Read user_id from the URL query string (passed by our Flutter app).
  var _userId = '';
  try {
    _userId = new URLSearchParams(location.search).get('user_id') || '';
  } catch(e) {}

  function isVtryonApi(url) {
    return url.indexOf('vtryon.earthlyjewels.co') > -1;
  }
  function addAuthHeaders(init) {
    if (!_userId) return init || {};
    var h = Object.assign({}, (init && init.headers) ? init.headers : {});
    if (!h['x-vtryon-user-id']) h['x-vtryon-user-id'] = _userId;
    return Object.assign({}, init || {}, { headers: h, credentials: 'include' });
  }
  function extractSid(d) {
    if (!d) return null;
    return d.selectionId || d.selection_id ||
      (d.selection && (d.selection.id || d.selection.selectionId)) ||
      (d.data && (d.data.selectionId || d.data.id || d.data.selection_id)) ||
      null;
  }

  var _origFetch = window.fetch;
  window.fetch = function(input, init) {
    var url = (typeof input === 'string') ? input
            : (input && input.url) ? String(input.url) : String(input || '');

    if (isVtryonApi(url)) {
      var patchedInit = addAuthHeaders(init);
      // Add shop param if missing on API calls.
      if (url.indexOf('/api/') > -1 && url.indexOf('shop=') === -1) {
        url = url + (url.indexOf('?') > -1 ? '&' : '?') + 'shop=' + _shop;
      }
      var p = _origFetch.call(window, url, patchedInit);
      p.then(function(r) { return r.clone().json(); })
       .then(function(d) {
         var sid = extractSid(d);
         if (sid) {
           console.log('[VTryOn] capture selectionId: ' + sid);
           window.flutter_inappwebview.callHandler('VTryOnCapture', String(sid));
         }
       }).catch(function() {});
      return p;
    }

    return _origFetch.apply(window, arguments);
  };

  // XHR: inject auth header and add ?shop to vtryon API calls.
  try {
    var _XHR = window.XMLHttpRequest;
    window.XMLHttpRequest = function() {
      var xhr = new _XHR();
      var _open = xhr.open.bind(xhr);
      var _setRequestHeader = xhr.setRequestHeader.bind(xhr);
      var _xurl = '';
      var _isVtryon = false;
      xhr.open = function(method, u) {
        var s = String(u || '');
        _isVtryon = isVtryonApi(s);
        if (_isVtryon && s.indexOf('/api/') > -1 && s.indexOf('shop=') === -1) {
          s = s + (s.indexOf('?') > -1 ? '&' : '?') + 'shop=' + _shop;
        }
        _xurl = s;
        return _open.call(xhr, method, s);
      };
      var _send = xhr.send.bind(xhr);
      xhr.send = function(body) {
        if (_isVtryon && _userId) {
          try { _setRequestHeader('x-vtryon-user-id', _userId); } catch(_) {}
        }
        return _send.call(xhr, body);
      };
      xhr.addEventListener('load', function() {
        try {
          if (_isVtryon) {
            var sid = extractSid(JSON.parse(xhr.responseText));
            if (sid) {
              console.log('[VTryOn] XHR capture selectionId: ' + sid);
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
""";
  }

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
                // Prevent file:// URI access from WebView content.
                allowFileAccess: false,
                allowFileAccessFromFileURLs: false,
                allowUniversalAccessFromFileURLs: false,
              ),
              // Inject intercept before any page script runs.
              initialUserScripts: handle != null
                  ? UnmodifiableListView([
                      UserScript(
                        source: _buildInterceptScript(widget.vtryonCdnUrl ?? ''),
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
              onPermissionRequest: (_, request) async {
                // Grant camera only — deny microphone, geolocation, etc.
                final granted = request.resources
                    .where((r) => r == PermissionResourceType.CAMERA)
                    .toList();
                return PermissionResponse(
                  resources: granted,
                  action: granted.isNotEmpty
                      ? PermissionResponseAction.GRANT
                      : PermissionResponseAction.DENY,
                );
              },
              onLoadStart: (_, __) {
                if (mounted) setState(() => _loading = true);
              },
              onLoadStop: (_, __) {
                if (mounted) setState(() => _loading = false);
              },
              onReceivedError: (_, __, ___) {
                if (mounted) setState(() => _loading = false);
              },
              onReceivedHttpError: (_, request, response) {
                if (kDebugMode) debugPrint('[VTryOn] HTTP ${response.statusCode}: ${request.url}');
              },
              onConsoleMessage: (_, msg) {
                if (kDebugMode && msg.message.contains('[VTryOn]')) {
                  debugPrint('[VTryOn][JS] ${msg.message}');
                }
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
