import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../services/shopify_service.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  final _service = ShopifyService.instance;

  Future<List<Product>> fetchBestSelling({int count = 24}) =>
      _service.fetchBestSellingProducts(first: count);

  Future<List<Product>> fetchByCollection(String handle, {int count = 24}) async {
    final col = await _service.fetchCollectionByHandle(handle, productCount: count);
    return col?.products ?? [];
  }

  Future<List<Collection>> fetchCollections({int count = 8}) =>
      _service.fetchCollections(first: count);

  Future<Product?> fetchByHandle(String handle) =>
      _service.fetchProductByHandle(handle);

  Future<List<Product>> search(String query) =>
      _service.searchProducts(query);

  Future<List<Product>> fetchByShape({
    required String shapeName,
    String collectionHandle = '',
    int count = 48,
  }) =>
      _service.fetchShapeProducts(
        shapeName: shapeName,
        collectionHandle: collectionHandle,
        productCount: count,
      );
}
