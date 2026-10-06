import '../models/review_model.dart';
import '../services/shopify_service.dart';

class ReviewRepository {
  ReviewRepository._();
  static final ReviewRepository instance = ReviewRepository._();

  final _service = ShopifyService.instance;

  Future<List<Review>> fetchStoreReviews({int count = 10}) =>
      _service.fetchStoreReviews(perPage: count);

  Future<ReviewSummary> fetchProductReviews(String handle) =>
      _service.fetchProductReviews(handle);
}
