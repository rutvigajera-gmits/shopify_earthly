import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../component/loader_widget.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/cart_model.dart';
import '../../../data/services/shopify_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/order_provider.dart';

class ShopifyWebCheckoutScreen extends StatefulWidget {
  const ShopifyWebCheckoutScreen({super.key});

  @override
  State<ShopifyWebCheckoutScreen> createState() =>
      _ShopifyWebCheckoutScreenState();
}

class _ShopifyWebCheckoutScreenState extends State<ShopifyWebCheckoutScreen> {
  bool _creating = true;
  String? _webUrl;
  String? _error;
  bool _orderConfirmed = false;

  InAppWebViewController? _webController;

  // Cart snapshot taken at checkout creation time — used for confirmation screen.
  List<CartLineItem> _cartSnapshot = const [];
  double _checkoutTotal = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createCheckout());
  }

  Future<void> _createCheckout() async {
    final cart = context.read<CartProvider>();
    final customer = context.read<CustomerProvider>();

    try {
      final checkout = await ShopifyService.instance.createCheckout(
        lineItems: cart.cart.lines,
        customerAccessToken: customer.accessToken,
      );

      if (checkout.webUrl.isEmpty) {
        throw Exception('Shopify did not return a checkout URL. Please try again.');
      }

      _cartSnapshot = List.from(cart.cart.lines);
      _checkoutTotal = checkout.totalPrice;

      if (mounted) {
        setState(() {
          _webUrl = checkout.webUrl;
          _creating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _creating = false;
        });
      }
    }
  }

  void _onThankYouDetected(WebUri uri) {
    if (_orderConfirmed) return;
    _orderConfirmed = true;

    final orderProvider = context.read<OrderProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final cartProvider = context.read<CartProvider>();

    // Shopify thank-you URL: .../thank_you?order_id=123456&order_token=xxx
    // order_id is numeric; display it with a # prefix.
    final rawId = uri.queryParameters['order_id'] ??
        uri.queryParameters['order_name'] ??
        '';
    final displayId = rawId.isNotEmpty
        ? (rawId.startsWith('#') ? rawId : '#$rawId')
        : 'Confirmed';

    orderProvider.setOrder(
      transactionId: displayId,
      items: _cartSnapshot,
      total: _checkoutTotal,
      customerName: customerProvider.customer?.displayName ?? '',
      deliveryAddress: '',
    );

    customerProvider.invalidateOrders();
    cartProvider.clearCart();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.orderConfirmation);
    }
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrl(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;

    final urlStr = url.toString();
    final scheme = url.scheme.toLowerCase();

    // Shopify order thank-you page — intercept before page loads.
    if (urlStr.contains('thank_you') && !_orderConfirmed) {
      _onThankYouDetected(url);
      return NavigationActionPolicy.CANCEL;
    }

    // UPI and Indian payment app deep-link schemes.
    const paymentSchemes = {
      'upi', 'phonepe', 'gpay', 'paytm', 'bhim', 'tez', 'freecharge',
    };
    if (paymentSchemes.contains(scheme)) {
      try {
        if (await canLaunchUrl(Uri.parse(urlStr))) {
          await launchUrl(Uri.parse(urlStr),
              mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No UPI app found on this device'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (_) {}
      return NavigationActionPolicy.CANCEL;
    }

    // Android intent:// scheme (payment apps on older Android).
    if (scheme == 'intent') {
      try {
        await launchUrl(Uri.parse(urlStr),
            mode: LaunchMode.externalApplication);
      } catch (_) {}
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  Future<void> _onBackPressed() async {
    // Navigate back within checkout WebView if history exists.
    if (_webController != null && await _webController!.canGoBack()) {
      await _webController!.goBack();
      return;
    }

    if (!mounted) return;
    final exit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Leave Checkout?', style: AppTextStyles.headlineSmall),
        content: Text(
          'Your cart is saved. You can return to checkout any time.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Leave',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (exit == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text('Checkout', style: AppTextStyles.headlineSmall),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: _onBackPressed,
            color: AppColors.textPrimary,
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ── Creating checkout ────────────────────────────────────────────────────
    if (_creating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoaderWidget(size: 32),
            SizedBox(height: 20),
            Text('Preparing your checkout…'),
          ],
        ),
      );
    }

    // ── Checkout creation failed ─────────────────────────────────────────────
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Could not start checkout',
                  style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _creating = true;
                    _error = null;
                  });
                  _createCheckout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // ── WebView checkout ─────────────────────────────────────────────────────
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_webUrl!)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportMultipleWindows: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        // Custom user-agent so Shopify serves the mobile checkout layout.
        userAgent:
            'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36 EarthlyJewels-App/1.0',
      ),
      onWebViewCreated: (controller) {
        _webController = controller;
      },
      shouldOverrideUrlLoading: _shouldOverrideUrl,
      onLoadStop: (controller, url) {
        // Secondary detection for navigations that bypass shouldOverrideUrlLoading
        // (e.g. POST-redirect responses from payment gateways).
        if (url != null &&
            url.toString().contains('thank_you') &&
            !_orderConfirmed) {
          _onThankYouDetected(url);
        }
      },
      onCreateWindow: (controller, createWindowAction) async {
        // Load 3DS / bank-redirect popup URLs in the same WebView instead of
        // opening a new window that Flutter cannot display.
        final url = createWindowAction.request.url;
        if (url != null) {
          await controller.loadUrl(urlRequest: URLRequest(url: url));
        }
        return true;
      },
    );
  }
}
