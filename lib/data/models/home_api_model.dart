import 'product_model.dart';

// Safely converts any Map (dynamic, String→Object, etc.) to Map<String, dynamic>.
// Prevents runtime TypeError when manually-constructed maps are passed to fromJson.
Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

// ─── Root response ────────────────────────────────────────────────────────────

class HomeApiResponse {
  final HomeTheme theme;
  final HomeGlobal global;
  final List<HomeSection> sections;

  const HomeApiResponse({
    required this.theme,
    required this.global,
    required this.sections,
  });

  factory HomeApiResponse.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List? ?? [])
        .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
        .where((s) => s.visible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return HomeApiResponse(
      theme: HomeTheme.fromJson(_asMap(json['theme'])),
      global: HomeGlobal.fromJson(_asMap(json['global'])),
      sections: rawSections,
    );
  }
}

// ─── Theme ────────────────────────────────────────────────────────────────────

class HomeTheme {
  final HomeLogo logo;
  final HomeLogo logoSquare;
  final String favicon;
  final HomeColors colors;
  final HomeTypography typography;
  final HomeLayout layout;

  const HomeTheme({
    required this.logo,
    required this.logoSquare,
    required this.favicon,
    required this.colors,
    required this.typography,
    required this.layout,
  });

  factory HomeTheme.fromJson(Map<String, dynamic> json) => HomeTheme(
        logo: HomeLogo.fromJson(_asMap(json['logo'])),
        logoSquare: HomeLogo.fromJson(_asMap(json['logo_square'])),
        favicon: json['favicon'] as String? ?? '',
        colors: HomeColors.fromJson(_asMap(json['colors'])),
        typography: HomeTypography.fromJson(_asMap(json['typography'])),
        layout: HomeLayout.fromJson(_asMap(json['layout'])),
      );
}

class HomeLogo {
  final String url;
  final int width;
  final int height;

  const HomeLogo({required this.url, required this.width, required this.height});

  bool get hasUrl => url.isNotEmpty;

  factory HomeLogo.fromJson(Map<String, dynamic> json) => HomeLogo(
        url: json['url'] as String? ?? '',
        width: json['width'] as int? ?? 200,
        height: json['height'] as int? ?? 60,
      );
}

class HomeColors {
  final String primary;
  final String primaryDark;
  final String background;
  final String surface;
  final String card;
  final String textPrimary;
  final String textSecondary;
  final String textMuted;
  final String border;
  final String announcementBg;
  final String announcementText;
  final String buttonBg;
  final String buttonText;
  final String saleBadge;
  final String saleBadgeText;

  const HomeColors({
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.announcementBg,
    required this.announcementText,
    required this.buttonBg,
    required this.buttonText,
    required this.saleBadge,
    required this.saleBadgeText,
  });

  factory HomeColors.fromJson(Map<String, dynamic> json) => HomeColors(
        primary: json['primary'] as String? ?? '#C49A6C',
        primaryDark: json['primary_dark'] as String? ?? '#9E7A4A',
        background: json['background'] as String? ?? '#FFFFFF',
        surface: json['surface'] as String? ?? '#FBF8F3',
        card: json['card'] as String? ?? '#F7F4EF',
        textPrimary: json['text_primary'] as String? ?? '#1C1C1C',
        textSecondary: json['text_secondary'] as String? ?? '#6B6B6B',
        textMuted: json['text_muted'] as String? ?? '#9E9E9E',
        border: json['border'] as String? ?? '#E8E0D6',
        announcementBg: json['announcement_bg'] as String? ?? '#1C1C1C',
        announcementText: json['announcement_text'] as String? ?? '#FFFFFF',
        buttonBg: json['button_bg'] as String? ?? '#1C1C1C',
        buttonText: json['button_text'] as String? ?? '#FFFFFF',
        saleBadge: json['sale_badge'] as String? ?? '#E53935',
        saleBadgeText: json['sale_badge_text'] as String? ?? '#FFFFFF',
      );
}

