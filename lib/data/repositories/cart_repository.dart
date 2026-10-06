import '../models/cart_model.dart';
import '../services/shopify_service.dart';

class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final _service = ShopifyService.instance;

  Future<Cart?> fetchCart(String cartId) => _service.fetchCart(cartId);

  Future<Cart> createCart() => _service.createCart();

  Future<Cart> addItem(String cartId, String variantId, int quantity) =>
      _service.addToCart(cartId, variantId, quantity);

  Future<Cart> updateItem(String cartId, String lineId, int quantity) =>
      _service.updateCartLine(cartId, lineId, quantity);

  Future<Cart> removeItem(String cartId, String lineId) =>
      _service.removeFromCart(cartId, lineId);
}
