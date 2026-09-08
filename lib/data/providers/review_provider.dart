import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/shopify_service.dart';

class ReviewProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  List<Review> _storeReviews = [];
  final Map<String, ReviewSummary> _productReviews = {};

  bool _loadingStore = false;
  bool _storeLoaded = false;
  final Set<String> _loadingProducts = {};

  List<Review> get storeReviews => _storeReviews;
  bool get loadingStore => _loadingStore;
  bool get hasStoreReviews => _storeReviews.isNotEmpty;

  ReviewSummary? productReviews(String handle) => _productReviews[handle];
  bool isLoadingProduct(String handle) => _loadingProducts.contains(handle);

  Future<void> loadStoreReviews() async {
    if (_storeLoaded || _loadingStore) return;
    _loadingStore = true;
    notifyListeners();
    try {
      _storeReviews = await _service.fetchStoreReviews(perPage: 10);
    } catch (_) {
      _storeReviews = [];
    } finally {
      _loadingStore = false;
      _storeLoaded = true;
      notifyListeners();
    }
  }

  Future<void> loadProductReviews(String handle) async {
    if (_productReviews.containsKey(handle)) return;
    if (_loadingProducts.contains(handle)) return;
    _loadingProducts.add(handle);
    notifyListeners();

    try {
      final summary = await _service.fetchProductReviews(handle);
      _productReviews[handle] = summary;
    } catch (_) {
      _productReviews[handle] = ReviewSummary.empty();
    } finally {
      _loadingProducts.remove(handle);
      notifyListeners();
    }
  }
}