class HomeTypography {
  final String fontHeading;
  final String fontBody;
  final String fontHeadingWeight;
  final String fontBodyWeight;
  final double letterSpacingHeading;
  final double letterSpacingBody;

  const HomeTypography({
    required this.fontHeading,
    required this.fontBody,
    required this.fontHeadingWeight,
    required this.fontBodyWeight,
    required this.letterSpacingHeading,
    required this.letterSpacingBody,
  });

  factory HomeTypography.fromJson(Map<String, dynamic> json) => HomeTypography(
        fontHeading:
            json['font_heading'] as String? ?? 'Cormorant Garamond',
        fontBody: json['font_body'] as String? ?? 'Jost',
        fontHeadingWeight: json['font_heading_weight'] as String? ?? '500',
        fontBodyWeight: json['font_body_weight'] as String? ?? '400',
        letterSpacingHeading:
            (json['letter_spacing_heading'] as num?)?.toDouble() ?? 0.5,
        letterSpacingBody:
            (json['letter_spacing_body'] as num?)?.toDouble() ?? 0.2,
      );
}

class HomeLayout {
  final double borderRadius;
  final double buttonBorderRadius;
  final double cardBorderRadius;
  final double horizontalPadding;
  final double sectionSpacing;
  final double cardSpacing;
  final String imageAspectRatio;

  const HomeLayout({
    required this.borderRadius,
    required this.buttonBorderRadius,
    required this.cardBorderRadius,
    required this.horizontalPadding,
    required this.sectionSpacing,
    required this.cardSpacing,
    required this.imageAspectRatio,
  });

  factory HomeLayout.fromJson(Map<String, dynamic> json) => HomeLayout(
        borderRadius: (json['border_radius'] as num?)?.toDouble() ?? 0,
        buttonBorderRadius:
            (json['button_border_radius'] as num?)?.toDouble() ?? 0,
        cardBorderRadius:
            (json['card_border_radius'] as num?)?.toDouble() ?? 0,
        horizontalPadding:
            (json['horizontal_padding'] as num?)?.toDouble() ?? 16,
        sectionSpacing: (json['section_spacing'] as num?)?.toDouble() ?? 40,
        cardSpacing: (json['card_spacing'] as num?)?.toDouble() ?? 12,
        imageAspectRatio: json['image_aspect_ratio'] as String? ?? '4:5',
      );
}

// ─── Global ───────────────────────────────────────────────────────────────────

class HomeGlobal {
  final String shopName;
  final String shopTagline;
  final String currencyCode;
  final String currencySymbol;
  final HomeContact contact;
  final HomeSocial social;
  final List<String> announcements;
  final HomeNavigation navigation;

  const HomeGlobal({
    required this.shopName,
    required this.shopTagline,
    required this.currencyCode,
    required this.currencySymbol,
    required this.contact,
    required this.social,
    required this.announcements,
    required this.navigation,
  });

