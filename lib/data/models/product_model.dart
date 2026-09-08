class ProductImage {
  final String url;
  final String? altText;

  const ProductImage({required this.url, this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: json['url'] as String? ?? json['src'] as String? ?? '',
      altText: json['altText'] as String?,
    );
  }
}

class ProductVariant {
  final String id;
  final String title;
  final String price;
  final String? compareAtPrice;
  final bool availableForSale;
  final Map<String, String> selectedOptions;

  const ProductVariant({
    required this.id,
    required this.title,
    required this.price,
    this.compareAtPrice,
    required this.availableForSale,
    required this.selectedOptions,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final priceV2 = json['priceV2'] ?? json['price'] ?? {};
    final compareAtPriceV2 = json['compareAtPriceV2'] ?? json['compareAtPrice'];

    final options = <String, String>{};
    if (json['selectedOptions'] is List) {
      for (final opt in (json['selectedOptions'] as List)) {
        options[opt['name'] as String] = opt['value'] as String;
      }
    }

    return ProductVariant(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      price: priceV2 is Map ? (priceV2['amount'] as String? ?? '0') : '0',
      compareAtPrice: compareAtPriceV2 is Map
          ? (compareAtPriceV2['amount'] as String?)
          : null,
      availableForSale: json['availableForSale'] as bool? ?? true,
      selectedOptions: options,
    );
  }

  bool get hasDiscount =>
      compareAtPrice != null &&
      double.tryParse(compareAtPrice!) != null &&
      double.tryParse(price) != null &&
      double.parse(compareAtPrice!) > double.parse(price);
}

class Product {
  final String id;
  final String handle;
  final String title;
  final String? description;
  final String? vendor;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<String> tags;
  final bool availableForSale;

  const Product({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.vendor,
    required this.images,
    required this.variants,
    required this.tags,
    required this.availableForSale,
  });

  String get minPrice {
    if (variants.isEmpty) return '0';
    final prices = variants.map((v) => double.tryParse(v.price) ?? 0).toList();
    return prices.reduce((a, b) => a < b ? a : b).toStringAsFixed(0);
  }

  String get formattedMinPrice {
    final price = double.tryParse(minPrice) ?? 0;
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$formatted';
  }

  ProductImage? get primaryImage => images.isNotEmpty ? images.first : null;

  bool get isMembersOnly => tags.any(
        (t) => t.toLowerCase().contains('members') || t.toLowerCase().contains('elite'),
      );

  factory Product.fromStorefrontJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    List<ProductImage> images = [];
    final imagesData = node['images'];
    if (imagesData is Map && imagesData['edges'] is List) {
      images = (imagesData['edges'] as List)
          .map((e) => ProductImage.fromJson(e['node'] as Map<String, dynamic>))
          .toList();
    }

    List<ProductVariant> variants = [];
    final variantsData = node['variants'];
    if (variantsData is Map && variantsData['edges'] is List) {
      variants = (variantsData['edges'] as List)
          .map((e) => ProductVariant.fromJson(e['node'] as Map<String, dynamic>))
          .toList();
    }

    final tags = (node['tags'] as List?)?.map((t) => t.toString()).toList() ?? [];

    return Product(
      id: node['id'] as String? ?? '',
      handle: node['handle'] as String? ?? '',
      title: node['title'] as String? ?? '',
      description: node['description'] as String?,
      vendor: node['vendor'] as String?,
      images: images,
      variants: variants,
      tags: tags,
      availableForSale: node['availableForSale'] as bool? ?? true,
    );
  }
}
