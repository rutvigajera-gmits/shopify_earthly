import 'package:flutter/foundation.dart';
import '../models/shop_model.dart';
import '../models/collection_model.dart';
import '../models/review_model.dart';
import '../services/shopify_service.dart';
import '../../core/constants/app_constants.dart';

class ShopProvider extends ChangeNotifier {
  final _service = ShopifyService.instance;

  ShopBrand? _brand;
  List<ShopBanner> _banners = [];
  ShopBanner? _featureBanner;
  List<BrandValue> _brandValues = [];
  List<String> _announcements = [];
  List<MenuItem> _navItems = [];
  List<Collection> _occasionCollections = [];
  List<Collection> _categoryCollections = [];
  List<Collection> _designerCollections = [];
  List<Review> _homeReviews = [];
  ShopBanner? _ctaBanner;
  Map<String, String> _sectionTitles = {};

  bool _loading = false;
  bool _initialized = false;
  String? _apiError;

  ShopBrand? get brand => _brand;
  List<ShopBanner> get banners => _banners;
  ShopBanner? get featureBanner => _featureBanner;
  List<BrandValue> get brandValues => _brandValues;
  List<String> get announcements => _announcements;
  List<MenuItem> get navItems => _navItems;
  List<Collection> get occasionCollections => _occasionCollections;
  List<Collection> get categoryCollections => _categoryCollections;
  List<Collection> get designerCollections => _designerCollections;
  List<Review> get homeReviews => _homeReviews;
  ShopBanner? get ctaBanner => _ctaBanner;
  bool get loading => _loading;
  bool get initialized => _initialized;
  String? get apiError => _apiError;

  String sectionTitle(String key) => _sectionTitles[key] ?? '';

  Future<void> initialize() async {
    if (_initialized) return;
    _loading = true;
    notifyListeners();

    await _loadFromShopify();

    _loading = false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadFromShopify() async {
    await Future.wait([
      _loadBrand(),
      _loadBanners(),
      _loadFeatureBanner(),
      _loadBrandValues(),
      _loadAnnouncements(),
      _loadNavItems(),
      _loadCategoryCollections(),
      _loadOccasionCollections(),
      _loadDesignerCollections(),
      _loadReviews(),
      _loadCtaBanner(),
      _loadSectionTitles(),
    ]);
  }

  Future<void> _loadBrand() async {
    try {
      _brand = await _service.fetchShopBrand();
    } catch (e) {
      _apiError = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _loadBanners() async {
    try {
      final fetched = await _service.fetchBanners();
      if (fetched.isNotEmpty) _banners = fetched;
    } catch (_) {}
  }

  Future<void> _loadFeatureBanner() async {
    try {
      _featureBanner = await _service.fetchFeatureBanner();
    } catch (_) {}
  }

  Future<void> _loadBrandValues() async {
    try {
      _brandValues = await _service.fetchBrandValues();
    } catch (_) {}
  }

  Future<void> _loadAnnouncements() async {
    try {
      final msgs = await _service.fetchAnnouncements();
      if (msgs.isNotEmpty) _announcements = msgs;
    } catch (_) {}
  }

  Future<void> _loadNavItems() async {
    try {
      _navItems = await _service.fetchMainMenu();
    } catch (_) {}
  }

  Future<void> _loadCategoryCollections() async {
    try {
      _categoryCollections = await _service.fetchOccasionCollections(
        AppConstants.categoryCollectionHandles,
      );
    } catch (_) {}
  }

  Future<void> _loadOccasionCollections() async {
    try {
      _occasionCollections = await _service.fetchOccasionCollections(
        AppConstants.occasionHandles,
      );
    } catch (_) {}
  }

  Future<void> _loadDesignerCollections() async {
    try {
      _designerCollections = await _service.fetchOccasionCollections(
        AppConstants.designerRingHandles,
      );
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    try {
      _homeReviews = await _service.fetchStoreReviews(perPage: 10);
    } catch (_) {}
  }

  Future<void> _loadCtaBanner() async {
    try {
      _ctaBanner = await _service.fetchCtaBanner();
    } catch (_) {}
  }

  Future<void> _loadSectionTitles() async {
    try {
      _sectionTitles = await _service.fetchSectionTitles();
    } catch (_) {}
  }
}
