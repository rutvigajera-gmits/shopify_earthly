import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/cart_model.dart';
import '../../data/repositories/cart_repository.dart';
import '../common/base_provider.dart';

class CartProvider extends BaseProvider {
  final _repo = CartRepository.instance;

  Cart _cart = const Cart();

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

  Future<void> _ensureCart() async {
    if (_cart.id == null) {
      _cart = await _repo.createCart();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppStrings.cartIdKey, _cart.id!);
    }
  }

  Future<void> addItem(String variantId, int quantity) async {
    setLoading();
    try {
      await _ensureCart();
      _cart = await _repo.addItem(_cart.id!, variantId, quantity);
      setLoaded();
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

  Future<void> clearCart() async {
    _cart = const Cart();
    clearError();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStrings.cartIdKey);
  }
}
