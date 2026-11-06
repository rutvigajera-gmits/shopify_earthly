import '../../data/models/product_model.dart';
import '../../data/models/collection_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/utils/format_utils.dart';
import '../common/base_provider.dart';

class ProductProvider extends BaseProvider {
  final _repo = ProductRepository.instance;

  List<Product> _featuredProducts = [];
  List<Product> _allProducts = [];
  bool _loadingAll = false;
  final Map<String, List<Product>> _collectionCache = {};
  String _currentCollectionHandle = '';
  List<Collection> _collections = [];
  List<Product> _searchResults = [];
  Product? _selectedProduct;

  bool _loadingFeatured = false;
  bool _loadingCollection = false;
  bool _loadingCollections = false;
  bool _loadingSearch = false;
  bool _loadingProduct = false;
  String? _productError;

  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get allProducts => _allProducts;
  List<Product> get collectionProducts =>
      _collectionCache[_currentCollectionHandle] ?? const [];
  String get loadedCollectionHandle => _currentCollectionHandle;
  List<Collection> get collections => _collections;
  List<Product> get searchResults => _searchResults;
  Product? get selectedProduct => _selectedProduct;

  List<Product> collectionProductsFor(String handle) =>
      _collectionCache[handle] ?? const [];

  bool get loadingFeatured => _loadingFeatured;
  bool get loadingAll => _loadingAll;
  bool get loadingCollection => _loadingCollection;
  bool get loadingCollections => _loadingCollections;
  bool get loadingSearch => _loadingSearch;
  bool get loadingProduct => _loadingProduct;
  String? get productError => _productError;

  Future<void> loadFeaturedProducts() async {
    if (_loadingFeatured || _featuredProducts.isNotEmpty) return;
    _loadingFeatured = true;
    notifyListeners();
    try {
      _featuredProducts = await _repo.fetchBestSelling(count: 24);
    } catch (e) {
      setError(e.toString());
    } finally {
      _loadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> loadAllProducts() async {
    if (_loadingAll || _allProducts.isNotEmpty) return;
    _loadingAll = true;
    notifyListeners();
    try {
      _allProducts = await _repo.fetchAll();
    } catch (e) {
      setError(e.toString());
    } finally {
      _loadingAll = false;
      notifyListeners();
    }
  }

  Future<void> loadCollectionProducts(String handle) async {
    if (_loadingCollection) return;
    _currentCollectionHandle = handle;
    if (_collectionCache.containsKey(handle)) {
      notifyListeners();
      return;
    }
    _loadingCollection = true;
    notifyListeners();
    try {
      _collectionCache[handle] = await _repo.fetchByCollection(handle);
    } catch (e) {
      setError(e.toString());
      _collectionCache[handle] = [];
    } finally {
      _loadingCollection = false;
      notifyListeners();
    }
  }

  Future<void> loadCollections() async {
    if (_loadingCollections || _collections.isNotEmpty) return;
    _loadingCollections = true;
    notifyListeners();
    try {
      _collections = await _repo.fetchCollections(count: 8);
    } catch (e) {
      setError(e.toString());
    } finally {
      _loadingCollections = false;
      notifyListeners();
    }
  }

  Future<void> loadProductByHandle(String handle) async {
    _loadingProduct = true;
    _selectedProduct = null;
    _productError = null;
    notifyListeners();
    try {
      _selectedProduct = await _repo.fetchByHandle(handle);
    } catch (e) {
      _productError = FormatUtils.trimException(e);
      setError(_productError!);
    } finally {
      _loadingProduct = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _loadingSearch = true;
    notifyListeners();
    try {
      _searchResults = await _repo.search(query.trim());
    } catch (_) {
      _searchResults = _featuredProducts
          .where((p) =>
              p.title.toLowerCase().contains(query.toLowerCase()) ||
              (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                  false))
          .toList();
    } finally {
      _loadingSearch = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
