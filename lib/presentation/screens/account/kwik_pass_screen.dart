import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../../../component/loader_widget.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/gokwik_backend_service.dart';
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
    Future.wait([
      CookieManager.instance().deleteAllCookies(),
      WebStorageManager.instance().deleteAllData(),
    ]).then((_) {
      if (mounted) setState(() => _cookiesCleared = true);
    });
  }

  // Tries five strategies in order; last resort sends a diagnostic dump.
  // getAnalyticsId() supplements the numeric Shopify id in all strategies —
  // ShopifyAnalytics.meta.page.customerId is injected by Shopify on every
  // authenticated page and is always the numeric customer id, never a UUID.
  // 1. window.Shopify.customer  — theme global, no network needed
  // 2. GoKwik / KwikPass global — post-OTP JS state (id is GoKwik UUID → supplement)
  // 3. localStorage scan        — GoKwik caches identity here
  // 4. /account.json fetch      — works on stores that honour Accept:json
  // 5. DOM email extraction     — customer email is always rendered on /account
  static const String _fetchIdentityJs = r'''
(function() {
  setTimeout(function() {
    function send(d) { window.flutter_inappwebview.callHandler('KwikPassChannel', d); }

    // Returns the numeric Shopify customer ID from Shopify's analytics globals.
    // ShopifyAnalytics.meta.page.customerId is present on every authenticated
    // Shopify page — always the numeric id (e.g. 31298404581597), never a UUID.
    function getAnalyticsId() {
      try {
        var c = (window.ShopifyAnalytics && window.ShopifyAnalytics.meta
                  && window.ShopifyAnalytics.meta.page
                  && window.ShopifyAnalytics.meta.page.customerId)
             || (window.meta && window.meta.page && window.meta.page.customerId)
             || (window.__st && window.__st.v && window.__st.v.customerId);
        if (c && /^\d{8,}$/.test(String(c))) return String(c);
      } catch(_) {}
      return '';
    }

    // Phone captured by the early intercept — read once here, supplement every strategy below.
    var ssPhone = '';
    try { ssPhone = sessionStorage.getItem('_gk_phone') || ''; } catch(_) {}
    console.log('[KwikPass] ssPhone=' + ssPhone);

    // 1. window.Shopify.customer — only shortcut when id is present;
    //    if id is missing, fall through to /account.json to get it.
    try {
      var sc = window.Shopify && window.Shopify.customer;
      if (sc && sc.id) {
        send({ email:sc.email||'', firstName:sc.first_name||'',
               lastName:sc.last_name||'', phone:sc.phone||ssPhone||'', id:String(sc.id) });
        return;
      }
    } catch(_) {}

    // 2. GoKwik / KwikPass global objects — GoKwik's id is a UUID, not the
    //    Shopify numeric customer id; supplement from analytics globals.
    try {
      var gk = window.GoKwik || window.gokwik || window.KwikPass
               || window.kwikpass || window._gokwik || window.GK;
      if (gk) {
        var cu = gk.customer || gk.customerData || gk.userData || gk.user;
        var gkId = cu ? String(cu.id || cu.customer_id || '') : '';
        if (cu && gkId) {
          var useId2 = /^\d{8,}$/.test(gkId) ? gkId : getAnalyticsId();
          send({ email:cu.email||'', firstName:cu.first_name||cu.firstName||'',
                 lastName:cu.last_name||cu.lastName||'', phone:cu.phone||ssPhone||'',
                 id:useId2 });
          return;
        }
      }
    } catch(_) {}

    // 3. localStorage — supplement numeric id from analytics if missing
    var lsKeys = ['kwikpass_customer','gk_customer_data','gokwik_customer',
                  'kwikpass_identity','kp_user_info','shopify_customer',
                  'customer_identity','kwik_customer','kp_customer'];
    try {
      for (var i = 0; i < lsKeys.length; i++) {
        var raw = localStorage.getItem(lsKeys[i]);
        if (!raw) continue;
        try {
          var p = JSON.parse(raw);
          var lsId = p ? String(p.id || p.customer_id || '') : '';
          if (p && lsId) {
            var useId3 = /^\d{8,}$/.test(lsId) ? lsId : getAnalyticsId();
            send({ email:p.email||'', firstName:p.first_name||p.firstName||'',
                   lastName:p.last_name||p.lastName||'', phone:p.phone||ssPhone||'',
                   id:useId3 });
            return;
          }
        } catch(_) {}
      }
    } catch(_) {}

    // 4. /account.json with JSON content-negotiation headers
    fetch('/account.json', {
      credentials: 'include',
      headers: { 'Accept':'application/json', 'X-Requested-With':'XMLHttpRequest' }
    })
    .then(function(r) {
      var ct = r.headers.get('content-type') || '';
      console.log('[KwikPass:4] status='+r.status+' ct='+ct);
      if (!ct.includes('json')) throw new Error('html:' + r.status);
      return r.json();
    })
    .then(function(data) {
      var c = data.customer || {};
      var id = String(c.id || '') || getAnalyticsId();
      // Supplement phone from sessionStorage when Shopify account has none.
      var phone = c.phone || ssPhone || '';
      console.log('[KwikPass:4] id='+id+' email='+c.email+' phone='+phone);
      send({ email:c.email||'', firstName:c.first_name||'',
             lastName:c.last_name||'', phone:phone, id:id });
    })
    .catch(function(fetchErr) {
      console.log('[KwikPass:4] err: '+fetchErr);
      // 5. DOM extraction — email is always rendered on the /account page.
      // Supplement id from analytics globals so we always capture numeric id.
      var analyticsId = getAnalyticsId();
      try {
        var skip = ['earthlyjewels','shopify','gokwik','kwikpass','support','noreply'];
        // a) mailto links — iterate all, skip store/platform addresses
        var mailtos = document.querySelectorAll('a[href^="mailto:"]');
        for (var k = 0; k < mailtos.length; k++) {
          var raw = mailtos[k].href.replace('mailto:','').split('?')[0].trim();
          if (!raw.includes('@')) continue;
          var ml = raw.toLowerCase(), bad = false;
          for (var s = 0; s < skip.length; s++) { if (ml.includes(skip[s])) { bad=true; break; } }
          if (!bad) { send({ email:raw, firstName:'', lastName:'', phone:ssPhone, id:analyticsId }); return; }
        }
        // b) regex scan of visible page text; skip store / platform addresses
        var text  = document.body.innerText || '';
        var found = text.match(/\b[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}\b/g) || [];
        for (var i = 0; i < found.length; i++) {
          var m = found[i].toLowerCase(), bad = false;
          for (var j = 0; j < skip.length; j++) { if (m.includes(skip[j])) { bad=true; break; } }
          if (!bad) { send({ email:found[i], firstName:'', lastName:'', phone:ssPhone, id:analyticsId }); return; }
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

  // Injected at AT_DOCUMENT_START on the login page so it runs before GoKwik's
  // script. Intercepts GoKwik's postMessage and dispatchEvent to capture the
  // OTP-verified phone number. The phone is stored in sessionStorage under
  // '_gk_phone' and survives the /account/login → /account redirect.
  // firstName/lastName are NOT available from GoKwik — OTP only collects phone.
  static const String _earlyInterceptJs = r'''
