import 'package:flutter/foundation.dart';
import '../models/home_api_model.dart';
import '../network/shopify_client.dart';

class StorefrontHomeService {
  StorefrontHomeService._();
  static final StorefrontHomeService instance = StorefrontHomeService._();

  static const List<String> _defaultSectionOrder = [
    'hero_banner',
    'shop_by_category',
    'product_grid',
    'designer_rings',
    'occasions',
    'shop_by_shape',
    'oriole_exclusive',
    'instagram_reels',
  ];

  static const List<String> _occasionHandles = [
    'lab-grown-diamond-engagement-rings',
    'eternity-rings',
    'dailywear',
    'gifts-for-her',
  ];

  static const String _pf = '''
    id handle title vendor availableForSale
    images(first: 2) { edges { node { url altText } } }
    variants(first: 1) {
      edges {
        node {
          id title availableForSale
          priceV2 { amount currencyCode }
          compareAtPriceV2 { amount currencyCode }
          selectedOptions { name value }
        }
      }
    }
  ''';

  // ── HTTP helper ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _query(String gql) =>
      ShopifyClient.instance.safeQuery(gql);

  // ── Public ─────────────────────────────────────────────────────────────────

  Future<HomeApiResponse> fetchHome() async {
    final results = await Future.wait<dynamic>([
      _queryShopAndContent(),
      _querySimpleCollections(),
      _queryOccasions(),
      _queryBestSellers(),
      _queryOrioleProducts(),
      _queryBannerMetaobjects(),
      _queryInstagramReels(),
      _queryShapeCollections(),
    ]);

    final content = results[0] as Map<String, dynamic>;
    final simpleCols = results[1] as Map<String, dynamic>;
    final occCols = results[2] as Map<String, dynamic>;
    final bestSellers = results[3] as List<HomeProduct>;
    final orioleProducts = results[4] as List<HomeProduct>;
    final bannerSlides = results[5] as List<Map<String, dynamic>>;
    final instagramReels = results[6] as List<Map<String, dynamic>>;
    final shapeCols = results[7] as Map<String, dynamic>;

    // Shop brand
    final shop = content['shop'] as Map<String, dynamic>? ?? {};
    final brand = shop['brand'] as Map<String, dynamic>?;
    final logoUrl =
        ((brand?['logo'] as Map?)?['image'] as Map?)?['url'] as String? ?? '';
    final shopName = shop['name'] as String? ?? 'Earthly Jewels';
    final slogan = brand?['slogan'] as String? ?? '';

    // Page content
    final announcementHtml =
        (content['homeAnnouncements'] as Map?)?['body'] as String? ?? '';
    final contactHtml =
        (content['homeContact'] as Map?)?['body'] as String? ?? '';

    final sectionOrder = List<String>.from(_defaultSectionOrder);

    final announcements = _parseLines(announcementHtml);
    final contact = _parseContact(contactHtml);

    // Build sections
    final sections = <HomeSection>[];
    for (var i = 0; i < sectionOrder.length; i++) {
      final section = _buildSection(
        type: sectionOrder[i],
        order: i,
        simpleCols: simpleCols,
        occCols: occCols,
        bestSellers: bestSellers,
        orioleProducts: orioleProducts,
        bannerSlides: bannerSlides,
        instagramReels: instagramReels,
        shapeCols: shapeCols,
      );
      if (section != null) sections.add(section);
    }

    return HomeApiResponse(
      theme: HomeTheme.fromJson({
        'logo': {'url': logoUrl, 'width': 200, 'height': 60},
        'logo_square': {'url': logoUrl, 'width': 60, 'height': 60},
        'favicon': '',
        'colors': {},
        'typography': {},
        'layout': {},
      }),
      global: HomeGlobal.fromJson({
        'shop_name': shopName,
        'shop_tagline': slogan,
        'currency_code': 'INR',
        'currency_symbol': '₹',
        'contact': contact,
        'social': {
          'instagram': 'https://www.instagram.com/earthlyjewels.co/',
          'youtube': '',
          'pinterest': '',
          'linkedin': '',
        },
        'announcements': announcements,
        'navigation': {
          'header': [],
          'footer': [],
        },
      }),
      sections: sections,
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  HomeSection? _buildSection({
    required String type,
    required int order,
    required Map<String, dynamic> simpleCols,
    required Map<String, dynamic> occCols,
    required List<HomeProduct> bestSellers,
    required List<HomeProduct> orioleProducts,
    required List<Map<String, dynamic>> bannerSlides,
    required List<Map<String, dynamic>> instagramReels,
    required Map<String, dynamic> shapeCols,
  }) {
    switch (type) {
      case 'hero_banner':
        return _buildHeroBanner(simpleCols, bannerSlides, order);
      case 'shop_by_category':
        return _buildShopByCategory(simpleCols, order);
      case 'product_grid':
        return _buildProductGrid(bestSellers, order);
      case 'designer_rings':
        return _buildDesignerRings(simpleCols, order);
      case 'occasions':
        return _buildOccasions(occCols, order);
      case 'shop_by_shape':
        return _buildShopByShape(shapeCols, order);
      case 'oriole_exclusive':
        return _buildOrioleExclusive(simpleCols, orioleProducts, order);
      case 'instagram_reels':
        return _buildInstagramReels(instagramReels, order);
      default:
        return null;
    }
  }

  HomeSection? _buildHeroBanner(
    Map<String, dynamic> cols,
    List<Map<String, dynamic>> metaSlides,
    int order,
  ) {
    // Use live metaobject slides if available
    if (metaSlides.isNotEmpty) {
      return HomeSection(
        id: 'hero_banner',
        type: 'hero_banner',
        visible: true,
        order: order,
        data: {'slides': metaSlides},
      );
    }

    // Fall back to collection cover images
    final slides = <Map<String, dynamic>>[];
    for (final idx in [0, 1, 2, 3, 12]) {
      final col = cols['c$idx'] as Map<String, dynamic>?;
      final imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
      if (imageUrl.isEmpty) continue;
      slides.add({
        'image': imageUrl,
        'title': '',
        'subtitle': '',
        'cta_label': 'Shop Now',
        'cta_url': '/collections/${col?['handle'] ?? ''}',
        'text_color': '#FFFFFF',
        'overlay': 0.35,
      });
    }
    if (slides.isEmpty) return null;
    return HomeSection(
      id: 'hero_banner',
      type: 'hero_banner',
      visible: true,
      order: order,
      data: {'slides': slides},
    );
  }

  HomeSection? _buildProductGrid(List<HomeProduct> products, int order) {
    if (products.isEmpty) return null;
    return HomeSection(
      id: 'product_grid',
      type: 'product_grid',
      visible: true,
      order: order,
      data: {
        'title': 'Most Loved Pieces',
        'cta_label': 'View All Trending Designs',
        'cta_url': '/collections/all',
        'columns': 2,
        'products': products.map(_homeProductToMap).toList(),
      },
    );
  }

  HomeSection? _buildShopByCategory(Map<String, dynamic> cols, int order) {
    final tiles = <Map<String, dynamic>>[];
    // c0=rings (featured hero), c1=earrings, c2=necklace, c3=bracelets, c4=mens-ring
    for (final idx in [0, 1, 2, 3, 4]) {
      final col = cols['c$idx'] as Map<String, dynamic>?;
      final imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
      if (imageUrl.isEmpty) continue;
      tiles.add({
        'handle': col?['handle'] as String? ?? '',
        'title': col?['title'] as String? ?? '',
        'image_url': imageUrl,
        'description': col?['description'] as String? ?? '',
      });
    }
    if (tiles.isEmpty) return null;
    return HomeSection(
      id: 'shop_by_category',
      type: 'shop_by_category',
      visible: true,
      order: order,
      data: {
        'title': 'Shop by Category',
        'cta_label': 'View All',
        'cta_url': '/collections/all',
        'tiles': tiles,
      },
    );
  }

  static const Map<String, String> _shapeLabels = {
    's0': 'Round',
    's1': 'Oval',
    's2': 'Pear',
    's3': 'Marquise',
    's4': 'Cushion',
    's5': 'Princess',
    's6': 'Emerald',
    's7': 'Heart',
    's8': 'Asscher',
    's9': 'Radiant',
  };

  HomeSection? _buildShopByShape(Map<String, dynamic> cols, int order) {
    final tiles = <Map<String, dynamic>>[];
    for (final entry in _shapeLabels.entries) {
      final col = cols[entry.key] as Map<String, dynamic>?;
      String imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
      // Fallback: use first product image when collection has no cover image
      if (imageUrl.isEmpty) {
        final productEdges =
            ((col?['products'] as Map?)?['edges'] as List?) ?? [];
        if (productEdges.isNotEmpty) {
          final node =
              (productEdges.first['node'] as Map<String, dynamic>?) ?? {};
          final imgEdges =
              ((node['images'] as Map?)?['edges'] as List?) ?? [];
          if (imgEdges.isNotEmpty) {
            imageUrl =
                (imgEdges.first['node'] as Map?)?['url'] as String? ?? '';
          }
        }
      }
      if (imageUrl.isEmpty) continue;
      tiles.add({
        'handle': col?['handle'] as String? ?? '',
        'title': entry.value,
        'image_url': imageUrl,
        'description': '',
      });
    }
    if (tiles.isEmpty) return null;
    return HomeSection(
      id: 'shop_by_shape',
      type: 'shop_by_shape',
      visible: true,
      order: order,
      data: {
        'title': 'Shop by Shape',
        'cta_label': '',
        'cta_url': '/collections/lab-grown-diamond-rings',
        'tiles': tiles,
      },
    );
  }


  HomeSection? _buildOccasions(Map<String, dynamic> occCols, int order) {
    final tabs = <Map<String, dynamic>>[];
    for (var i = 0; i < _occasionHandles.length; i++) {
      final col = occCols['o$i'] as Map<String, dynamic>?;
      if (col == null) continue;
      final imageUrl = (col['image'] as Map?)?['url'] as String? ?? '';
      final products =
          ((col['products'] as Map?)?['edges'] as List? ?? [])
              .map((e) => _productNodeToMap(e['node'] as Map<String, dynamic>))
              .toList();
      if (col['title'] == null) continue;
      tabs.add({
        'title': col['title'] as String? ?? '',
        'image_url': imageUrl,
        'handle': col['handle'] as String? ?? _occasionHandles[i],
        'products': products,
      });
    }
    if (tabs.isEmpty) return null;
    return HomeSection(
      id: 'occasions',
      type: 'occasions',
      visible: true,
      order: order,
      data: {
        'title': 'Perfect Sparkle for Every Occasion',
        'cta_label': 'View all',
        'cta_url': '/collections/all',
        'tabs': tabs,
      },
    );
  }

  HomeSection? _buildDesignerRings(Map<String, dynamic> cols, int order) {
    final tiles = <Map<String, dynamic>>[];
    // c0=All Rings, c5=twine, c6=fluid, c7=envy, c8=aura, c9=flora, c10=grace, c11=bezel
    for (final idx in [0, 5, 6, 7, 8, 9, 10, 11]) {
      final col = cols['c$idx'] as Map<String, dynamic>?;
      final imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
      if (imageUrl.isEmpty) continue;
      tiles.add({
        'handle': col?['handle'] as String? ?? '',
        'title': col?['title'] as String? ?? '',
        'image_url': imageUrl,
        'description': col?['description'] as String? ?? '',
      });
    }
    if (tiles.isEmpty) return null;
    return HomeSection(
      id: 'designer_rings',
      type: 'designer_rings',
      visible: true,
      order: order,
      data: {
        'title': 'Designer Rings Collection',
        'cta_label': 'View All Rings',
        'cta_url': '/collections/lab-grown-diamond-rings',
        'tiles': tiles,
      },
    );
  }

  HomeSection? _buildOrioleExclusive(
    Map<String, dynamic> cols,
    List<HomeProduct> orioleProducts,
    int order,
  ) {
    debugPrint('[Oriole] _buildOrioleExclusive called, products: ${orioleProducts.length}');
    if (orioleProducts.isEmpty) return null;
    final col = cols['c13'] as Map<String, dynamic>?;
    final sectionTitle = col?['title'] as String? ?? 'Earthly Exclusive Diamonds';
    final collHandle = col?['handle'] as String? ?? 'oriole';
    return HomeSection(
      id: 'oriole_exclusive',
      type: 'oriole_exclusive',
      visible: true,
      order: order,
      data: {
        'title': sectionTitle,
        'cta_label': 'View Full Oriole Collection',
        'cta_url': '/collections/$collHandle',
        'columns': 2,
        'products': orioleProducts.map(_homeProductToMap).toList(),
      },
    );
  }

  HomeSection _buildInstagramReels(
      List<Map<String, dynamic>> reels, int order) {
    return HomeSection(
      id: 'instagram_reels',
      type: 'instagram_reels',
      visible: true,
      order: order,
      data: {
        'title': 'Instagram Reels & Feeds',
        'instagram_handle': '@earthlyjewels.co',
        'reels': reels,
      },
    );
  }

  // ── GraphQL queries (run in parallel) ─────────────────────────────────────

  Future<Map<String, dynamic>> _queryShopAndContent() => _query('''
    {
      shop {
        name
        brand {
          logo { image { url altText } }
          squareLogo { image { url altText } }
          slogan
          shortDescription
        }
      }
      homeAnnouncements: page(handle: "home-announcements") { body }
      homeContact: page(handle: "home-contact") { body }
    }
  ''');

  Future<List<Map<String, dynamic>>> _queryBannerMetaobjects() async {
    const fragment = '''
      edges {
        node {
          fields {
            key value type
            reference {
              ... on MediaImage { image { url altText } }
              ... on Video { sources { url mimeType } previewImage { url } }
            }
          }
        }
      }
    ''';
    try {
      final data = await _query('''
        {
          b1: metaobjects(type: "hero_banner", first: 8) { $fragment }
          b2: metaobjects(type: "banner",      first: 8) { $fragment }
          b3: metaobjects(type: "slide",       first: 8) { $fragment }
          b4: metaobjects(type: "hero_slide",  first: 8) { $fragment }
        }
      ''');
      for (final alias in ['b1', 'b2', 'b3', 'b4']) {
        final edges = (data[alias]?['edges'] as List?) ?? [];
        if (edges.isEmpty) continue;
        final slides = <Map<String, dynamic>>[];
        for (final edge in edges) {
          final node = edge['node'] as Map<String, dynamic>? ?? {};
          final fieldsList = node['fields'] as List? ?? [];
          String imageUrl = '';
          String videoUrl = '';
          String title = '';
          String subtitle = '';
          String ctaLabel = 'Shop Now';
          String ctaUrl = '';
          for (final f in fieldsList) {
            final key = f['key'] as String? ?? '';
            final val = f['value'] as String? ?? '';
            switch (key) {
              case 'image':
              case 'banner_image':
              case 'background_image':
              case 'photo':
                final ref = f['reference'] as Map<String, dynamic>?;
                imageUrl =
                    (ref?['image'] as Map?)?['url'] as String? ?? '';
              case 'video':
              case 'banner_video':
              case 'background_video':
                final ref = f['reference'] as Map<String, dynamic>?;
                final sources = (ref?['sources'] as List?) ?? [];
                for (final s in sources) {
                  final mime = s['mimeType'] as String? ?? '';
                  if (mime.contains('mp4') || videoUrl.isEmpty) {
                    videoUrl = s['url'] as String? ?? videoUrl;
                  }
                }
              case 'title':
              case 'heading':
                title = val;
              case 'subtitle':
              case 'subheading':
              case 'description':
                subtitle = val;
              case 'cta_label':
              case 'button_text':
              case 'cta_text':
                ctaLabel = val.isNotEmpty ? val : 'Shop Now';
              case 'cta_url':
              case 'link':
              case 'url':
                ctaUrl = val;
            }
          }
          if (imageUrl.isEmpty && videoUrl.isEmpty) continue;
          slides.add({
            'image': imageUrl,
            'video_url': videoUrl,
            'title': title,
            'subtitle': subtitle,
            'cta_label': ctaLabel,
            'cta_url': ctaUrl,
            'text_color': '#FFFFFF',
            'overlay': 0.35,
          });
        }
        if (slides.isNotEmpty) return slides;
      }
    } catch (e) {
      debugPrint('[Home] banner metaobjects error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> _querySimpleCollections() => _query('''
    {
      c0:  collectionByHandle(handle: "lab-grown-diamond-rings")            { title handle description image { url } }
      c1:  collectionByHandle(handle: "lab-grown-diamond-earrings")         { title handle description image { url } }
      c2:  collectionByHandle(handle: "lab-grown-diamond-necklace")         { title handle description image { url } }
      c3:  collectionByHandle(handle: "lab-grown-diamond-bracelets")        { title handle description image { url } }
      c4:  collectionByHandle(handle: "mens-ring")                          { title handle description image { url } }
      c5:  collectionByHandle(handle: "twine")                              { title handle description image { url } }
      c6:  collectionByHandle(handle: "fluid")                              { title handle description image { url } }
      c7:  collectionByHandle(handle: "envy")                               { title handle description image { url } }
      c8:  collectionByHandle(handle: "aura")                               { title handle description image { url } }
      c9:  collectionByHandle(handle: "flora")                              { title handle description image { url } }
      c10: collectionByHandle(handle: "grace")                              { title handle description image { url } }
      c11: collectionByHandle(handle: "bezel")                              { title handle description image { url } }
      c12: collectionByHandle(handle: "lab-grown-diamond-engagement-rings") { title handle description image { url } }
      c13: collectionByHandle(handle: "oriole")                             { title handle description image { url } }
      c14: collectionByHandle(handle: "stackable-diamond-bands")            { title handle description image { url } }
    }
  ''');

  Future<Map<String, dynamic>> _queryOccasions() async {
    const colFragment = '''
      title handle image { url }
      products(first: 6, sortKey: BEST_SELLING) {
        edges { node { $_pf } }
      }
    ''';
    return _query('''
      {
        o0: collectionByHandle(handle: "lab-grown-diamond-engagement-rings") { $colFragment }
        o1: collectionByHandle(handle: "eternity-rings")                     { $colFragment }
        o2: collectionByHandle(handle: "dailywear")                          { $colFragment }
        o3: collectionByHandle(handle: "gifts-for-her")                      { $colFragment }
      }
    ''');
  }

  // Handles of the products shown in "Most Loved Pieces" on the website,
  // in the exact same order as the theme editor selection.
  static const List<String> _mostLovedHandles = [
    'round-diamond-solitaire-ring-with-marquise-side-stones',
    'pear-shape-diamond-vanki-ring',
    'marquise-cut-diamond-ring-with-leaf-design-and-side-accents',
    'oval-cut-diamond-ring-with-marquise-and-round-side-stones',
    'portuguese-round-cut-diamond-ring-with-hidden-halo',
    '2-carat-round-solitaire-diamond-ring',
  ];

  Future<List<HomeProduct>> _queryBestSellers() async {
    // 1. Try "most-loved-pieces" Shopify collection (if merchant creates one)
    final colData = await _query('''
      {
        collection: collectionByHandle(handle: "most-loved-pieces") {
          products(first: 12, sortKey: COLLECTION_DEFAULT) {
            edges { node { $_pf } }
          }
        }
      }
    ''');
    final colEdges =
        (colData['collection']?['products']?['edges'] as List?) ?? [];
    if (colEdges.isNotEmpty) {
      return colEdges
          .map((e) => HomeProduct.fromJson(
                _productNodeToMap(e['node'] as Map<String, dynamic>),
              ))
          .where((p) => !p.title.toLowerCase().contains('membership'))
          .toList();
    }

    // 2. Fetch the exact products shown on the website, in the same order
    final aliases = _mostLovedHandles
        .asMap()
        .entries
        .map((e) => 'p${e.key}: productByHandle(handle: "${e.value}") { $_pf }')
        .join('\n');
    final data = await _query('{ $aliases }');

    final products = <HomeProduct>[];
    for (var i = 0; i < _mostLovedHandles.length; i++) {
      final node = data['p$i'] as Map<String, dynamic>?;
      if (node == null) continue;
      final p = HomeProduct.fromJson(_productNodeToMap(node));
      if (!p.title.toLowerCase().contains('membership')) products.add(p);
    }
    if (products.isNotEmpty) return products;

    // 3. Last resort — global best-selling sort
    final fallback = await _query('''
      {
        products(first: 8, sortKey: BEST_SELLING) {
          edges { node { $_pf } }
        }
      }
    ''');
    final edges = (fallback['products']?['edges'] as List?) ?? [];
    return edges
        .map((e) => HomeProduct.fromJson(
              _productNodeToMap(e['node'] as Map<String, dynamic>),
            ))
        .where((p) => !p.title.toLowerCase().contains('membership'))
        .toList();
  }

  Future<Map<String, dynamic>> _queryShapeCollections() {
    const prodFrag = '''
      products(first: 1) {
        edges { node { images(first: 1) { edges { node { url } } } } }
      }
    ''';
    return _query('''
      {
        s0: collectionByHandle(handle: "round-diamond")                { title handle image { url } $prodFrag }
        s1: collectionByHandle(handle: "oval-diamond")                 { title handle image { url } $prodFrag }
        s2: collectionByHandle(handle: "pear-diamond")                 { title handle image { url } $prodFrag }
        s3: collectionByHandle(handle: "marquise-diamond")             { title handle image { url } $prodFrag }
        s4: collectionByHandle(handle: "cushion-cut-engagement-rings") { title handle image { url } $prodFrag }
        s5: collectionByHandle(handle: "princess-diamond")             { title handle image { url } $prodFrag }
        s6: collectionByHandle(handle: "emerald-diamond")              { title handle image { url } $prodFrag }
        s7: collectionByHandle(handle: "heart-diamond")                { title handle image { url } $prodFrag }
        s8: collectionByHandle(handle: "asscher-cut-diamond")          { title handle image { url } $prodFrag }
        s9: collectionByHandle(handle: "radiant-diamond")              { title handle image { url } $prodFrag }
      }
    ''');
  }

  Future<List<Map<String, dynamic>>> _queryInstagramReels() async {
    try {
      final data = await _query('''
        {
          metaobjects(type: "instagram_reel", first: 12) {
            edges {
              node {
                fields {
                  key value
                  reference {
                    ... on MediaImage { image { url } }
                  }
                }
              }
            }
          }
        }
      ''');
      final edges = (data['metaobjects']?['edges'] as List?) ?? [];
      if (edges.isEmpty) return [];
      final reels = <Map<String, dynamic>>[];
      for (final edge in edges) {
        final fields = (edge['node']?['fields'] as List?) ?? [];
        String thumbnailUrl = '';
        String reelUrl = '';
        String caption = '';
        for (final f in fields) {
          final key = f['key'] as String? ?? '';
          final val = f['value'] as String? ?? '';
          switch (key) {
            case 'thumbnail':
            case 'image':
            case 'cover':
              final ref = f['reference'] as Map<String, dynamic>?;
              thumbnailUrl = (ref?['image'] as Map?)?['url'] as String? ?? '';
            case 'reel_url':
            case 'url':
            case 'link':
              reelUrl = val;
            case 'caption':
            case 'description':
              caption = val;
          }
        }
        if (thumbnailUrl.isEmpty && reelUrl.isEmpty) continue;
        reels.add({
          'thumbnail_url': thumbnailUrl,
          'reel_url': reelUrl,
          'caption': caption,
        });
      }
      return reels;
    } catch (e) {
      debugPrint('[Home] instagram reels error: $e');
      return [];
    }
  }

  static const List<String> _orioleHandles = [
    'oriole',
    'oriole-diamonds',
    'earthly-exclusive-diamonds',
    'earthly-exclusive',
  ];

  Future<List<HomeProduct>> _queryOrioleProducts() async {
    final aliases = _orioleHandles
        .asMap()
        .entries
        .map((e) =>
            'o${e.key}: collectionByHandle(handle: "${e.value}") { products(first: 8, sortKey: BEST_SELLING) { edges { node { $_pf } } } }')
        .join('\n');
    final data = await _query('{ $aliases }');

    for (var i = 0; i < _orioleHandles.length; i++) {
      final col = data['o$i'] as Map<String, dynamic>?;
      final edges = (col?['products']?['edges'] as List?) ?? [];
      debugPrint('[Oriole] handle="${_orioleHandles[i]}" edges=${edges.length}');
      if (edges.isNotEmpty) {
        return edges
            .map((e) => HomeProduct.fromJson(
                  _productNodeToMap(e['node'] as Map<String, dynamic>),
                ))
            .toList();
      }
    }
    debugPrint('[Oriole] no products found in any handle');
    return [];
  }

  // ── Parsing helpers ────────────────────────────────────────────────────────

  List<String> _parseLines(String html) {
    return html
        .replaceAll(
          RegExp(r'</?(?:p|li|br|div|h[1-6])[^>]*>', caseSensitive: false),
          '\n',
        )
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _parseContact(String html) {
    final lines = _parseLines(html);
    String phone = '';
    String email = '';
    String whatsapp = '';
    final addressLines = <String>[];

    for (final line in lines) {
      if (line.contains('@') && line.contains('.')) {
        email = line;
      } else if (RegExp(r'^\+?\d[\d\s\-()]{6,}$').hasMatch(line.replaceAll(' ', ''))) {
        if (phone.isEmpty) {
          phone = line;
        } else {
          whatsapp = line;
        }
      } else {
        addressLines.add(line);
      }
    }

    return {
      'phone': phone,
      'email': email,
      'whatsapp': whatsapp.isNotEmpty ? whatsapp : phone,
      'address': addressLines.join(', '),
    };
  }

  Map<String, dynamic> _productNodeToMap(Map<String, dynamic> node) {
    final images =
        ((node['images'] as Map?)?['edges'] as List? ?? [])
            .map((e) {
              final n = e['node'] as Map<String, dynamic>? ?? {};
              return {
                'url': n['url'] as String? ?? '',
                'alt': n['altText'] as String? ?? '',
              };
            })
            .where((img) => (img['url'] as String).isNotEmpty)
            .toList();

    final variants = ((node['variants'] as Map?)?['edges'] as List? ?? []);
    final firstVariant = variants.isNotEmpty
        ? variants.first['node'] as Map<String, dynamic>?
        : null;
    final priceStr =
        (firstVariant?['priceV2'] as Map?)?['amount'] as String? ?? '0';
    final compareStr =
        (firstVariant?['compareAtPriceV2'] as Map?)?['amount'] as String?;

    return {
      'id': node['id'] as String? ?? '',
      'handle': node['handle'] as String? ?? '',
      'title': node['title'] as String? ?? '',
      'vendor': node['vendor'] as String? ?? '',
      'available': node['availableForSale'] as bool? ?? true,
      'price_amount': double.tryParse(priceStr) ?? 0.0,
      if (compareStr != null &&
          compareStr.isNotEmpty &&
          compareStr != '0.00')
        'compare_at_price_amount': double.tryParse(compareStr) ?? 0.0,
      'currency': 'INR',
      'images': images,
    };
  }

  Map<String, dynamic> _homeProductToMap(HomeProduct p) {
    return {
      'id': p.id,
      'handle': p.handle,
      'title': p.title,
      'vendor': p.vendor,
      'available': p.available,
      'price_amount': double.tryParse(p.price) ?? 0.0,
      if (p.compareAtPrice != null && p.compareAtPrice!.isNotEmpty)
        'compare_at_price_amount': double.tryParse(p.compareAtPrice!) ?? 0.0,
      'currency': p.currency,
      'images': p.images
          .map((img) => {'url': img.url, 'alt': img.alt})
          .toList(),
      if (p.badge != null) 'badge': p.badge!,
    };
  }
}
