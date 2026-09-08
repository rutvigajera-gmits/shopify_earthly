class ShopBrand {
  final String storeName;
  final String? logoUrl;
  final String? squareLogoUrl;
  final String? slogan;
  final String? description;
  final String? coverImageUrl;

  const ShopBrand({
    required this.storeName,
    this.logoUrl,
    this.squareLogoUrl,
    this.slogan,
    this.description,
    this.coverImageUrl,
  });

  factory ShopBrand.fromStorefrontJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>? ?? {};
    final brand = shop['brand'] as Map<String, dynamic>?;

    String? logoUrl;
    String? squareLogoUrl;
    String? coverUrl;

    if (brand != null) {
      final logo = brand['logo'] as Map<String, dynamic>?;
      logoUrl = (logo?['image'] as Map?)?['url'] as String?;

      final sq = brand['squareLogo'] as Map<String, dynamic>?;
      squareLogoUrl = (sq?['image'] as Map?)?['url'] as String?;

      final cover = brand['coverImage'] as Map<String, dynamic>?;
      coverUrl = (cover?['image'] as Map?)?['url'] as String?;
    }

    return ShopBrand(
      storeName: shop['name'] as String? ?? '',
      logoUrl: logoUrl,
      squareLogoUrl: squareLogoUrl,
      slogan: brand?['slogan'] as String?,
      description: brand?['shortDescription'] as String? ??
          shop['description'] as String?,
      coverImageUrl: coverUrl,
    );
  }

  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
}

class ShopBanner {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String ctaText;

  const ShopBanner({
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.ctaText = '',
  });

  factory ShopBanner.fromCollection({
    required String imageUrl,
    required String title,
    String? subtitle,
  }) {
    return ShopBanner(imageUrl: imageUrl, title: title, subtitle: subtitle);
  }

  factory ShopBanner.fromMetaobject(Map<String, dynamic> fields) {
    String imageUrl = '';
    String title = '';
    String? subtitle;
    String cta = '';

    for (final entry in fields.entries) {
      switch (entry.key) {
        case 'image':
        case 'banner_image':
        case 'background_image':
        case 'photo':
          final ref = entry.value['reference'] as Map<String, dynamic>?;
          final img = ref?['image'] as Map<String, dynamic>?;
          imageUrl = img?['url'] as String? ?? '';
        case 'title':
        case 'heading':
          title = entry.value['value'] as String? ?? '';
        case 'subtitle':
        case 'subheading':
        case 'description':
          subtitle = entry.value['value'] as String?;
        case 'cta':
        case 'button_label':
        case 'cta_text':
        case 'button_text':
          cta = entry.value['value'] as String? ?? '';
      }
    }

    return ShopBanner(
      imageUrl: imageUrl,
      title: title,
      subtitle: subtitle,
      ctaText: cta,
    );
  }
}

class BrandValue {
  final String icon;
  final String title;
  final String body;

  const BrandValue({
    required this.icon,
    required this.title,
    required this.body,
  });

  bool get isValid => title.isNotEmpty && body.isNotEmpty;

  factory BrandValue.fromMetaobject(Map<String, dynamic> fields) {
    String icon = '';
    String title = '';
    String body = '';

    for (final entry in fields.entries) {
      final value = entry.value['value'] as String? ?? '';
      switch (entry.key) {
        case 'icon':
        case 'emoji':
        case 'symbol':
          icon = value;
        case 'title':
        case 'heading':
        case 'name':
          title = value;
        case 'body':
        case 'description':
        case 'content':
        case 'text':
          body = value;
      }
    }

    return BrandValue(icon: icon, title: title, body: body);
  }
}

class MenuItem {
  final String title;
  final String url;
  final String handle;

  const MenuItem({
    required this.title,
    required this.url,
    required this.handle,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String? ?? '';
    final parts = url.split('/');
    final handle = parts.isNotEmpty ? parts.last : '';
    return MenuItem(
      title: json['title'] as String? ?? '',
      url: url,
      handle: handle,
    );
  }
}