(function() {
  // Intercept window.postMessage — GoKwik's widget iframe posts auth data here.
  window.addEventListener('message', function(evt) {
    try {
      var d = (typeof evt.data === 'string') ? JSON.parse(evt.data) : evt.data;
      if (!d) return;
      var ph = d.phone || d.mobile || d.phoneNumber
            || (d.data  && (d.data.phone  || d.data.mobile))
            || (d.user  && (d.user.phone  || d.user.mobile))
            || '';
      if (ph && /^\+?\d{7,15}$/.test(ph.replace(/[\s\-]/g,''))) {
        sessionStorage.setItem('_gk_phone', ph);
        console.log('[KwikPass:early] phone via postMessage: ' + ph);
      }
    } catch(_) {}
  }, false);

  // Intercept window.dispatchEvent — GoKwik dispatches custom events on OTP success.
  try {
    var _origDispatch = window.dispatchEvent.bind(window);
    window.dispatchEvent = function(evt) {
      try {
        if (evt && evt.type) {
          var t = evt.type.toLowerCase();
          if (t.indexOf('kp') !== -1 || t.indexOf('kwik') !== -1 || t.indexOf('gokwik') !== -1) {
            var d = evt.detail || {};
            var ph = d.phone || d.mobile || d.phoneNumber
                  || (d.user && (d.user.phone || d.user.mobile))
                  || '';
            if (ph && /^\+?\d{7,15}$/.test(ph.replace(/[\s\-]/g,''))) {
              sessionStorage.setItem('_gk_phone', ph);
              console.log('[KwikPass:early] phone via dispatchEvent(' + evt.type + '): ' + ph);
            }
          }
        }
      } catch(_) {}
      return _origDispatch.apply(this, arguments);
    };
  } catch(_) {}

  // Patch GoKwik's known success callback names set by the merchant theme.
  ['kpSuccessCallback','gkSuccessCallback','kwikpassSuccess','kpLoginSuccess'].forEach(function(name) {
    try {
      Object.defineProperty(window, name, {
        configurable: true,
        set: function(fn) {
          Object.defineProperty(window, name, {
            configurable: true,
            get: function() {
              return function(data) {
                try {
                  var ph = (data && (data.phone || data.mobile)) || '';
                  if (ph && /^\+?\d{7,15}$/.test(ph.replace(/[\s\-]/g,''))) {
                    sessionStorage.setItem('_gk_phone', ph);
                    console.log('[KwikPass:early] phone via ' + name + ': ' + ph);
                  }
                } catch(_) {}
                if (typeof fn === 'function') return fn.apply(this, arguments);
              };
            }
          });
        }
      });
    } catch(_) {}
  });

  // Intercept fetch — captures phone from GoKwik's send/verify-OTP API calls
  // when GoKwik's coordination script runs in the main frame (not inside the iframe).
  try {
    var _origFetch = window.fetch;
    if (_origFetch) {
      window.fetch = function(input, init) {
        try {
          var url = typeof input === 'string' ? input
                  : (input && input.url) ? String(input.url) : '';
          if (/gokwik|kwikpass|kwik\.in/i.test(url)) {
            var body = init && init.body;
            if (body) {
              try {
                var obj = JSON.parse(typeof body === 'string' ? body : String(body));
                var ph = obj.phone || obj.mobile || obj.phoneNumber || obj.mobileNumber
                      || (obj.data && (obj.data.phone || obj.data.mobile)) || '';
                ph = String(ph).replace(/[\s\-\(\)]/g, '');
                if (/^\+?\d{7,15}$/.test(ph)) {
                  sessionStorage.setItem('_gk_phone', ph);
                  console.log('[KwikPass:early] phone via fetch: ' + ph);
                }
              } catch(_) {}
            }
          }
        } catch(_) {}
        return _origFetch.apply(this, arguments);
      };
    }
  } catch(_) {}

  // Intercept XMLHttpRequest — same, for older GoKwik builds using XHR.
  try {
    var _origXhrOpen = XMLHttpRequest.prototype.open;
    var _origXhrSend = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.open = function(method, url) {
      this._gkUrl = String(url || '');
      return _origXhrOpen.apply(this, arguments);
    };
    XMLHttpRequest.prototype.send = function(body) {
      try {
        if (/gokwik|kwikpass|kwik\.in/i.test(this._gkUrl || '')) {
          if (body) {
            try {
              var obj = JSON.parse(typeof body === 'string' ? body : String(body));
              var ph = obj.phone || obj.mobile || obj.phoneNumber || obj.mobileNumber
                    || (obj.data && (obj.data.phone || obj.data.mobile)) || '';
              ph = String(ph).replace(/[\s\-\(\)]/g, '');
              if (/^\+?\d{7,15}$/.test(ph)) {
                sessionStorage.setItem('_gk_phone', ph);
                console.log('[KwikPass:early] phone via XHR: ' + ph);
              }
            } catch(_) {}
          }
        }
      } catch(_) {}
      return _origXhrSend.apply(this, arguments);
    };
  } catch(_) {}
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
              initialUserScripts: UnmodifiableListView([
                UserScript(
                  source: _earlyInterceptJs,
                  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                ),
              ]),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
                useWideViewPort: true,
                loadWithOverviewMode: true,
                // Do NOT use incognito: true here. Incognito prevents Shopify's
                // post-OTP session cookies (_shopify_y, _shopify_s) from being
                // written to the persistent WebView cookie store, which means
                // the session is lost the moment this screen is closed.
                // Fresh sessions are already guaranteed by the deleteAllCookies()
                // call in initState above, which runs before this WebView mounts.
                // Let GoKwik's scripts run as if on the real website.
                userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
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
      debugPrint(
          '[KwikPass] account.json fetch failed: ${payload['fetchError']}');
      if (mounted) {
        setState(() {
          _authenticating = false;
          _loginHandled = false; // allow retry on next post-login navigation
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Sign-in could not be verified. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final email = payload['email'] as String? ?? '';
    final firstName = payload['firstName'] as String? ?? '';
    final lastName = payload['lastName'] as String? ?? '';
    final phone = payload['phone'] as String? ?? '';
    final id = payload['id'] as String? ?? '';

    debugPrint('[KwikPass] Identity received — email: $email  phone: $phone  id: $id');

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

    // Read KWIKSESSIONTOKEN while the WebView is still alive.
    // If the JS strategies couldn't capture the phone (GoKwik runs inside a
    // cross-origin iframe so its OTP requests are invisible to our main-frame
    // interceptors), try decoding the phone from the JWT payload as a fallback.
    final kwikToken = await _readKwikSessionToken();
    final resolvedPhone =
        phone.isNotEmpty ? phone : _phoneFromJwt(kwikToken);
    if (resolvedPhone.isNotEmpty && resolvedPhone != phone) {
      debugPrint('[KwikPass] Phone from KWIKSESSIONTOKEN JWT: $resolvedPhone');
    }

    await provider.loginWithIdentity(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: resolvedPhone,
      numericId: numericId,
    );

    if (!mounted) return;

    if (provider.isLoggedIn) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _resolveWithBackend(provider, kwikToken);
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

  // Reads the KWIKSESSIONTOKEN cookie set by GoKwik after successful OTP.
  Future<String> _readKwikSessionToken() async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://earthlyjewels.co'));
      for (final c in cookies) {
        if (c.name == 'KWIKSESSIONTOKEN') {
          return c.value?.toString() ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  // Tries to extract the phone number from a GoKwik KWIKSESSIONTOKEN JWT.
  // GoKwik JWTs are base64url-encoded JSON; the phone is often in the payload
  // under 'phone', 'mobile', or 'phone_number'. Returns '' if not found or
  // if the token is not a valid JWT.
  String _phoneFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      // Base64url → Base64
      String payload = parts[1];
      final pad = (4 - payload.length % 4) % 4;
      payload = payload + ('=' * pad);
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64Decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final ph = json['phone'] ?? json['mobile'] ?? json['phoneNumber'] ??
                 json['mobileNumber'] ?? json['phone_number'] ?? '';
      final phStr = ph.toString().replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (RegExp(r'^\+?\d{7,15}$').hasMatch(phStr)) return phStr;
    } catch (_) {}
    return '';
  }

  // Fire-and-forget: calls the backend proxy to fetch orders and addresses.
  // Silently ignored if the backend URL is not configured or the call fails —
  // the KwikPass identity session is already stored at this point.
  void _resolveWithBackend(CustomerProvider provider, String kwikToken) {
    if (kwikToken.isEmpty) return;
    GoKwikBackendService.instance.resolveCustomer(kwikToken).then((result) {
      if (result != null) {
        provider.updateFromBackend(
          shopifyId: result.shopifyId,
          orders: result.orders,
          addresses: result.addresses,
        );
      }
    }).catchError((_) {});
  }
}