  factory HomeGlobal.fromJson(Map<String, dynamic> json) => HomeGlobal(
        shopName: json['shop_name'] as String? ?? 'Earthly Jewels',
        shopTagline: json['shop_tagline'] as String? ?? '',
        currencyCode: json['currency_code'] as String? ?? 'INR',
        currencySymbol: json['currency_symbol'] as String? ?? '₹',
        contact: HomeContact.fromJson(_asMap(json['contact'])),
        social: HomeSocial.fromJson(_asMap(json['social'])),
        announcements: (json['announcements'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        navigation: HomeNavigation.fromJson(_asMap(json['navigation'])),
      );
}

class HomeContact {
  final String phone;
  final String email;
  final String whatsapp;
  final String address;

  const HomeContact({
    required this.phone,
    required this.email,
    required this.whatsapp,
    required this.address,
  });

  factory HomeContact.fromJson(Map<String, dynamic> json) => HomeContact(
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        whatsapp: json['whatsapp'] as String? ?? '',
        address: json['address'] as String? ?? '',
      );
}

class HomeSocial {
  final String instagram;
  final String youtube;
  final String pinterest;
  final String linkedin;

  const HomeSocial({
    required this.instagram,
    required this.youtube,
    required this.pinterest,
    required this.linkedin,
  });

  factory HomeSocial.fromJson(Map<String, dynamic> json) => HomeSocial(
        instagram: json['instagram'] as String? ?? '',
        youtube: json['youtube'] as String? ?? '',
        pinterest: json['pinterest'] as String? ?? '',
        linkedin: json['linkedin'] as String? ?? '',
      );
}

class HomeNavigation {
  final List<HomeNavItem> header;
  final List<HomeFooterGroup> footerLinks;

  const HomeNavigation({
    required this.header,
    required this.footerLinks,
  });

  factory HomeNavigation.fromJson(Map<String, dynamic> json) => HomeNavigation(
        header: (json['header'] as List? ?? [])
            .map((e) => HomeNavItem.fromJson(_asMap(e)))
            .toList(),
        footerLinks: (json['footer_links'] as List? ?? [])
            .map((e) => HomeFooterGroup.fromJson(_asMap(e)))
            .toList(),
      );
}

class HomeNavItem {
  final String label;
  final String url;

  const HomeNavItem({required this.label, required this.url});

  factory HomeNavItem.fromJson(Map<String, dynamic> json) => HomeNavItem(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

class HomeFooterGroup {
  final String heading;
  final List<HomeNavItem> links;

  const HomeFooterGroup({required this.heading, required this.links});

  factory HomeFooterGroup.fromJson(Map<String, dynamic> json) =>
      HomeFooterGroup(
        heading: json['heading'] as String? ?? '',
        links: (json['links'] as List? ?? [])
            .map((e) => HomeNavItem.fromJson(_asMap(e)))
            .toList(),
      );
}

// ─── Sections ─────────────────────────────────────────────────────────────────

class HomeSection {
  final String id;
  final String type;
  final bool visible;
  final int order;
  final Map<String, dynamic> data;

  const HomeSection({
    required this.id,
    required this.type,
    required this.visible,
    required this.order,
    required this.data,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) => HomeSection(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? '',
        visible: json['visible'] as bool? ?? true,
        order: json['order'] as int? ?? 99,
        data: _asMap(json['data']),
      );

  HeroBannerData get heroBannerData => HeroBannerData.fromJson(data);
  ProductGridData get productGridData => ProductGridData.fromJson(data);
  ImageTextData get imageTextData => ImageTextData.fromJson(data);
  CollectionRowData get collectionRowData => CollectionRowData.fromJson(data);
  BrandValuesData get brandValuesData => BrandValuesData.fromJson(data);
  ReviewsCarouselData get reviewsCarouselData => ReviewsCarouselData.fromJson(data);
  FaqData get faqData => FaqData.fromJson(data);
  OccasionsData get occasionsData => OccasionsData.fromJson(data);
  FullWidthCtaData get fullWidthCtaData => FullWidthCtaData.fromJson(data);
  ProductGridData get orioleExclusiveData => ProductGridData.fromJson(data);
}

// ─── Section data: hero_banner ────────────────────────────────────────────────

class HeroBannerData {
  final List<HeroBannerSlide> slides;

  const HeroBannerData({required this.slides});

  factory HeroBannerData.fromJson(Map<String, dynamic> json) {
    final list = json['slides'] as List? ?? [];
    return HeroBannerData(
      slides: list
          .map((e) => HeroBannerSlide.fromJson(_asMap(e)))
          .where((s) => s.image.isNotEmpty)
          .toList(),
    );
  }
}

class HeroBannerSlide {
  final String image;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String ctaUrl;
  final String textColor;
  final double overlay;

  const HeroBannerSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.textColor,
    required this.overlay,
  });

  factory HeroBannerSlide.fromJson(Map<String, dynamic> json) =>
      HeroBannerSlide(
        image: json['image'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        ctaLabel: json['cta_label'] as String? ?? '',
        ctaUrl: json['cta_url'] as String? ?? '/collections/all',
        textColor: json['text_color'] as String? ?? '#FFFFFF',
        overlay: (json['overlay'] as num?)?.toDouble() ?? 0.3,
      );
}

// ─── Section data: product_grid / product_carousel ───────────────────────────

class ProductGridData {
  final String title;
  final String? badge;
  final String ctaLabel;
  final String ctaUrl;
  final int columns;
  final List<HomeProduct> products;

  const ProductGridData({
    required this.title,
    this.badge,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.columns,
    required this.products,
  });

  factory ProductGridData.fromJson(Map<String, dynamic> json) {
    final list = json['products'] as List? ?? [];
    return ProductGridData(
      title: json['title'] as String? ?? '',
      badge: json['badge'] as String?,
      ctaLabel: json['cta_label'] as String? ?? 'View all',
      ctaUrl: json['cta_url'] as String? ?? '/collections/all',
      columns: json['columns'] as int? ?? 2,
      products: list
          .map((e) => HomeProduct.fromJson(_asMap(e)))
          .toList(),
    );
  }
}

// ─── Section data: image_text ─────────────────────────────────────────────────

class ImageTextData {
  final String image;
  final String imageSide;
  final String title;
  final String body;
  final String ctaLabel;
  final String ctaUrl;
  final String secondaryCtaLabel;
  final String secondaryCtaUrl;

  const ImageTextData({
    required this.image,
    required this.imageSide,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.secondaryCtaLabel,
    required this.secondaryCtaUrl,
  });

  bool get hasContent =>
      image.isNotEmpty || title.isNotEmpty || body.isNotEmpty;

  factory ImageTextData.fromJson(Map<String, dynamic> json) => ImageTextData(
        image: json['image'] as String? ?? '',
        imageSide: json['image_side'] as String? ?? 'left',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        ctaLabel: json['cta_label'] as String? ?? 'Shop now',
        ctaUrl: json['cta_url'] as String? ?? '/collections/all',
        secondaryCtaLabel: json['secondary_cta_label'] as String? ?? '',
        secondaryCtaUrl: json['secondary_cta_url'] as String? ?? '',
      );
}

// ─── Home product ─────────────────────────────────────────────────────────────

class HomeProductImage {
  final String url;
  final String alt;

  const HomeProductImage({required this.url, required this.alt});
}

class HomeProduct {
  final String id;
  final String handle;
  final String title;
  final String vendor;
  final bool available;
  final String price;
  final String? compareAtPrice;
  final String currency;
  final String? badge;
  final List<HomeProductImage> images;
  final String url;

  const HomeProduct({
    required this.id,
    required this.handle,
    required this.title,
    required this.vendor,
    required this.available,
    required this.price,
    this.compareAtPrice,
    required this.currency,
    this.badge,
    required this.images,
    required this.url,
  });

  String get formattedPrice {
    final amount = double.tryParse(price) ?? 0;
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
    return '₹$formatted';
  }

  Product toProduct() {
    return Product(
      id: id,
      handle: handle,
      title: title,
      vendor: vendor,
      availableForSale: available,
      images: images
          .map((img) => ProductImage(url: img.url, altText: img.alt))
          .toList(),
      variants: [
        ProductVariant(
          id: 'v_$handle',
          title: 'Default Title',
          price: price,
          compareAtPrice: compareAtPrice,
          availableForSale: available,
          selectedOptions: {},
        ),
      ],
      tags: badge != null ? [badge!.toLowerCase()] : [],
    );
  }

  factory HomeProduct.fromJson(Map<String, dynamic> json) {
    // Normalize price: accept "45149", "₹45,149", or numeric
    String priceStr = '0';
    if (json['price_amount'] != null) {
      priceStr = (json['price_amount'] as num).toStringAsFixed(0);
    } else if (json['price'] != null) {
      priceStr = json['price']
          .toString()
          .replaceAll(RegExp(r'[₹,\s]'), '')
          .split('.')
          .first;
    }

    String? compareStr;
    if (json['compare_at_price_amount'] != null) {
      final amt = (json['compare_at_price_amount'] as num?)?.toDouble() ?? 0;
      if (amt > 0) compareStr = amt.toStringAsFixed(0);
    } else if (json['compare_at_price'] != null) {
      final raw = json['compare_at_price']
          .toString()
          .replaceAll(RegExp(r'[₹,\s]'), '')
          .split('.')
          .first;
      if (raw.isNotEmpty && raw != '0' && raw != 'null') compareStr = raw;
    }

    final imgs = <HomeProductImage>[];
    for (final img in (json['images'] as List? ?? [])) {
      final m = img as Map<String, dynamic>;
      final imgUrl = m['url'] as String? ?? '';
      if (imgUrl.isNotEmpty) {
        imgs.add(HomeProductImage(
          url: imgUrl,
          alt: m['alt'] as String? ?? m['alt_text'] as String? ?? '',
        ));
      }
    }
    if (imgs.isEmpty && json['featured_image'] is String) {
      imgs.add(HomeProductImage(
          url: json['featured_image'] as String, alt: ''));
    }

    return HomeProduct(
      id: json['id'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      title: json['title'] as String? ?? '',
      vendor: json['vendor'] as String? ?? '',
      available: json['available'] as bool? ??
          json['available_for_sale'] as bool? ??
          true,
      price: priceStr,
      compareAtPrice: compareStr,
      currency: json['currency'] as String? ?? 'INR',
      badge: json['badge'] as String?,
      images: imgs,
      url: json['url'] as String? ?? '/products/${json['handle']}',
    );
  }
}

// ─── Section data: collection_row / designer_rings ────────────────────────────

class CollectionTile {
  final String handle;
  final String title;
  final String imageUrl;
  final String description;

  const CollectionTile({
    required this.handle,
    required this.title,
    required this.imageUrl,
    this.description = '',
  });
}

class CollectionRowData {
  final String title;
  final String ctaLabel;
  final String ctaUrl;
  final List<CollectionTile> tiles;

  const CollectionRowData({
    required this.title,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.tiles,
  });

  bool get hasContent => tiles.isNotEmpty;

  factory CollectionRowData.fromJson(Map<String, dynamic> json) {
    final list = json['tiles'] as List? ?? [];
    return CollectionRowData(
      title: json['title'] as String? ?? '',
      ctaLabel: json['cta_label'] as String? ?? 'View All',
      ctaUrl: json['cta_url'] as String? ?? '/collections/all',
      tiles: list
          .map((e) {
            final m = _asMap(e);
            return CollectionTile(
              handle: m['handle'] as String? ?? '',
              title: m['title'] as String? ?? '',
              imageUrl: m['image_url'] as String? ?? '',
              description: m['description'] as String? ?? '',
            );
          })
          .where((t) => t.imageUrl.isNotEmpty)
          .toList(),
    );
  }
}

// ─── Section data: brand_values ───────────────────────────────────────────────

class BrandValueItem {
  final String icon;
  final String title;
  final String body;

  const BrandValueItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class BrandValuesData {
  final String title;
  final List<BrandValueItem> values;

  const BrandValuesData({required this.title, required this.values});

  bool get hasContent => values.isNotEmpty;

  factory BrandValuesData.fromJson(Map<String, dynamic> json) {
    final list = json['values'] as List? ?? [];
    return BrandValuesData(
      title: json['title'] as String? ?? '',
      values: list
          .map((e) {
            final m = _asMap(e);
            return BrandValueItem(
              icon: m['icon'] as String? ?? '',
              title: m['title'] as String? ?? '',
              body: m['body'] as String? ?? '',
            );
          })
          .where((v) => v.title.isNotEmpty)
          .toList(),
    );
  }
}

// ─── Section data: reviews_carousel ──────────────────────────────────────────

class ReviewCard {
  final double rating;
  final String title;
  final String body;
  final String author;
  final String productName;
  final String avatarUrl;

  const ReviewCard({
    required this.rating,
    required this.title,
    required this.body,
    required this.author,
    this.productName = '',
    this.avatarUrl = '',
  });
}

class ReviewsCarouselData {
  final String sectionTitle;
  final List<ReviewCard> reviews;

  const ReviewsCarouselData({
    required this.sectionTitle,
    required this.reviews,
  });

  bool get hasContent => reviews.isNotEmpty;

  factory ReviewsCarouselData.fromJson(Map<String, dynamic> json) {
    final list = json['reviews'] as List? ?? [];
    return ReviewsCarouselData(
      sectionTitle:
          json['section_title'] as String? ?? 'What Our Customers Say',
      reviews: list
          .map((e) {
            final m = _asMap(e);
            return ReviewCard(
              rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
              title: m['title'] as String? ?? '',
              body: m['body'] as String? ?? '',
              author: m['author'] as String? ?? '',
              productName: m['product_name'] as String? ?? '',
              avatarUrl: m['avatar_url'] as String? ?? '',
            );
          })
          .where((r) => r.body.isNotEmpty || r.title.isNotEmpty)
          .toList(),
    );
  }
}

// ─── Section data: faq_accordion ─────────────────────────────────────────────

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class FaqData {
  final String title;
  final List<FaqItem> items;

  const FaqData({required this.title, required this.items});

  bool get hasContent => items.isNotEmpty;

  factory FaqData.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return FaqData(
      title: json['title'] as String? ?? 'Frequently Asked Questions',
      items: list
          .map((e) {
            final m = _asMap(e);
            return FaqItem(
              question: m['question'] as String? ?? '',
              answer: m['answer'] as String? ?? '',
            );
          })
          .where((f) => f.question.isNotEmpty)
          .toList(),
    );
  }
}

// ─── Section data: occasions ──────────────────────────────────────────────────

class OccasionTab {
  final String title;
  final String imageUrl;
  final String handle;
  final List<HomeProduct> products;

  const OccasionTab({
    required this.title,
    required this.imageUrl,
    required this.handle,
    required this.products,
  });
}

class OccasionsData {
  final String title;
  final String ctaLabel;
  final String ctaUrl;
  final List<OccasionTab> tabs;

  const OccasionsData({
    required this.title,
    this.ctaLabel = '',
    this.ctaUrl = '',
    required this.tabs,
  });

  bool get hasContent => tabs.isNotEmpty;

  factory OccasionsData.fromJson(Map<String, dynamic> json) {
    final list = json['tabs'] as List? ?? [];
    return OccasionsData(
      title: json['title'] as String? ?? 'Perfect Sparkle for Every Occasion',
      ctaLabel: json['cta_label'] as String? ?? '',
      ctaUrl: json['cta_url'] as String? ?? '/collections/all',
      tabs: list
          .map((e) {
            final m = _asMap(e);
            final productList = m['products'] as List? ?? [];
            return OccasionTab(
              title: m['title'] as String? ?? '',
              imageUrl: m['image_url'] as String? ?? '',
              handle: m['handle'] as String? ?? '',
              products: productList
                  .map((p) => HomeProduct.fromJson(_asMap(p)))
                  .toList(),
            );
          })
          .where((t) => t.title.isNotEmpty)
          .toList(),
    );
  }
}

// ─── Section data: full_width_cta ────────────────────────────────────────────

class FullWidthCtaData {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String ctaUrl;

  const FullWidthCtaData({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaUrl,
  });

  bool get hasContent => title.isNotEmpty;

  factory FullWidthCtaData.fromJson(Map<String, dynamic> json) =>
      FullWidthCtaData(
        imageUrl: json['image_url'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        ctaLabel: json['cta_label'] as String? ?? 'Shop Now',
        ctaUrl: json['cta_url'] as String? ?? '/collections/all',
      );
}
