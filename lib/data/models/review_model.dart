class Review {
  final int? id;
  final int rating;
  final String? title;
  final String body;
  final String reviewerName;
  final DateTime? createdAt;
  final String? productTitle;
  final String? productHandle;
  final List<String> pictures;

  const Review({
    this.id,
    required this.rating,
    this.title,
    required this.body,
    required this.reviewerName,
    this.createdAt,
    this.productTitle,
    this.productHandle,
    this.pictures = const [],
  });

  // Parses SPR (Shopify Product Reviews) and Judge.me JSON — same schema.
  factory Review.fromSprJson(Map<String, dynamic> json) {
    final reviewer = json['reviewer'] as Map<String, dynamic>? ?? {};
    final pics = <String>[];
    if (json['pictures'] is List) {
      for (final p in json['pictures'] as List) {
        if (p is! Map) continue;
        // Judge.me v1 API: pictures[].urls.original
        final urls = p['urls'] as Map?;
        final fromUrls = urls?['original'] as String?;
        // Legacy SPR format: pictures[].original
        final fromDirect = p['original'] as String?;
        final url = fromUrls ?? fromDirect;
        if (url != null && url.isNotEmpty) pics.add(url);
      }
    }

    DateTime? createdAt;
    if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'] as String);
      } catch (_) {}
    }

    return Review(
      id: json['id'] as int?,
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      title: json['title'] as String?,
      body: json['body'] as String? ?? '',
      reviewerName: reviewer['name'] as String? ?? '',
      createdAt: createdAt,
      productTitle: json['product_title'] as String?,
      productHandle: json['product_handle'] as String?,
      pictures: pics,
    );
  }

  // Parses a Shopify metaobject node whose fields map to review data.
  factory Review.fromMetaobject(Map<String, dynamic> node) {
    final fieldsList = node['fields'] as List? ?? [];
    final fields = <String, String>{};
    for (final f in fieldsList) {
      final key = f['key'] as String? ?? '';
      final val = f['value'] as String? ?? '';
      if (key.isNotEmpty) fields[key] = val;
    }

    int rating = 5;
    final ratingStr =
        fields['rating'] ?? fields['stars'] ?? fields['score'];
    if (ratingStr != null) {
      rating = int.tryParse(ratingStr) ??
          double.tryParse(ratingStr)?.round() ??
          5;
    }

    DateTime? createdAt;
    final dateStr =
        fields['created_at'] ?? fields['date'] ?? fields['published_at'];
    if (dateStr != null && dateStr.isNotEmpty) {
      try {
        createdAt = DateTime.parse(dateStr);
      } catch (_) {}
    }

    return Review(
      rating: rating.clamp(1, 5),
      title: fields['title'] ?? fields['heading'],
      body: fields['body'] ??
          fields['content'] ??
          fields['text'] ??
          fields['review'] ??
          '',
      reviewerName: fields['reviewer_name'] ??
          fields['author'] ??
          fields['name'] ??
          fields['customer_name'] ??
          '',
      createdAt: createdAt,
      productTitle: fields['product_title'] ?? fields['product'],
      productHandle: fields['product_handle'],
    );
  }

  String get formattedDate {
    if (createdAt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[createdAt!.month - 1]} ${createdAt!.year}';
  }
}

class ReviewSummary {
  final double averageRating;
  final int totalCount;
  final List<Review> reviews;

  const ReviewSummary({
    required this.averageRating,
    required this.totalCount,
    required this.reviews,
  });

  factory ReviewSummary.empty() =>
      const ReviewSummary(averageRating: 0, totalCount: 0, reviews: []);

  factory ReviewSummary.fromSprJson(Map<String, dynamic> json) {
    final list = <Review>[];
    if (json['reviews'] is List) {
      for (final r in json['reviews'] as List) {
        try {
          list.add(Review.fromSprJson(r as Map<String, dynamic>));
        } catch (_) {}
      }
    }

    final total = (json['total'] as num?)?.toInt() ??
        (json['reviews'] as List?)?.length ??
        list.length;

    double avg = 0;
    if (list.isNotEmpty) {
      avg = list.fold(0.0, (s, r) => s + r.rating) / list.length;
    }

    return ReviewSummary(
      averageRating: avg,
      totalCount: total,
      reviews: list,
    );
  }
}
