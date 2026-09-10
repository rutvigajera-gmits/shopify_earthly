import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../services/shopify_service.dart';

class ProductProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  List<Product> _featuredProducts = [];
  List<Product> _collectionProducts = [];
  String _loadedCollectionHandle = '';
  List<Collection> _collections = [];
  List<Product> _searchResults = [];
  Product? _selectedProduct;

  bool _loadingFeatured = false;
  bool _loadingCollection = false;
  bool _loadingCollections = false;
  bool _loadingSearch = false;
  bool _loadingProduct = false;

  String? _error;
  String? _productError;

  List<Product> get featuredProducts => _featuredProducts;
  List<Product> get collectionProducts => _collectionProducts;
  String get loadedCollectionHandle => _loadedCollectionHandle;
  List<Collection> get collections => _collections;
  List<Product> get searchResults => _searchResults;
  Product? get selectedProduct => _selectedProduct;

  bool get loadingFeatured => _loadingFeatured;
  bool get loadingCollection => _loadingCollection;
  bool get loadingCollections => _loadingCollections;
  bool get loadingSearch => _loadingSearch;
  bool get loadingProduct => _loadingProduct;

  String? get error => _error;
  String? get productError => _productError;

  Future<void> loadFeaturedProducts() async {
    if (_loadingFeatured) return;
    _loadingFeatured = true;
    _error = null;
    notifyListeners();
    try {
      _featuredProducts = await _service.fetchBestSellingProducts(first: 24);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingFeatured = false;
      notifyListeners();
    }
  }

  Future<void> loadCollectionProducts(String handle) async {
    if (_loadingCollection) return;
    if (_loadedCollectionHandle == handle && _collectionProducts.isNotEmpty) return;
    _loadingCollection = true;
    _error = null;
    notifyListeners();
    try {
      final col = await _service.fetchCollectionByHandle(handle, productCount: 24);
      _collectionProducts = col?.products ?? [];
      _loadedCollectionHandle = handle;
    } catch (e) {
      _error = e.toString();
      _collectionProducts = [];
    } finally {
      _loadingCollection = false;
      notifyListeners();
    }
  }

  Future<void> loadCollections() async {
    if (_loadingCollections) return;
    _loadingCollections = true;
    notifyListeners();
    try {
      _collections = await _service.fetchCollections(first: 8);
    } catch (e) {
      _error = e.toString();
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
      _selectedProduct = await _service.fetchProductByHandle(handle);
    } catch (e) {
      _productError = e.toString().replaceFirst('Exception: ', '');
      _error = _productError;
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
      _searchResults = await _service.searchProducts(query.trim());
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
