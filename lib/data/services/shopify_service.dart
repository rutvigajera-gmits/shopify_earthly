import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
// AppConstants is already imported above — no duplicate needed
import '../models/product_model.dart';
import '../models/collection_model.dart';
import '../models/cart_model.dart';
import '../models/shop_model.dart';
import '../models/review_model.dart';
import '../models/customer_model.dart';

class ShopifyService {
  ShopifyService._();
  static final ShopifyService instance = ShopifyService._();

  Future<Map<String, dynamic>> _query(String gql) async {
    final response = await http.post(
      Uri.parse(AppConstants.storefrontApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': AppConstants.storefrontAccessToken,
      },
      body: jsonEncode({'query': gql}),
    );
    if (response.statusCode != 200) {
      debugPrint('[Shopify] HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
      throw Exception('Shopify API ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['errors'] != null) {
      debugPrint('[Shopify] GraphQL error: ${data['errors']}');
      throw Exception('GraphQL: ${data['errors']}');
    }
    return data['data'] as Map<String, dynamic>;
  }

  // ─── Shop Brand & Logo ────────────────────────────────────────────────────

  Future<ShopBrand?> fetchShopBrand() async {
    try {
      final data = await _query('''
        {
          shop {
            name description
            brand {
              logo { image { url altText } }
              squareLogo { image { url altText } }
              slogan shortDescription
              coverImage { image { url altText } }
            }
          }
        }
      ''');
      return ShopBrand.fromStorefrontJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Announcements ────────────────────────────────────────────────────────
  // Returns list of announcement strings from the store.
  // Tries metaobjects first, then shop metafields (JSON-array or single value).

  Future<List<String>> fetchAnnouncements() async {
    // 1. Metaobjects (two types in one batched query)
    try {
      final data = await _query('''
        {
          a1: metaobjects(type: "announcement", first: 10) {
            edges { node { fields { key value } } }
          }
          a2: metaobjects(type: "announcement_bar", first: 10) {
            edges { node { fields { key value } } }
          }
        }
      ''');
      for (final alias in ['a1', 'a2']) {
        final edges = (data[alias]?['edges'] as List?) ?? [];
        if (edges.isEmpty) continue;
        final msgs = <String>[];
        for (final edge in edges) {
          for (final f in (edge['node']['fields'] as List? ?? [])) {
            final key = f['key'] as String? ?? '';
            final val = f['value'] as String? ?? '';
            if ((key == 'text' || key == 'message' || key == 'content') &&
                val.isNotEmpty) {
              msgs.add(val);
            }
          }
        }
        if (msgs.isNotEmpty) return msgs;
      }
    } catch (_) {}

    // 2. Shop metafields (batched with aliases)
    try {
      final data = await _query('''
        {
          shop {
            f1: metafield(namespace: "custom", key: "announcements") { value type }
            f2: metafield(namespace: "custom", key: "announcement_text") { value type }
            f3: metafield(namespace: "custom", key: "announcement") { value type }
            f4: metafield(namespace: "theme", key: "announcement_bar") { value type }
            f5: metafield(namespace: "global", key: "announcement") { value type }
          }
        }
      ''');
      final shop = data['shop'] as Map<String, dynamic>? ?? {};
      for (final alias in ['f1', 'f2', 'f3', 'f4', 'f5']) {
        final mf = shop[alias] as Map?;
        final val = mf?['value'] as String?;
        final type = mf?['type'] as String?;
        if (val == null || val.isEmpty) continue;
        if (type == 'list.single_line_text_field' ||
            val.trimLeft().startsWith('[')) {
          try {
            final list = jsonDecode(val) as List;
            final strings =
                list.whereType<String>().where((s) => s.isNotEmpty).toList();
            if (strings.isNotEmpty) return strings;
          } catch (_) {}
        }
        return [val];
      }
    } catch (_) {}

    return [];
  }

  // ─── Hero Banners ─────────────────────────────────────────────────────────
  // Tries four metaobject types in one batched GraphQL call.
  // Falls back to collection cover images.

  Future<List<ShopBanner>> fetchBanners() async {
    try {
      final data = await _query('''
        {
          b1: metaobjects(type: "hero_banner", first: 5) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          b2: metaobjects(type: "banner", first: 5) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          b3: metaobjects(type: "slide", first: 5) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          b4: metaobjects(type: "hero_slide", first: 5) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
        }
      ''');
      for (final alias in ['b1', 'b2', 'b3', 'b4']) {
        final banners =
            _parseBannersFromEdges((data[alias]?['edges'] as List?) ?? []);
        if (banners.isNotEmpty) return banners;
      }
    } catch (_) {}

    return _fetchBannersFromCollections();
  }

  List<ShopBanner> _parseBannersFromEdges(List edges) {
    final banners = <ShopBanner>[];
    for (final edge in edges) {
      final node = edge['node'] as Map<String, dynamic>? ?? {};
      final fieldsList = node['fields'] as List? ?? [];
      final fields = <String, dynamic>{};
      for (final f in fieldsList) {
        fields[f['key'] as String? ?? ''] = f;
      }
      if (fields.isNotEmpty) {
        final banner = ShopBanner.fromMetaobject(fields);
        if (banner.imageUrl.isNotEmpty) banners.add(banner);
      }
    }
    return banners;
  }

  Future<List<ShopBanner>> _fetchBannersFromCollections() async {
    try {
      final handles = AppConstants.bannerCollectionHandles;
      final aliases = handles.asMap().entries.map((e) => '''
        b${e.key}: collectionByHandle(handle: "${e.value}") {
          title image { url altText }
        }
      ''').join('\n');
      final data = await _query('{ $aliases }');
      final banners = <ShopBanner>[];
      for (var i = 0; i < handles.length; i++) {
        final col = data['b$i'] as Map<String, dynamic>?;
        final imgUrl = col?['image']?['url'] as String?;
        if (imgUrl != null && imgUrl.isNotEmpty) {
          banners.add(ShopBanner.fromCollection(imageUrl: imgUrl, title: ''));
        }
      }
      if (banners.isNotEmpty) return banners;
      // Generic fallback — any collection with an image.
      final cols = await fetchCollections(first: 6);
      return cols
          .where((c) => c.image != null)
          .take(4)
          .map((c) => ShopBanner.fromCollection(imageUrl: c.image!.url, title: ''))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Feature Banner (second section) ─────────────────────────────────────
  // Five metaobject type names tried in one batched query.

  Future<ShopBanner?> fetchFeatureBanner() async {
    try {
      final data = await _query('''
        {
          f1: metaobjects(type: "feature_banner", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          f2: metaobjects(type: "promo_banner", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          f3: metaobjects(type: "second_banner", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          f4: metaobjects(type: "image_with_text", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          f5: metaobjects(type: "homepage_feature", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
        }
      ''');
      for (final alias in ['f1', 'f2', 'f3', 'f4', 'f5']) {
        final edges = (data[alias]?['edges'] as List?) ?? [];
        final banners = _parseBannersFromEdges(edges.take(1).toList());
        if (banners.isNotEmpty) return banners.first;
      }
    } catch (_) {}
    return null;
  }

  // ─── Brand Values (Why Earthly) ───────────────────────────────────────────
  // Five metaobject type names tried in one batched query.

  Future<List<BrandValue>> fetchBrandValues() async {
    try {
      final data = await _query('''
        {
          v1: metaobjects(type: "why_earthly", first: 10) {
            edges { node { fields { key value } } }
          }
          v2: metaobjects(type: "brand_value", first: 10) {
            edges { node { fields { key value } } }
          }
          v3: metaobjects(type: "value_proposition", first: 10) {
            edges { node { fields { key value } } }
          }
          v4: metaobjects(type: "why_us", first: 10) {
            edges { node { fields { key value } } }
          }
          v5: metaobjects(type: "usp", first: 10) {
            edges { node { fields { key value } } }
          }
        }
      ''');
      for (final alias in ['v1', 'v2', 'v3', 'v4', 'v5']) {
        final edges = (data[alias]?['edges'] as List?) ?? [];
        if (edges.isEmpty) continue;
        final values = _parseBrandValuesFromEdges(edges);
        if (values.isNotEmpty) return values;
      }
    } catch (_) {}
    return [];
  }

  List<BrandValue> _parseBrandValuesFromEdges(List edges) {
    final values = <BrandValue>[];
    for (final edge in edges) {
      final node = edge['node'] as Map<String, dynamic>? ?? {};
      final fieldsList = node['fields'] as List? ?? [];
      final fields = <String, dynamic>{};
      for (final f in fieldsList) {
        fields[f['key'] as String? ?? ''] = f;
      }
      if (fields.isNotEmpty) {
        final bv = BrandValue.fromMetaobject(fields);
        if (bv.isValid) values.add(bv);
      }
    }
    return values;
  }

  // ─── CTA Banner ───────────────────────────────────────────────────────────

  Future<ShopBanner?> fetchCtaBanner() async {
    try {
      final data = await _query('''
        {
          c1: metaobjects(type: "cta", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          c2: metaobjects(type: "call_to_action", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          c3: metaobjects(type: "customization_cta", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
          c4: metaobjects(type: "homepage_cta", first: 1) {
            edges { node { fields { key value type reference { ... on MediaImage { image { url altText } } } } } }
          }
        }
      ''');
      for (final alias in ['c1', 'c2', 'c3', 'c4']) {
        final edges = (data[alias]?['edges'] as List?) ?? [];
        if (edges.isEmpty) continue;
        final node = edges.first['node'] as Map<String, dynamic>? ?? {};
        final fieldsList = node['fields'] as List? ?? [];
        final fields = <String, dynamic>{};
        for (final f in fieldsList) {
          fields[f['key'] as String? ?? ''] = f;
        }
        if (fields.isNotEmpty) {
          final banner = ShopBanner.fromMetaobject(fields);
          if (banner.title.isNotEmpty) return banner;
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── Main Navigation Menu ─────────────────────────────────────────────────
  // Returns menu items from whichever handle the store uses.

  Future<List<MenuItem>> fetchMainMenu() async {
    for (final handle in [
      'main-menu',
      'header-menu',
      'navigation',
      'main-navigation',
    ]) {
      try {
        final data = await _query('''
          {
            menu(handle: "$handle") {
              items { title url type }
            }
          }
        ''');
        final items = (data['menu']?['items'] as List?) ?? [];
        if (items.isNotEmpty) {
          return items
              .map((i) => MenuItem.fromJson(i as Map<String, dynamic>))
              .where((m) => m.title.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return [];
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────
  // Source: Judge.me public API (requires Public Token from Judge.me → Settings → General).

  static bool get _judgeMeConfigured =>
      AppConstants.judgeMePublicToken.isNotEmpty &&
      AppConstants.judgeMePublicToken != 'YOUR_PUBLIC_TOKEN_HERE';

  Future<List<Review>> fetchStoreReviews({int perPage = 10}) async {
    if (!_judgeMeConfigured) {
      debugPrint('[JudgeMe] Token not configured — set judgeMePublicToken in app_constants.dart');
      return [];
    }
    try {
      final uri = Uri.parse(
        'https://judge.me/api/v1/reviews'
        '?api_token=${AppConstants.judgeMePublicToken}'
        '&shop_domain=${AppConstants.judgeMeShopDomain}'
        '&per_page=$perPage'
        '&sort_by=created_at'
        '&sort_dir=desc',
      );
      debugPrint('[JudgeMe] fetchStoreReviews → ${uri.host}${uri.path}');
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      debugPrint('[JudgeMe] fetchStoreReviews status=${resp.statusCode} body=${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final summary = ReviewSummary.fromSprJson(body);
        debugPrint('[JudgeMe] fetchStoreReviews → ${summary.reviews.length} reviews');
        return summary.reviews;
      }
    } catch (e) {
      debugPrint('[JudgeMe] fetchStoreReviews error: $e');
    }
    return [];
  }

  Future<ReviewSummary> fetchProductReviews(String handle) async {
    if (!_judgeMeConfigured) return ReviewSummary.empty();
    try {
      final productId = await _fetchShopifyProductId(handle);
      debugPrint('[JudgeMe] fetchProductReviews handle=$handle productId=$productId');
      if (productId == null) return ReviewSummary.empty();

      final uri = Uri.parse(
        'https://judge.me/api/v1/reviews'
        '?api_token=${AppConstants.judgeMePublicToken}'
        '&shop_domain=${AppConstants.judgeMeShopDomain}'
        '&product_id=$productId'
        '&per_page=20'
        '&sort_by=created_at'
        '&sort_dir=desc',
      );
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      debugPrint('[JudgeMe] fetchProductReviews status=${resp.statusCode} body=${resp.body.substring(0, resp.body.length.clamp(0, 300))}');
      if (resp.statusCode == 200) {
        final result = ReviewSummary.fromSprJson(
          jsonDecode(resp.body) as Map<String, dynamic>,
        );
        debugPrint('[JudgeMe] fetchProductReviews → ${result.reviews.length} reviews');
        return result;
      }
    } catch (e) {
      debugPrint('[JudgeMe] fetchProductReviews error: $e');
    }
    return ReviewSummary.empty();
  }

  // Judge.me filters by Shopify numeric product ID, not handle.
  // Resolve handle → GID → numeric ID via Storefront API.
  Future<int?> _fetchShopifyProductId(String handle) async {
    try {
      final data = await _query('{ product(handle: "$handle") { id } }');
      final gid = data['product']?['id'] as String?;
      debugPrint('[JudgeMe] _fetchShopifyProductId handle=$handle gid=$gid');
      if (gid == null) return null;
      return int.tryParse(gid.split('/').last);
    } catch (e) {
      debugPrint('[JudgeMe] _fetchShopifyProductId error: $e');
      return null;
    }
  }

  // ─── Products ─────────────────────────────────────────────────────────────

  Future<List<Product>> fetchBestSellingProducts({int first = 20}) async {
    // Fetch extra so we still have [first] items after filtering non-jewelry.
    final fetch = first + 6;
    final data = await _query('''
      {
        products(first: $fetch, sortKey: BEST_SELLING) {
          edges {
            node {
              id handle title description vendor availableForSale tags
              images(first: 3) { edges { node { url altText } } }
              variants(first: 5) {
                edges {
                  node {
                    id title availableForSale
                    priceV2 { amount currencyCode }
                    compareAtPriceV2 { amount currencyCode }
                    selectedOptions { name value }
                  }
                }
              }
            }
          }
        }
      }
    ''');
    final edges = (data['products']?['edges'] as List?) ?? [];
    return edges
        .map((e) => Product.fromStorefrontJson(e as Map<String, dynamic>))
        .where((p) => !p.title.toLowerCase().contains('membership'))
        .take(first)
        .toList();
  }

  Future<List<Product>> fetchProducts({int first = 20, String? query}) async {
    final filter = query != null ? ', query: "$query"' : '';
    final data = await _query('''
      {
        products(first: $first$filter) {
          edges {
            node {
              id handle title description vendor availableForSale tags
              images(first: 3) { edges { node { url altText } } }
              variants(first: 5) {
                edges {
                  node {
                    id title availableForSale
                    priceV2 { amount currencyCode }
                    compareAtPriceV2 { amount currencyCode }
                    selectedOptions { name value }
                  }
                }
              }
            }
          }
        }
      }
    ''');
    final edges = (data['products']?['edges'] as List?) ?? [];
    return edges
        .map((e) => Product.fromStorefrontJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product?> fetchProductByHandle(String handle) async {
    final data = await _query('''
      {
        productByHandle(handle: "$handle") {
          id handle title description vendor availableForSale tags
          images(first: 8) { edges { node { url altText } } }
          variants(first: 10) {
            edges {
              node {
                id title availableForSale
                priceV2 { amount currencyCode }
                compareAtPriceV2 { amount currencyCode }
                selectedOptions { name value }
              }
            }
          }
          options { name values }
        }
      }
    ''');
    if (data['productByHandle'] == null) return null;
    return Product.fromStorefrontJson(
        data['productByHandle'] as Map<String, dynamic>);
  }

  // ─── Collections ──────────────────────────────────────────────────────────

  Future<List<Collection>> fetchCollections({int first = 10}) async {
    final data = await _query('''
      {
        collections(first: $first) {
          edges {
            node {
              id handle title description
              image { url altText }
              products(first: 8) {
                edges {
                  node {
                    id handle title availableForSale tags
                    images(first: 2) { edges { node { url altText } } }
                    variants(first: 3) {
                      edges {
                        node {
                          id title availableForSale
                          priceV2 { amount currencyCode }
                          compareAtPriceV2 { amount currencyCode }
                          selectedOptions { name value }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''');
    final edges = (data['collections']?['edges'] as List?) ?? [];
    return edges
        .map((e) => Collection.fromStorefrontJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Collection?> fetchCollectionByHandle(
    String handle, {
    int productCount = 24,
  }) async {
    final data = await _query('''
      {
        collectionByHandle(handle: "$handle") {
          id handle title description
          image { url altText }
          products(first: $productCount) {
            edges {
              node {
                id handle title availableForSale tags
                images(first: 2) { edges { node { url altText } } }
                variants(first: 3) {
                  edges {
                    node {
                      id title availableForSale
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      selectedOptions { name value }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''');
    if (data['collectionByHandle'] == null) return null;
    return Collection.fromStorefrontJson(
        data['collectionByHandle'] as Map<String, dynamic>);
  }

  // Fetches multiple collections by handle in a single batched query.
  // Used for the Occasions section.
  Future<List<Collection>> fetchOccasionCollections(
      List<String> handles) async {
    if (handles.isEmpty) return [];
    try {
      final aliases = handles.asMap().entries.map((e) => '''
        col${e.key}: collectionByHandle(handle: "${e.value}") {
          id handle title description
          image { url altText }
        }
      ''').join('\n');

      final data = await _query('{ $aliases }');
      final collections = <Collection>[];
      for (var i = 0; i < handles.length; i++) {
        final json = data['col$i'] as Map<String, dynamic>?;
        if (json != null) {
          collections.add(Collection.fromStorefrontJson(json));
        }
      }
      return collections;
    } catch (_) {
      return [];
    }
  }

  // ─── Cart ─────────────────────────────────────────────────────────────────

  Future<Cart> createCart() async {
    final data = await _query('''
      mutation {
        cartCreate {
          cart {
            id checkoutUrl
            estimatedCost { subtotalAmount { amount currencyCode } }
            lines(first: 50) { edges { node { ${_cartLineFragment()} } } }
          }
        }
      }
    ''');
    return Cart.fromStorefrontJson(data['cartCreate'] as Map<String, dynamic>);
  }

  Future<Cart> addToCart(
      String cartId, String variantId, int quantity) async {
    final data = await _query('''
      mutation {
        cartLinesAdd(cartId: "$cartId", lines: [
          { merchandiseId: "$variantId", quantity: $quantity }
        ]) {
          cart {
            id checkoutUrl
            estimatedCost { subtotalAmount { amount currencyCode } }
            lines(first: 50) { edges { node { ${_cartLineFragment()} } } }
          }
        }
      }
    ''');
    return Cart.fromStorefrontJson(
        data['cartLinesAdd'] as Map<String, dynamic>);
  }

  Future<Cart> updateCartLine(
      String cartId, String lineId, int quantity) async {
    final data = await _query('''
      mutation {
        cartLinesUpdate(cartId: "$cartId", lines: [
          { id: "$lineId", quantity: $quantity }
        ]) {
          cart {
            id checkoutUrl
            estimatedCost { subtotalAmount { amount currencyCode } }
            lines(first: 50) { edges { node { ${_cartLineFragment()} } } }
          }
        }
      }
    ''');
    return Cart.fromStorefrontJson(
        data['cartLinesUpdate'] as Map<String, dynamic>);
  }

  Future<Cart> removeFromCart(String cartId, String lineId) async {
    final data = await _query('''
      mutation {
        cartLinesRemove(cartId: "$cartId", lineIds: ["$lineId"]) {
          cart {
            id checkoutUrl
            estimatedCost { subtotalAmount { amount currencyCode } }
            lines(first: 50) { edges { node { ${_cartLineFragment()} } } }
          }
        }
      }
    ''');
    return Cart.fromStorefrontJson(
        data['cartLinesRemove'] as Map<String, dynamic>);
  }

  String _cartLineFragment() => '''
    id quantity
    estimatedCost { totalAmount { amount currencyCode } }
    merchandise {
      ... on ProductVariant {
        id title
        image { url altText }
        product { id title }
        priceV2 { amount currencyCode }
      }
    }
  ''';

  // ─── Section Titles & Store Contact ──────────────────────────────────────
  // Replaces the earlier fetchSectionTitles — now also includes store contact
  // metafields so the account screen can show address/hours/phone dynamically.

  Future<Map<String, String>> fetchSectionTitles() async {
    try {
      final data = await _query('''
        {
          shop {
            featured_products: metafield(namespace: "section", key: "featured_products") { value }
            why_earthly: metafield(namespace: "section", key: "why_earthly") { value }
            why_earthly_sub: metafield(namespace: "section", key: "why_earthly_subtitle") { value }
            reviews: metafield(namespace: "section", key: "reviews") { value }
            categories: metafield(namespace: "section", key: "categories") { value }
            occasions: metafield(namespace: "section", key: "occasions") { value }
            store_address: metafield(namespace: "custom", key: "store_address") { value }
            store_hours: metafield(namespace: "custom", key: "store_hours") { value }
            store_phone: metafield(namespace: "custom", key: "store_phone") { value }
            store_email: metafield(namespace: "custom", key: "store_email") { value }
          }
        }
      ''');
      final shop = data['shop'] as Map<String, dynamic>? ?? {};
      final result = <String, String>{};
      shop.forEach((key, value) {
        final v = (value as Map?)?['value'] as String?;
        if (v != null && v.isNotEmpty) result[key] = v;
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  // ─── Customer Auth ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _queryWithVars(
      String gql, Map<String, dynamic> variables) async {
    final response = await http.post(
      Uri.parse(AppConstants.storefrontApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': AppConstants.storefrontAccessToken,
      },
      body: jsonEncode({'query': gql, 'variables': variables}),
    );
    if (response.statusCode != 200) {
      throw Exception('Shopify API ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['errors'] != null) {
      throw Exception('GraphQL: ${data['errors']}');
    }
    return data['data'] as Map<String, dynamic>;
  }

  Future<String> loginCustomer({
    required String email,
    required String password,
  }) async {
    final data = await _queryWithVars('''
      mutation login(\$input: CustomerAccessTokenCreateInput!) {
        customerAccessTokenCreate(input: \$input) {
          customerAccessToken { accessToken expiresAt }
          customerUserErrors { code field message }
        }
      }
    ''', {
      'input': {'email': email, 'password': password},
    });
    final result =
        data['customerAccessTokenCreate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Login failed');
    }
    final token =
        result['customerAccessToken']?['accessToken'] as String?;
    if (token == null || token.isEmpty) throw Exception('Login failed');
    return token;
  }

  Future<void> createCustomer({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final data = await _queryWithVars('''
      mutation register(\$input: CustomerCreateInput!) {
        customerCreate(input: \$input) {
          customer { id }
          customerUserErrors { code field message }
        }
      }
    ''', {
      'input': {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
    });
    final result = data['customerCreate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Registration failed');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _queryWithVars('''
      mutation recover(\$email: String!) {
        customerRecover(email: \$email) {
          customerUserErrors { code message }
        }
      }
    ''', {'email': email});
  }

  Future<void> logoutCustomer(String accessToken) async {
    try {
      await _queryWithVars('''
        mutation logout(\$token: String!) {
          customerAccessTokenDelete(customerAccessToken: \$token) {
            deletedAccessToken
          }
        }
      ''', {'token': accessToken});
    } catch (_) {}
  }

  Future<Customer?> fetchCustomer(String accessToken) async {
    try {
      final data = await _queryWithVars('''
        query getCustomer(\$token: String!) {
          customer(customerAccessToken: \$token) {
            id firstName lastName email phone
          }
        }
      ''', {'token': accessToken});
      final json = data['customer'] as Map<String, dynamic>?;
      if (json == null) return null;
      return Customer.fromStorefrontJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<List<CustomerOrder>> fetchCustomerOrders(String accessToken) async {
    final data = await _queryWithVars('''
      query getOrders(\$token: String!) {
        customer(customerAccessToken: \$token) {
          orders(first: 20, sortKey: PROCESSED_AT, reverse: true) {
            edges {
              node {
                id name orderNumber fulfillmentStatus financialStatus
                processedAt
                totalPrice { amount currencyCode }
                lineItems(first: 5) {
                  edges {
                    node {
                      title quantity
                      variant {
                        title
                        image { url altText }
                        price { amount currencyCode }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''', {'token': accessToken});
    final edges =
        (data['customer']?['orders']?['edges'] as List?) ?? [];
    return edges
        .map((e) =>
            CustomerOrder.fromStorefrontJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Customer Profile & Addresses ────────────────────────────────────────

  Future<Customer?> updateCustomer({
    required String accessToken,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final input = <String, dynamic>{};
    if (firstName != null) input['firstName'] = firstName;
    if (lastName != null) input['lastName'] = lastName;
    if (phone != null && phone.isNotEmpty) input['phone'] = phone;

    final data = await _queryWithVars('''
      mutation update(\$token: String!, \$customer: CustomerUpdateInput!) {
        customerUpdate(customerAccessToken: \$token, customer: \$customer) {
          customer { id firstName lastName email phone }
          customerUserErrors { code field message }
        }
      }
    ''', {'token': accessToken, 'customer': input});
    final result = data['customerUpdate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Update failed');
    }
    final json = result['customer'] as Map<String, dynamic>?;
    return json != null ? Customer.fromStorefrontJson(json) : null;
  }

  Future<List<CustomerAddress>> fetchCustomerAddresses(String accessToken) async {
    try {
      final data = await _queryWithVars('''
        query getAddresses(\$token: String!) {
          customer(customerAccessToken: \$token) {
            defaultAddress { id }
            addresses(first: 10) {
              edges {
                node {
                  id firstName lastName company
                  address1 address2 city province country zip phone
                }
              }
            }
          }
        }
      ''', {'token': accessToken});
      final customer = data['customer'] as Map<String, dynamic>?;
      if (customer == null) return [];
      final defaultId =
          (customer['defaultAddress'] as Map?)?['id'] as String? ?? '';
      final edges = (customer['addresses']?['edges'] as List?) ?? [];
      return edges.map((e) {
        final node = e['node'] as Map<String, dynamic>;
        return CustomerAddress.fromStorefrontJson(
          node,
          isDefault: node['id'] == defaultId,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CustomerAddress> createCustomerAddress({
    required String accessToken,
    required Map<String, String> address,
  }) async {
    final data = await _queryWithVars('''
      mutation createAddr(\$token: String!, \$address: MailingAddressInput!) {
        customerAddressCreate(customerAccessToken: \$token, address: \$address) {
          customerAddress {
            id firstName lastName company
            address1 address2 city province country zip phone
          }
          customerUserErrors { code field message }
        }
      }
    ''', {'token': accessToken, 'address': address});
    final result = data['customerAddressCreate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Could not save address');
    }
    final json = result['customerAddress'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Address not returned');
    return CustomerAddress.fromStorefrontJson(json);
  }

  Future<CustomerAddress> updateCustomerAddress({
    required String accessToken,
    required String addressId,
    required Map<String, String> address,
  }) async {
    final data = await _queryWithVars('''
      mutation updateAddr(\$token: String!, \$id: ID!, \$address: MailingAddressInput!) {
        customerAddressUpdate(
          customerAccessToken: \$token, id: \$id, address: \$address
        ) {
          customerAddress {
            id firstName lastName company
            address1 address2 city province country zip phone
          }
          customerUserErrors { code field message }
        }
      }
    ''', {'token': accessToken, 'id': addressId, 'address': address});
    final result = data['customerAddressUpdate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Could not update address');
    }
    final json = result['customerAddress'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Address not returned');
    return CustomerAddress.fromStorefrontJson(json);
  }

  Future<void> deleteCustomerAddress({
    required String accessToken,
    required String addressId,
  }) async {
    final data = await _queryWithVars('''
      mutation deleteAddr(\$token: String!, \$id: ID!) {
        customerAddressDelete(customerAccessToken: \$token, id: \$id) {
          deletedCustomerAddressId
          customerUserErrors { code field message }
        }
      }
    ''', {'token': accessToken, 'id': addressId});
    final result = data['customerAddressDelete'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Could not delete address');
    }
  }

  Future<void> setDefaultCustomerAddress({
    required String accessToken,
    required String addressId,
  }) async {
    final data = await _queryWithVars('''
      mutation setDefault(\$token: String!, \$addressId: ID!) {
        customerDefaultAddressUpdate(
          customerAccessToken: \$token, addressId: \$addressId
        ) {
          customer { id }
          customerUserErrors { code field message }
        }
      }
    ''', {'token': accessToken, 'addressId': addressId});
    final result =
        data['customerDefaultAddressUpdate'] as Map<String, dynamic>? ?? {};
    final errors = result['customerUserErrors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(
          (errors.first as Map)['message'] as String? ?? 'Could not set default');
    }
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<List<Product>> searchProducts(String query) async {
    final escaped = query.replaceAll('"', '\\"');
    final data = await _query('''
      {
        search(query: "$escaped", first: 24, types: PRODUCT) {
          edges {
            node {
              ... on Product {
                id handle title description vendor availableForSale tags
                images(first: 3) { edges { node { url altText } } }
                variants(first: 5) {
                  edges {
                    node {
                      id title availableForSale
                      priceV2 { amount currencyCode }
                      compareAtPriceV2 { amount currencyCode }
                      selectedOptions { name value }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ''');
    final edges = (data['search']?['edges'] as List?) ?? [];
    return edges
        .map((e) => Product.fromStorefrontJson(e as Map<String, dynamic>))
        .where((p) => p.handle.isNotEmpty)
        .toList();
  }
}
