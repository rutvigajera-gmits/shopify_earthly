import '../models/home_api_model.dart';
import '../models/shop_model.dart';
import '../models/collection_model.dart';
import '../models/review_model.dart';
import '../services/storefront_home_service.dart';
import '../services/shopify_service.dart';
import '../../core/constants/app_constants.dart';

class HomeRepository {
  HomeRepository._();
  static final HomeRepository instance = HomeRepository._();

  final _homeService = StorefrontHomeService.instance;
  final _shopService = ShopifyService.instance;

  Future<HomeApiResponse> fetchHome() => _homeService.fetchHome();

  Future<ShopBrand?> fetchBrand() => _shopService.fetchShopBrand();

  Future<List<ShopBanner>> fetchBanners() => _shopService.fetchBanners();

  Future<ShopBanner?> fetchFeatureBanner() => _shopService.fetchFeatureBanner();

  Future<List<BrandValue>> fetchBrandValues() => _shopService.fetchBrandValues();

  Future<List<String>> fetchAnnouncements() => _shopService.fetchAnnouncements();

  Future<List<MenuItem>> fetchMainMenu() => _shopService.fetchMainMenu();

  Future<ShopBanner?> fetchCtaBanner() => _shopService.fetchCtaBanner();

  Future<Map<String, String>> fetchSectionTitles() =>
      _shopService.fetchSectionTitles();

  Future<List<Collection>> fetchCategoryCollections() =>
      _shopService.fetchOccasionCollections(AppConstants.categoryCollectionHandles);

  Future<List<Collection>> fetchOccasionCollections() =>
      _shopService.fetchOccasionCollections(AppConstants.occasionHandles);

  Future<List<Collection>> fetchDesignerCollections() =>
      _shopService.fetchOccasionCollections(AppConstants.designerRingHandles);

  Future<List<Review>> fetchHomeReviews({int count = 10}) =>
      _shopService.fetchStoreReviews(perPage: count);
}
