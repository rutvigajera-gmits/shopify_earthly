import 'product_model.dart';

class CollectionImage {
  final String url;
  final String? altText;

  const CollectionImage({required this.url, this.altText});

  factory CollectionImage.fromJson(Map<String, dynamic> json) {
    return CollectionImage(
      url: json['url'] as String? ?? json['src'] as String? ?? '',
      altText: json['altText'] as String?,
    );
  }
}

class Collection {
  final String id;
  final String handle;
  final String title;
  final String? description;
  final CollectionImage? image;
  final List<Product> products;

  const Collection({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.image,
    this.products = const [],
  });

  factory Collection.fromStorefrontJson(Map<String, dynamic> json) {
    final node = json['node'] ?? json;

    CollectionImage? image;
    if (node['image'] != null) {
      image = CollectionImage.fromJson(node['image'] as Map<String, dynamic>);
    }

    List<Product> products = [];
    final productsData = node['products'];
    if (productsData is Map && productsData['edges'] is List) {
      products = (productsData['edges'] as List)
          .map((e) => Product.fromStorefrontJson(e as Map<String, dynamic>))
          .toList();
    }

    return Collection(
      id: node['id'] as String? ?? '',
      handle: node['handle'] as String? ?? '',
      title: node['title'] as String? ?? '',
      description: node['description'] as String?,
      image: image,
      products: products,
    );
  }
}
