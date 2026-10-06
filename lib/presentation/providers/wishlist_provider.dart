import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/wishlist_service.dart';
import '../common/base_provider.dart';

class WishlistProvider extends BaseProvider {
  final Set<String> _handles = {};
  List<Product> _products = [];
  bool _loadingProducts = false;

  List<String> get handles => List.unmodifiable(_handles.toList());
  List<Product> get products => _products;
  bool get loadingProducts => _loadingProducts;
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
    if (_loadingProducts) return;
    _loadingProducts = true;
    notifyListeners();
    try {
      final futures = _handles.map((h) => ProductRepository.instance.fetchByHandle(h));
      final results = await Future.wait(futures);
      _products = results.whereType<Product>().toList();
    } catch (_) {
      _products = [];
    } finally {
      _loadingProducts = false;
      notifyListeners();
    }
  }
}
