import '../../data/models/review_model.dart';
import '../../data/repositories/review_repository.dart';
import '../common/base_provider.dart';

class ReviewProvider extends BaseProvider {
  final _repo = ReviewRepository.instance;

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
      _storeReviews = await _repo.fetchStoreReviews();
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
      final summary = await _repo.fetchProductReviews(handle);
      _productReviews[handle] = summary;
    } catch (_) {
      _productReviews[handle] = ReviewSummary.empty();
    } finally {
      _loadingProducts.remove(handle);
      notifyListeners();
    }
  }
}
