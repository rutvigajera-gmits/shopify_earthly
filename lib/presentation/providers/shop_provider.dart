import '../../data/models/shop_model.dart';
import '../../data/models/collection_model.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/home_repository.dart';
import '../common/base_provider.dart';

class ShopProvider extends BaseProvider {
  final _repo = HomeRepository.instance;

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
  bool _initialized = false;

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
  bool get initialized => _initialized;

  String sectionTitle(String key) => _sectionTitles[key] ?? '';

  Future<void> initialize() async {
    if (_initialized) return;
    setLoading();

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

    _initialized = true;
    setLoaded();
  }

  Future<void> _loadBrand() async {
    try { _brand = await _repo.fetchBrand(); } catch (_) {}
  }

  Future<void> _loadBanners() async {
    try {
      final fetched = await _repo.fetchBanners();
      if (fetched.isNotEmpty) _banners = fetched;
    } catch (_) {}
  }

  Future<void> _loadFeatureBanner() async {
    try { _featureBanner = await _repo.fetchFeatureBanner(); } catch (_) {}
  }

  Future<void> _loadBrandValues() async {
    try { _brandValues = await _repo.fetchBrandValues(); } catch (_) {}
  }

  Future<void> _loadAnnouncements() async {
    try {
      final msgs = await _repo.fetchAnnouncements();
      if (msgs.isNotEmpty) _announcements = msgs;
    } catch (_) {}
  }

  Future<void> _loadNavItems() async {
    try { _navItems = await _repo.fetchMainMenu(); } catch (_) {}
  }

  Future<void> _loadCategoryCollections() async {
    try { _categoryCollections = await _repo.fetchCategoryCollections(); } catch (_) {}
  }

  Future<void> _loadOccasionCollections() async {
    try { _occasionCollections = await _repo.fetchOccasionCollections(); } catch (_) {}
  }

  Future<void> _loadDesignerCollections() async {
    try { _designerCollections = await _repo.fetchDesignerCollections(); } catch (_) {}
  }

  Future<void> _loadReviews() async {
    try { _homeReviews = await _repo.fetchHomeReviews(); } catch (_) {}
  }

  Future<void> _loadCtaBanner() async {
    try { _ctaBanner = await _repo.fetchCtaBanner(); } catch (_) {}
  }

  Future<void> _loadSectionTitles() async {
    try { _sectionTitles = await _repo.fetchSectionTitles(); } catch (_) {}
  }
}
