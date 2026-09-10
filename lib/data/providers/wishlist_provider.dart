import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/shopify_service.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final Set<String> _handles = {};
  List<Product> _products = [];
  bool _loading = false;

  List<String> get handles => List.unmodifiable(_handles.toList());
  List<Product> get products => _products;
  bool get loading => _loading;
  bool contains(String handle) => _handles.contains(handle);

  Future<void> init() async {
    final saved = await WishlistService.getHandles();
    _handles.addAll(saved);
    notifyListeners();
  }

  Future<void> toggle(String handle) async {
    if (_handles.contains(handle)) {
      _handles.remove(handle);
      _products.removeWhere((p) => p.handle == handle);
      await WishlistService.removeHandle(handle);
    } else {
      _handles.add(handle);
      await WishlistService.addHandle(handle);
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    if (_handles.isEmpty) {
      _products = [];
      notifyListeners();
      return;
    }
    if (_loading) return;
    _loading = true;
    notifyListeners();
    try {
      final futures = _handles
          .map((h) => ShopifyService.instance.fetchProductByHandle(h));
      final results = await Future.wait(futures);
      _products = results.whereType<Product>().toList();
    } catch (_) {
      _products = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
