import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/home_api_model.dart';

class StorefrontHomeService {
  StorefrontHomeService._();
  static final StorefrontHomeService instance = StorefrontHomeService._();

  static const List<String> _defaultSectionOrder = [
    'hero_banner',
    'brand_values',
    'reviews_carousel',
    'product_grid',
    'shop_by_category',
    'shop_by_shape',
    'occasions',
    'stackable_bands',
    'oriole_exclusive',
    'designer_rings',
    'customize_cta',
    'virtual_call_cta',
    'faq_accordion',
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

  Future<Map<String, dynamic>> _query(String gql) async {
    try {
      final response = await http
          .post(
            Uri.parse(AppConstants.storefrontApiUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Shopify-Storefront-Access-Token':
                  AppConstants.storefrontAccessToken,
            },
            body: jsonEncode({'query': gql}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint('[Home] HTTP ${response.statusCode}');
        return {};
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['errors'] != null) {
        debugPrint('[Home] GraphQL errors: ${decoded['errors']}');
      }
      return decoded['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      debugPrint('[Home] query error: $e');
      return {};
    }
  }

  // ── Public ─────────────────────────────────────────────────────────────────

  Future<HomeApiResponse> fetchHome() async {
    final results = await Future.wait<dynamic>([
      _queryShopAndContent(),
      _querySimpleCollections(),
      _queryOccasions(),
      _queryBestSellers(),
      _queryOrioleProducts(),
      _queryBannerMetaobjects(),
    ]);

    final content = results[0] as Map<String, dynamic>;
    final simpleCols = results[1] as Map<String, dynamic>;
    final occCols = results[2] as Map<String, dynamic>;
    final bestSellers = results[3] as List<HomeProduct>;
    final orioleProducts = results[4] as List<HomeProduct>;
    final bannerSlides = results[5] as List<Map<String, dynamic>>;

    // Shop brand
    final shop = content['shop'] as Map<String, dynamic>? ?? {};
    final brand = shop['brand'] as Map<String, dynamic>?;
    final logoUrl =
        ((brand?['logo'] as Map?)?['image'] as Map?)?['url'] as String? ?? '';
    final shopName = shop['name'] as String? ?? 'Earthly Jewels';
    final slogan = brand?['slogan'] as String? ?? '';

    // Page content
    final configHtml =
        (content['homeConfig'] as Map?)?['body'] as String? ?? '';
    final announcementHtml =
        (content['homeAnnouncements'] as Map?)?['body'] as String? ?? '';
    final brandValuesHtml =
        (content['homeBrandValues'] as Map?)?['body'] as String? ?? '';
    final brandValuesTitle =
        (content['homeBrandValues'] as Map?)?['title'] as String? ?? '';
    final ctaPage = content['homeCustomizeCta'] as Map<String, dynamic>?;
    final virtualCallPage =
        content['homeVirtualCall'] as Map<String, dynamic>?;
    final contactHtml =
        (content['homeContact'] as Map?)?['body'] as String? ?? '';

    final sectionOrder = configHtml.isNotEmpty
        ? _parseSectionOrder(configHtml)
        : List<String>.from(_defaultSectionOrder);

    final announcements = _parseLines(announcementHtml);
    final brandValues = _parseBrandValues(brandValuesHtml);
    // Reviews are now loaded live from Judge.me via ReviewProvider — no static data needed.
    final faqItems = _parseFaq(content['faq'] as Map<String, dynamic>?);
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
        brandValues: brandValues,
        brandValuesTitle: brandValuesTitle,
        faqItems: faqItems,
        ctaPage: ctaPage,
        virtualCallPage: virtualCallPage,
        bannerSlides: bannerSlides,
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
          'footer_links': [
            {
              'heading': 'Useful links',
              'links': [
                {'label': 'Book A Video Call', 'url': '/pages/virtual-consultation'},
                {'label': 'Buy Back / Cancellation Policy', 'url': '/policies/refund-policy'},
                {'label': 'Privacy Policy', 'url': '/policies/privacy-policy'},
                {'label': 'Terms and Condition', 'url': '/policies/terms-of-service'},
                {'label': 'Shipping & Delivery', 'url': '/policies/shipping-policy'},
                {'label': 'FAQ', 'url': '/pages/faq'},
                {'label': 'Blogs', 'url': '/blogs'},
              ],
            },
            {
              'heading': 'Know Your Jewellery',
              'links': [
                {'label': 'Ring Size Chart', 'url': '/pages/ring-size-chart'},
                {'label': 'Bracelet Size Chart', 'url': '/pages/bracelet-size-chart'},
                {'label': 'Growing diamonds', 'url': '/pages/growing-diamonds'},
                {'label': 'The 4cs', 'url': '/pages/the-4cs'},
                {'label': 'Get In Touch', 'url': '/pages/contact'},
              ],
            },
            {
              'heading': 'About Earthly',
              'links': [
                {'label': 'Store Locator', 'url': '/pages/store-locator'},
                {'label': 'About Us', 'url': '/pages/about'},
                {'label': 'Mystique Stone', 'url': '/pages/mystique-stone'},
                {'label': 'Custom Jewellery design', 'url': '/pages/customize'},
                {'label': 'The Founder Story', 'url': '/pages/founder-story'},
              ],
            },
          ],
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
    required List<Map<String, String>> brandValues,
    required String brandValuesTitle,
    required List<Map<String, String>> faqItems,
    required List<Map<String, dynamic>> bannerSlides,
    Map<String, dynamic>? ctaPage,
    Map<String, dynamic>? virtualCallPage,
  }) {
    switch (type) {
      case 'hero_banner':
        return _buildHeroBanner(simpleCols, bannerSlides, order);
      case 'product_grid':
        return _buildProductGrid(bestSellers, order);
      case 'shop_by_category':
        return _buildShopByCategory(simpleCols, order);
      case 'shop_by_shape':
        return _buildShopByShape(simpleCols, order);
      case 'collection_row':
        return _buildCollectionRow(simpleCols, order);
      case 'brand_values':
        return _buildBrandValues(brandValues, brandValuesTitle, order);
      case 'reviews_carousel':
        return _buildReviews(order);
      case 'occasions':
        return _buildOccasions(occCols, order);
      case 'designer_rings':
        return _buildDesignerRings(simpleCols, order);
      case 'stackable_bands':
        return _buildStackableBands(simpleCols, order);
      case 'oriole_exclusive':
        return _buildOrioleExclusive(simpleCols, orioleProducts, order);
      case 'customize_cta':
      case 'full_width_cta':
        return _buildCustomizeCta(ctaPage, order);
      case 'virtual_call_cta':
        return _buildVirtualCallCta(virtualCallPage, order);
      case 'faq_accordion':
        return _buildFaq(faqItems, order);
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
      final imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
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

  HomeSection? _buildCollectionRow(Map<String, dynamic> cols, int order) {
    final tiles = <Map<String, dynamic>>[];
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
      id: 'collection_row',
      type: 'collection_row',
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

  HomeSection? _buildBrandValues(
    List<Map<String, String>> values,
    String title,
    int order,
  ) {
    if (values.isEmpty) return null;
    return HomeSection(
      id: 'brand_values',
      type: 'brand_values',
      visible: true,
      order: order,
      data: {
        'title': title.isNotEmpty ? title : 'Why Earthly Jewels',
        'values': values
            .map((v) => {
                  'icon': v['icon'] ?? '',
                  'title': v['title'] ?? '',
                  'body': v['body'] ?? '',
                })
            .toList(),
      },
    );
  }

  HomeSection? _buildReviews(int order) {
    return HomeSection(
      id: 'reviews_carousel',
      type: 'reviews_carousel',
      visible: true,
      order: order,
      data: {'section_title': 'What Our Customers Say'},
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

  HomeSection? _buildStackableBands(Map<String, dynamic> cols, int order) {
    final col = cols['c14'] as Map<String, dynamic>?;
    final title = col?['title'] as String? ?? '';
    if (title.isEmpty) return null;
    final imageUrl = (col?['image'] as Map?)?['url'] as String? ?? '';
    final description = col?['description'] as String? ?? '';
    final handle = col?['handle'] as String? ?? 'stackable-diamond-bands';
    return HomeSection(
      id: 'stackable_bands',
      type: 'stackable_bands',
      visible: true,
      order: order,
      data: {
        'image_url': imageUrl,
        'title': title,
        'subtitle': description,
        'cta_label': 'View Collection',
        'cta_url': '/collections/$handle',
      },
    );
  }

  HomeSection? _buildOrioleExclusive(
    Map<String, dynamic> cols,
    List<HomeProduct> orioleProducts,
    int order,
  ) {
    if (orioleProducts.isEmpty) return null;
    final col = cols['c13'] as Map<String, dynamic>?;
    final sectionTitle = col?['title'] as String? ?? 'Oriole Diamonds';
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

  HomeSection? _buildCustomizeCta(Map<String, dynamic>? ctaPage, int order) {
    if (ctaPage == null) return null;
    final title = ctaPage['title'] as String? ?? '';
    if (title.isEmpty) return null;
    final bodyHtml = ctaPage['body'] as String? ?? '';
    final subtitle = _extractSubtitle(bodyHtml);
    final imageUrl =
        (ctaPage['featuredImage'] as Map?)?['url'] as String? ?? '';
    return HomeSection(
      id: 'customize_cta',
      type: 'customize_cta',
      visible: true,
      order: order,
      data: {
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'cta_label': 'Customize Now',
        'cta_url': '/pages/customize',
      },
    );
  }

  HomeSection? _buildVirtualCallCta(
      Map<String, dynamic>? page, int order) {
    if (page == null) return null;
    final title = page['title'] as String? ?? '';
    if (title.isEmpty) return null;
    final bodyHtml = page['body'] as String? ?? '';
    final subtitle = _extractSubtitle(bodyHtml);
    final imageUrl =
        (page['featuredImage'] as Map?)?['url'] as String? ?? '';
    return HomeSection(
      id: 'virtual_call_cta',
      type: 'virtual_call_cta',
      visible: true,
      order: order,
      data: {
        'image_url': imageUrl,
        'title': title,
        'subtitle': subtitle,
        'cta_label': 'Schedule Your Call',
        'cta_url': '/pages/virtual-consultation',
      },
    );
  }

  HomeSection? _buildFaq(List<Map<String, String>> items, int order) {
    if (items.isEmpty) return null;
    return HomeSection(
      id: 'faq_accordion',
      type: 'faq_accordion',
      visible: true,
      order: order,
      data: {
        'title': 'Everything you want to know about Earthly Jewels',
        'items': items
            .map((f) => {
                  'question': f['question'] ?? '',
                  'answer': f['answer'] ?? '',
                })
            .toList(),
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
      homeConfig: page(handle: "home-config") { body }
      homeAnnouncements: page(handle: "home-announcements") { body }
      homeBrandValues: page(handle: "home-brand-values") { title body }
      homeCustomizeCta: page(handle: "home-customize-cta") {
        title body
        featuredImage { url }
      }
      homeVirtualCall: page(handle: "home-virtual-call") {
        title body
        featuredImage { url }
      }
      homeContact: page(handle: "home-contact") { body }
      testimonials: blog(handle: "testimonials") {
        articles(first: 8, sortKey: PUBLISHED_AT, reverse: true) {
          edges { node { title contentHtml tags } }
        }
      }
      faq: blog(handle: "faq") {
        articles(first: 20, sortKey: PUBLISHED_AT) {
          edges { node { title contentHtml } }
        }
      }
    }
  ''');

  Future<List<Map<String, dynamic>>> _queryBannerMetaobjects() async {
    const fragment = '''
      edges {
        node {
          fields {
            key value type
            reference { ... on MediaImage { image { url altText } } }
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
          if (imageUrl.isEmpty) continue;
          slides.add({
            'image': imageUrl,
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
      s0:  collectionByHandle(handle: "round-diamond")                      { title handle image { url } }
      s1:  collectionByHandle(handle: "oval-diamond")                       { title handle image { url } }
      s2:  collectionByHandle(handle: "pear-diamond")                       { title handle image { url } }
      s3:  collectionByHandle(handle: "marquise-diamond")                   { title handle image { url } }
      s4:  collectionByHandle(handle: "cushion-cut-engagement-rings")       { title handle image { url } }
      s5:  collectionByHandle(handle: "princess-diamond")                   { title handle image { url } }
      s6:  collectionByHandle(handle: "emerald-diamond")                    { title handle image { url } }
      s7:  collectionByHandle(handle: "heart-diamond")                      { title handle image { url } }
      s8:  collectionByHandle(handle: "asscher-cut-diamond")                { title handle image { url } }
      s9:  collectionByHandle(handle: "radiant-diamond")                    { title handle image { url } }
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

  Future<List<HomeProduct>> _queryOrioleProducts() async {
    final data = await _query('''
      {
        collectionByHandle(handle: "oriole") {
          products(first: 8, sortKey: BEST_SELLING) {
            edges { node { $_pf } }
          }
        }
      }
    ''');
    final col = data['collectionByHandle'] as Map<String, dynamic>?;
    final edges = (col?['products']?['edges'] as List?) ?? [];
    return edges
        .map((e) => HomeProduct.fromJson(
              _productNodeToMap(e['node'] as Map<String, dynamic>),
            ))
        .toList();
  }

  // ── Parsing helpers ────────────────────────────────────────────────────────

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>', dotAll: true), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extractSubtitle(String html) {
    final text = _stripHtml(html);
    return text.length > 250 ? '${text.substring(0, 247)}...' : text;
  }

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

  List<String> _parseSectionOrder(String html) {
    const validTypes = {
      'hero_banner', 'product_grid', 'product_carousel', 'collection_row',
      'shop_by_category', 'brand_values', 'reviews_carousel', 'occasions',
      'designer_rings', 'stackable_bands', 'oriole_exclusive',
      'customize_cta', 'virtual_call_cta', 'full_width_cta',
      'faq_accordion', 'image_text',
    };
    final lines = _parseLines(html)
        .where((l) => validTypes.contains(l.toLowerCase()))
        .toList();
    return lines.isNotEmpty ? lines : List<String>.from(_defaultSectionOrder);
  }

  List<Map<String, String>> _parseBrandValues(String html) {
    if (html.isEmpty) return [];
    final values = <Map<String, String>>[];
    for (final line in _parseLines(html)) {
      final parts = line.split('|');
      if (parts.length >= 3) {
        values.add({
          'icon': parts[0].trim(),
          'title': parts[1].trim(),
          'body': parts.skip(2).join('|').trim(),
        });
      } else if (parts.length == 2) {
        values.add({
          'icon': '',
          'title': parts[0].trim(),
          'body': parts[1].trim(),
        });
      }
    }
    return values;
  }

  List<Map<String, String>> _parseFaq(Map<String, dynamic>? blogData) {
    final edges = (blogData?['articles']?['edges'] as List?) ?? [];
    final items = <Map<String, String>>[];
    for (final edge in edges) {
      final node = edge['node'] as Map<String, dynamic>? ?? {};
      final question = node['title'] as String? ?? '';
      final answer = _stripHtml(node['contentHtml'] as String? ?? '');
      if (question.isNotEmpty && answer.isNotEmpty) {
        items.add({'question': question, 'answer': answer});
      }
    }
    return items;
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
