import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../common/base_provider.dart';

class CartProvider extends BaseProvider {
  final _repo = CartRepository.instance;

  Cart _cart = const Cart();

  // Serialises concurrent _ensureCart calls so only one cartCreate is issued.
  Future<void>? _ensureCartFuture;

  Cart get cart => _cart;
  int get itemCount => _cart.totalQuantity;
  String? get checkoutUrl => _cart.checkoutUrl;

  /// Called once on app start to restore the saved cart from Shopify.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(AppStrings.cartIdKey);
      if (savedId == null || savedId.isEmpty) return;
      final restored = await _repo.fetchCart(savedId);
      if (restored != null && restored.id != null) {
        _cart = restored;
        notifyListeners();
      } else {
        // Cart expired or not found on Shopify — drop the stale ID.
        await prefs.remove(AppStrings.cartIdKey);
      }
    } catch (_) {
      // Network error — silently start with empty cart; it will be recreated on first add.
    }
  }

  Future<void> _ensureCart() {
    if (_cart.id != null) return Future.value();
    return _ensureCartFuture ??=
        _createNewCart().whenComplete(() => _ensureCartFuture = null);
  }

  Future<void> _createNewCart() async {
    _cart = await _repo.createCart();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppStrings.cartIdKey, _cart.id!);
  }

  Future<void> addItem(String variantId, int quantity) async {
    setLoading();
    try {
      await _ensureCart();
      _cart = await _repo.addItem(_cart.id!, variantId, quantity);
      setLoaded();
      _pushItemToWebCart(variantId, quantity);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> updateQuantity(String lineId, int quantity) async {
    if (_cart.id == null) return;
    setLoading();
    try {
      if (quantity <= 0) {
        _cart = await _repo.removeItem(_cart.id!, lineId);
      } else {
        _cart = await _repo.updateItem(_cart.id!, lineId, quantity);
      }
      setLoaded();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> removeItem(String lineId) async {
    if (_cart.id == null) return;
    setLoading();
    try {
      _cart = await _repo.removeItem(_cart.id!, lineId);
      setLoaded();
    } catch (e) {
      setError(e.toString());
    }
  }

  /// Associates the current cart with a logged-in customer so Shopify
  /// links it to their account. Call this after login and on app startup
  /// when a saved cart + customer token are both available.
  /// Silent on failure — existing cart behaviour is fully preserved.
  Future<void> associateWithCustomer(String customerAccessToken) async {
    if (_cart.id == null || customerAccessToken.isEmpty) return;
    try {
      final updated =
          await _repo.associateWithCustomer(_cart.id!, customerAccessToken);
      if (updated.id != null) {
        _cart = updated;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> clearCart() async {
    _cart = const Cart();
    clearError();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.cartIdKey);
  }

  /// Pushes all current app cart items to the Shopify web cart via AJAX so
  /// the same items appear when the user views earthlyjewels.co in any browser
  /// after logging in. Only runs if the app cart has items AND a Shopify
  /// session cookie is present (i.e. user went through KwikPass). Silent.
  Future<void> syncToWebCart() async {
    if (_cart.lines.isEmpty) return;
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://earthlyjewels.co'));
      final hasCartCookie =
          cookies.any((c) => c.name == 'cart' && c.value.isNotEmpty);
      if (!hasCartCookie) return;

      final cookieHeader =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');

      final items = _cart.lines
          .map((line) {
            final numericId = int.tryParse(line.variantId.split('/').last);
            return numericId != null
                ? {'id': numericId, 'quantity': line.quantity}
                : null;
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      if (items.isEmpty) return;

      await http
          .post(
            Uri.parse('https://earthlyjewels.co/cart/add.js'),
            headers: {
              'Cookie': cookieHeader,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: jsonEncode({'items': items}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Fire-and-forget: pushes a single variant to the web cart when the user
  /// adds it to the app cart while already logged in (KwikPass session active).
  Future<void> _pushItemToWebCart(String variantGid, int quantity) async {
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://earthlyjewels.co'));
      final hasCartCookie =
          cookies.any((c) => c.name == 'cart' && c.value.isNotEmpty);
      if (!hasCartCookie) return;

      final numericId = int.tryParse(variantGid.split('/').last);
      if (numericId == null) return;

      final cookieHeader =
          cookies.map((c) => '${c.name}=${c.value}').join('; ');
      await http
          .post(
            Uri.parse('https://earthlyjewels.co/cart/add.js'),
            headers: {
              'Cookie': cookieHeader,
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
            },
            body: jsonEncode({
              'items': [
                {'id': numericId, 'quantity': quantity}
              ]
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  /// Reads the Shopify web cart via the InAppWebView cookie store and adds its
  /// items to the Storefront API cart if the app cart is currently empty.
  /// Call this after login and on app startup. Silent on any failure.
  Future<void> syncFromWebCart() async {
    if (_cart.lines.isNotEmpty) return;
    try {
      final cookies = await CookieManager.instance()
          .getCookies(url: WebUri('https://earthlyjewels.co'));

      String? cartToken;
      for (final c in cookies) {
        if (c.name == 'cart') {
          cartToken = c.value;
          break;
        }
      }
      if (cartToken == null || cartToken.isEmpty) return;

      final response = await http
          .get(
            Uri.parse('https://earthlyjewels.co/cart.js'),
            headers: {
              'Cookie': 'cart=$cartToken',
              'Accept': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final cartJson = jsonDecode(response.body) as Map<String, dynamic>;
      final items = cartJson['items'] as List? ?? [];
      if (items.isEmpty) return;

      await _ensureCart();
      for (final item in items) {
        final variantIdNum = item['variant_id'];
        final quantity = item['quantity'] as int? ?? 1;
        if (variantIdNum != null) {
          _cart = await _repo.addItem(
            _cart.id!,
            'gid://shopify/ProductVariant/$variantIdNum',
            quantity,
          );
        }
      }
      notifyListeners();
    } catch (_) {}
  }
}
