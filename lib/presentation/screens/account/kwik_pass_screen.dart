import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../../../component/loader_widget.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/customer_provider.dart';

// KwikPass login via the live Earthly Jewels website.
//
// HOW IT WORKS:
//   GoKwik KwikPass is a JS widget on earthlyjewels.co/account/login.
//   After the user completes phone OTP, Shopify redirects to /account.
//   We detect that redirect, inject a fetch('/account.json') call, and
//   receive the customer identity (email, name, phone) via the JS channel.
//   CustomerProvider.loginWithIdentity() stores this as an identity-only
//   session — no Storefront API token, orders/addresses open via website.
//
// WHY NO STOREFRONT TOKEN:
//   GoKwik's web flow creates a server-side Shopify session (httpOnly
//   cookies). The Storefront API customerAccessToken is a separate concept
//   and is not stored anywhere accessible to JavaScript. To get a full
//   token the app would need GoKwik's native mobile API credentials.

class KwikPassScreen extends StatefulWidget {
  const KwikPassScreen({super.key});

  @override
  State<KwikPassScreen> createState() => _KwikPassScreenState();
}

class _KwikPassScreenState extends State<KwikPassScreen> {
  InAppWebViewController? _controller;
  bool _pageLoading = true;
  bool _authenticating = false;
  bool _loginHandled = false;
  bool _cookiesCleared = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    // Wipe any residual Shopify session so the KwikPass OTP form always shows.
    // incognito:true alone is unreliable on some Android versions.
    // The Future is awaited via .then() so the WebView only mounts after
    // deletion completes — avoids the race where the old session is still
    // active when the first request fires.
    // deleteAllCookies() clears every domain (Shopify + GoKwik's own cookies).
    // Clearing only earthlyjewels.co leaves GoKwik's session intact, which
    // causes it to silently re-authenticate the user and skip the OTP form.
    CookieManager.instance().deleteAllCookies().then((_) {
      if (mounted) setState(() => _cookiesCleared = true);
    });
  }

  // Tries five strategies in order; last resort sends a diagnostic dump.
  // 1. window.Shopify.customer  — theme global, no network needed
  // 2. GoKwik / KwikPass global — post-OTP JS state
  // 3. localStorage scan        — GoKwik caches identity here
  // 4. /account.json fetch      — works on stores that honour Accept:json
  // 5. DOM email extraction     — customer email is always rendered on /account
  static const String _fetchIdentityJs = r'''
(function() {
  setTimeout(function() {
    function send(d) { window.flutter_inappwebview.callHandler('KwikPassChannel', d); }

    // 1. window.Shopify.customer
    try {
      var sc = window.Shopify && window.Shopify.customer;
      if (sc && (sc.email || sc.id)) {
        send({ email:sc.email||'', firstName:sc.first_name||'',
               lastName:sc.last_name||'', phone:sc.phone||'', id:String(sc.id||'') });
        return;
      }
    } catch(_) {}

    // 2. GoKwik / KwikPass global objects
    try {
      var gk = window.GoKwik || window.gokwik || window.KwikPass
               || window.kwikpass || window._gokwik || window.GK;
      if (gk) {
        var cu = gk.customer || gk.customerData || gk.userData || gk.user;
        if (cu && (cu.email || cu.phone)) {
          send({ email:cu.email||'', firstName:cu.first_name||cu.firstName||'',
                 lastName:cu.last_name||cu.lastName||'', phone:cu.phone||'',
                 id:String(cu.id||cu.customer_id||'') });
          return;
        }
      }
    } catch(_) {}

    // 3. localStorage — GoKwik / Shopify key patterns
    var lsKeys = ['kwikpass_customer','gk_customer_data','gokwik_customer',
                  'kwikpass_identity','kp_user_info','shopify_customer',
                  'customer_identity','kwik_customer','kp_customer'];
    try {
      for (var i = 0; i < lsKeys.length; i++) {
        var raw = localStorage.getItem(lsKeys[i]);
        if (!raw) continue;
        try {
          var p = JSON.parse(raw);
          if (p && (p.email || p.phone)) {
            send({ email:p.email||'', firstName:p.first_name||p.firstName||'',
                   lastName:p.last_name||p.lastName||'', phone:p.phone||'',
                   id:String(p.id||p.customer_id||'') });
            return;
          }
        } catch(_) {}
      }
    } catch(_) {}

    // 4. /account.json with JSON content-negotiation headers
    fetch('/account.json', {
      headers: { 'Accept':'application/json', 'X-Requested-With':'XMLHttpRequest' }
    })
    .then(function(r) {
      var ct = r.headers.get('content-type') || '';
      if (!ct.includes('json')) throw new Error('html:' + r.status);
      return r.json();
    })
    .then(function(data) {
      var c = data.customer || {};
      send({ email:c.email||'', firstName:c.first_name||'',
             lastName:c.last_name||'', phone:c.phone||'', id:String(c.id||'') });
    })
    .catch(function(fetchErr) {
      // 5. DOM extraction — email is always rendered on the /account page
      try {
        var skip = ['earthlyjewels','shopify','gokwik','kwikpass','support','noreply'];
        // a) mailto links — iterate all, skip store/platform addresses
        var mailtos = document.querySelectorAll('a[href^="mailto:"]');
        for (var k = 0; k < mailtos.length; k++) {
          var raw = mailtos[k].href.replace('mailto:','').split('?')[0].trim();
          if (!raw.includes('@')) continue;
          var ml = raw.toLowerCase(), bad = false;
          for (var s = 0; s < skip.length; s++) { if (ml.includes(skip[s])) { bad=true; break; } }
          if (!bad) { send({ email:raw, firstName:'', lastName:'', phone:'', id:'' }); return; }
        }
        // b) regex scan of visible page text; skip store / platform addresses
        var text  = document.body.innerText || '';
        var found = text.match(/\b[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}\b/g) || [];
        for (var i = 0; i < found.length; i++) {
          var m = found[i].toLowerCase(), bad = false;
          for (var j = 0; j < skip.length; j++) { if (m.includes(skip[j])) { bad=true; break; } }
          if (!bad) { send({ email:found[i], firstName:'', lastName:'', phone:'', id:'' }); return; }
        }
      } catch(_) {}

      // All strategies failed — diagnostic dump to debug console
      var diag = { err:String(fetchErr),
                   hasSC:!!(window.Shopify&&window.Shopify.customer),
                   hasGK:!!(window.GoKwik||window.KwikPass||window.kwikpass),
                   url:location.href, ls:[] };
      try { for (var i=0; i<localStorage.length; i++) diag.ls.push(localStorage.key(i)); } catch(_) {}
      send({ fetchError: JSON.stringify(diag) });
    });
  }, 1200);
})();
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Sign In', style: AppTextStyles.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Stack(
        children: [
          // ── WebView ──────────────────────────────────────────────────────
          // Only mount after deleteCookies() resolves to avoid the race where
          // the old Shopify session cookie is still active on first load.
          if (_loadError == null && _cookiesCleared)
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(GoKwikConfig.loginUrl),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                // Fresh session every time — prevents a stale website cookie
                // from skipping the OTP flow and showing only a spinner.
                incognito: true,
                // Let GoKwik's scripts run as if on the real website.
                userAgent:
                    'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (controller) {
                _controller = controller;
                controller.addJavaScriptHandler(
                  handlerName: 'KwikPassChannel',
                  callback: (args) {
                    _handleJsPayload(args);
                    return null;
                  },
                );
              },
              onLoadStart: (controller, url) {
                if (mounted) setState(() => _pageLoading = true);
              },
              onReceivedError: (controller, request, error) {
                // Only surface errors for the initial login page — sub-resource
                // errors from GoKwik / Shopify CDN are expected and harmless.
                if (request.url.toString() == GoKwikConfig.loginUrl) {
                  if (mounted) {
                    setState(() {
                      _pageLoading = false;
                      _loadError =
                          'Could not load sign-in page.\n${error.description}';
                    });
                  }
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                if (mounted) setState(() => _pageLoading = false);
                final path = url?.path ?? '';
                if (_isPostLoginPath(path) && !_loginHandled) {
                  if (mounted) setState(() => _authenticating = true);
                  await controller.evaluateJavascript(source: _fetchIdentityJs);
                }
              },
            ),

          // ── Load error ─────────────────────────────────────────────────
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('Sign-in unavailable',
                        style: AppTextStyles.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _loadError = null);
                        _controller?.reload();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // ── Spinner overlay ─────────────────────────────────────────────
          if (_pageLoading || _authenticating)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white
                    .withValues(alpha: _authenticating ? 0.88 : 0.55),
                child: const Center(child: LoaderWidget(size: 32)),
              ),
            ),
        ],
      ),
    );
  }

  bool _isPostLoginPath(String path) {
    return GoKwikConfig.postLoginPaths.any((p) => path == p || path == '$p/');
  }

  // Receives the /account.json result from the injected JS.
  // _loginHandled guards against duplicate calls.
  void _handleJsPayload(List<dynamic> args) {
    if (args.isEmpty || _loginHandled) return;
    _loginHandled = true;

    dynamic payload = args.first;
    if (payload is String) {
      try {
        payload = jsonDecode(payload);
      } catch (_) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
    if (payload is! Map) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (payload['fetchError'] != null) {
      debugPrint('[KwikPass] account.json fetch failed: ${payload['fetchError']}');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final email     = payload['email']     as String? ?? '';
    final firstName = payload['firstName'] as String? ?? '';
    final lastName  = payload['lastName']  as String? ?? '';
    final phone     = payload['phone']     as String? ?? '';
    final id        = payload['id']        as String? ?? '';

    debugPrint('[KwikPass] Identity received — email: $email  phone: $phone');

    if (email.isEmpty && phone.isEmpty) {
      debugPrint('[KwikPass] No identity data in account.json response.');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    _handleIdentity(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      numericId: id,
    );
  }

  Future<void> _handleIdentity({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required String numericId,
  }) async {
    final provider = context.read<CustomerProvider>();
    await provider.loginWithIdentity(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      numericId: numericId,
    );

    if (!mounted) return;

    if (provider.isLoggedIn) {
      Navigator.of(context).pop();
    } else {
      final msg = provider.errorMessage ?? 'Sign-in failed. Please try again.';
      provider.clearError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _authenticating = false;
        _loginHandled = false; // allow retry
      });
    }
  }
}
