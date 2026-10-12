import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/customer_provider.dart';
import 'kwik_pass_screen.dart';

/// WebView screen for authenticated Shopify account pages (My Orders,
/// Saved Addresses, etc.) that require a live Shopify web session.
///
/// SESSION RESTORATION FLOW:
///   Shopify's _shopify_s is a session cookie — it is cleared whenever
///   Android kills the app process. GoKwik's own session cookie is
///   persistent (30-90 day expiry) and survives process death.
///
///   When Shopify redirects to /account/login (session expired):
///   1. An overlay is shown so the user never sees the login page.
///   2. GoKwik's JS detects its own persistent cookie and silently
///      re-authenticates — no OTP, no user interaction (1-3 seconds).
///   3. GoKwik navigates to /account; this screen detects that redirect
///      and reloads the original URL (e.g. /account/orders).
///   4. If GoKwik's cookie is also expired (>30-90 days), a 6-second
///      timer fires and KwikPassScreen is pushed as a fallback, which
///      performs the full OTP flow and then reloads the original URL.
class AccountWebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const AccountWebViewScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<AccountWebViewScreen> createState() => _AccountWebViewScreenState();
}

class _AccountWebViewScreenState extends State<AccountWebViewScreen> {
  InAppWebViewController? _controller;
  int _progress = 0;

  // Set when Shopify redirects to /account/login — prevents re-triggering.
  bool _sessionExpiredHandled = false;

  // True while GoKwik is silently re-authenticating. An opaque overlay
  // covers the WebView so the user never sees the login page.
  bool _silentAuthInProgress = false;

  // Fallback timer: if GoKwik hasn't navigated away from /account/login
  // within 6 seconds, its own session has also expired → full OTP flow.
  Timer? _silentAuthTimer;

  @override
  void dispose() {
    _silentAuthTimer?.cancel();
    super.dispose();
  }

  bool _isEarthlyjewelsDomain(WebUri uri) =>
      uri.host == 'earthlyjewels.co' || uri.host == 'www.earthlyjewels.co';

  bool _isLoginRedirect(WebUri uri) =>
      _isEarthlyjewelsDomain(uri) && uri.path.startsWith('/account/login');

  // GoKwik navigates here after silent re-authentication succeeds.
  bool _isPostLoginPath(WebUri uri) {
    if (!_isEarthlyjewelsDomain(uri)) return false;
    final p = uri.path;
    return p == '/account' || p == '/account/' || p == '/';
  }

  // Allow all /account/* paths (covers GoKwik session-restore redirects
  // such as /account/login/multipass/...) plus Shopify's Customer Account
  // OAuth host. Everything outside /account opens in the system browser.
  bool _isAllowedNavigation(WebUri uri) {
    if (uri.host == 'accounts.shopify.com') return true;
    if (!_isEarthlyjewelsDomain(uri)) return false;
    if (uri.path.startsWith('/account')) return true;
    return false;
  }

  void _startSilentAuthTimer() {
    _silentAuthTimer?.cancel();
    _silentAuthTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _silentAuthInProgress) {
        // GoKwik's session is also expired — fall back to full OTP.
        setState(() => _silentAuthInProgress = false);
        _handleSessionExpiry();
      }
    });
  }

  void _onSilentAuthSuccess() {
    _silentAuthTimer?.cancel();
    setState(() {
      _silentAuthInProgress = false;
      _sessionExpiredHandled = false;
      _progress = 0;
    });
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.title, style: AppTextStyles.headlineSmall),
          centerTitle: false,
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    color: AppColors.teal,
                    backgroundColor: AppColors.border,
                  ),
                )
              : null,
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
                userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
              ),
              onWebViewCreated: (controller) => _controller = controller,
              onProgressChanged: (_, p) => setState(() => _progress = p),
              onLoadStop: (_, uri) {
                if (uri == null) return;

                // Session expired — Shopify redirected to login page.
                // Show overlay and let GoKwik silently re-authenticate.
                if (_isLoginRedirect(uri) && !_sessionExpiredHandled) {
                  setState(() {
                    _sessionExpiredHandled = true;
                    _silentAuthInProgress = true;
                  });
                  _startSilentAuthTimer();
                  return;
                }

                // GoKwik silently authenticated — navigated to /account or /.
                if (_silentAuthInProgress && _isPostLoginPath(uri)) {
                  _onSilentAuthSuccess();
                }
              },
              shouldOverrideUrlLoading: (_, action) async {
                final uri = action.request.url;
                if (uri == null) return NavigationActionPolicy.CANCEL;
                if (_isAllowedNavigation(uri))
                  return NavigationActionPolicy.ALLOW;
                launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationActionPolicy.CANCEL;
              },
            ),

            // Shown while GoKwik silently re-establishes the Shopify session.
            // Hides the /account/login page from the user entirely.
            if (_silentAuthInProgress)
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: AppColors.teal,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading ${widget.title}…',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fallback: GoKwik's own session expired. Push KwikPassScreen for full OTP.
  // After OTP, reload the original URL directly.
  // If the user cancels OTP, pop this screen back to Account.
  Future<void> _handleSessionExpiry() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KwikPassScreen()),
    );
    if (!mounted) return;
    final isLoggedIn = context.read<CustomerProvider>().isLoggedIn;
    if (isLoggedIn) {
      setState(() {
        _sessionExpiredHandled = false;
        _progress = 0;
      });
      _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(widget.url)));
    } else {
      Navigator.of(context).pop();
    }
  }
}
