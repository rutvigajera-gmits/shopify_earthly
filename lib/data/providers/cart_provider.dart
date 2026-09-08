import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../services/shopify_service.dart';

class CartProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  Cart _cart = const Cart();
  bool _loading = false;
  String? _error;

  Cart get cart => _cart;
  bool get loading => _loading;
  String? get error => _error;
  int get itemCount => _cart.totalQuantity;

  Future<void> _ensureCart() async {
    if (_cart.id == null) {
      final newCart = await _service.createCart();
      _cart = newCart;
    }
  }

  Future<void> addItem(String variantId, int quantity) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _ensureCart();
      _cart = await _service.addToCart(_cart.id!, variantId, quantity);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String lineId, int quantity) async {
    if (_cart.id == null) return;
    _loading = true;
    notifyListeners();
    try {
      if (quantity <= 0) {
        _cart = await _service.removeFromCart(_cart.id!, lineId);
      } else {
        _cart = await _service.updateCartLine(_cart.id!, lineId, quantity);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String lineId) async {
    if (_cart.id == null) return;
    _loading = true;
    notifyListeners();
    try {
      _cart = await _service.removeFromCart(_cart.id!, lineId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String? get checkoutUrl => _cart.checkoutUrl;
}
