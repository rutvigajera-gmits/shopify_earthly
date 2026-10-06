import '../../core/utils/format_utils.dart';

class ProductImage {
  final String url;
  final String? altText;

  const ProductImage({required this.url, this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: FormatUtils.shopifyImageJpeg(
          json['url'] as String? ?? json['src'] as String? ?? ''),
      altText: json['altText'] as String?,
    );
  }
}

enum ProductMediaType { image, video, externalVideo }

class ProductMediaItem {
  final ProductMediaType type;
  final String url;
  final String? altText;
  final String? thumbnailUrl;

  const ProductMediaItem({
    required this.type,
    required this.url,
    this.altText,
    this.thumbnailUrl,
  });

  bool get isVideo => type != ProductMediaType.image;
  String get displayThumbnail => thumbnailUrl ?? url;

  static ProductMediaItem? fromNode(Map<String, dynamic> node) {
    final contentType = node['mediaContentType'] as String? ?? '';
    switch (contentType) {
      case 'VIDEO':
        final sources = (node['sources'] as List?) ?? [];
        String sourceUrl = '';
        for (final s in sources) {
          final mime = s['mimeType'] as String? ?? '';
          if (mime.contains('mp4')) { sourceUrl = s['url'] as String? ?? ''; break; }
        }
        if (sourceUrl.isEmpty && sources.isNotEmpty) {
          sourceUrl = sources.first['url'] as String? ?? '';
        }
        final thumb = FormatUtils.shopifyImageJpeg(
            (node['previewImage'] as Map?)?['url'] as String? ?? '');
        if (sourceUrl.isEmpty) return null;
        return ProductMediaItem(type: ProductMediaType.video, url: sourceUrl, thumbnailUrl: thumb);
      case 'EXTERNAL_VIDEO':
        final embedUrl = node['embeddedUrl'] as String? ?? '';
        final thumb = FormatUtils.shopifyImageJpeg(
            (node['previewImage'] as Map?)?['url'] as String? ?? '');
        if (embedUrl.isEmpty) return null;
        return ProductMediaItem(type: ProductMediaType.externalVideo, url: embedUrl, thumbnailUrl: thumb);
      default:
        final imageUrl = FormatUtils.shopifyImageJpeg(
            (node['image'] as Map?)?['url'] as String? ?? '');
        final altText = (node['image'] as Map?)?['altText'] as String?;
        if (imageUrl.isEmpty) return null;
        return ProductMediaItem(type: ProductMediaType.image, url: imageUrl, altText: altText);
    }
  }
}

class ProductOption {
  final String name;
  final List<String> values;

  const ProductOption({required this.name, required this.values});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List? ?? [];
    return ProductOption(
      name: json['name'] as String? ?? '',
      values: rawValues.map((v) => v.toString()).toList(),
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
  final List<ProductMediaItem> mediaItems;
  final List<ProductVariant> variants;
  final List<ProductOption> options;
  final List<String> tags;
  final bool availableForSale;

  const Product({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.vendor,
    required this.images,
    this.mediaItems = const <ProductMediaItem>[],
    required this.variants,
    required this.options,
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
    return FormatUtils.formatPrice(price);
  }

  ProductImage? get primaryImage => images.isNotEmpty ? images.first : null;

  bool get isMembersOnly => tags.any(
        (t) => t.toLowerCase().contains('members') || t.toLowerCase().contains('elite'),
      );

  // Always derives option names from variant selectedOptions (guaranteed complete),
  // then uses the API options list for the ordered values when available.
  List<ProductOption> get realOptions {
    // Collect unique option names in variant order
    final names = <String>[];
    for (final v in variants) {
      for (final name in v.selectedOptions.keys) {
        if (!names.contains(name) && name.toLowerCase() != 'title') {
          names.add(name);
        }
      }
    }
    if (names.isEmpty) return [];

    return names.map((name) {
      // Prefer API-provided values (Shopify admin order)
      final apiOpt = options.cast<ProductOption?>().firstWhere(
        (o) => o!.name.toLowerCase() == name.toLowerCase(),
        orElse: () => null,
      );
      if (apiOpt != null && apiOpt.values.isNotEmpty) return apiOpt;

      // Derive values from variants in the order they appear
      final values = <String>[];
      for (final v in variants) {
        final val = v.selectedOptions[name];
        if (val != null && !values.contains(val)) values.add(val);
      }
      return ProductOption(name: name, values: values);
    }).toList();
  }

  factory Product.fromStorefrontJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    List<ProductImage> images = [];
    final imagesData = node['images'];
    if (imagesData is Map && imagesData['edges'] is List) {
      images = (imagesData['edges'] as List)
          .map((e) => ProductImage.fromJson(e['node'] as Map<String, dynamic>))
          .toList();
    }

    // Parse rich media (images + videos) when available
    List<ProductMediaItem>? mediaItems;
    final mediaData = node['media'];
    if (mediaData is Map && mediaData['edges'] is List) {
      final items = <ProductMediaItem>[];
      for (final edge in mediaData['edges'] as List) {
        final item = ProductMediaItem.fromNode(edge['node'] as Map<String, dynamic>);
        if (item != null) items.add(item);
      }
      if (items.isNotEmpty) mediaItems = items;
    }
    // Fallback: derive media items from images list
    mediaItems ??= images.map((img) => ProductMediaItem(
          type: ProductMediaType.image,
          url: img.url,
          altText: img.altText,
        )).toList();

    List<ProductVariant> variants = [];
    final variantsData = node['variants'];
    if (variantsData is Map && variantsData['edges'] is List) {
      variants = (variantsData['edges'] as List)
          .map((e) => ProductVariant.fromJson(e['node'] as Map<String, dynamic>))
          .toList();
    }

    List<ProductOption> options = [];
    final optionsData = node['options'];
    if (optionsData is List) {
      options = optionsData
          .map((o) => ProductOption.fromJson(o as Map<String, dynamic>))
          .where((o) => o.name.isNotEmpty)
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
      mediaItems: mediaItems,
      variants: variants,
      options: options,
      tags: tags,
      availableForSale: node['availableForSale'] as bool? ?? true,
    );
  }
}
