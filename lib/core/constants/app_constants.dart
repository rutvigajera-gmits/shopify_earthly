class AppConstants {
  AppConstants._();

  // ── Shopify Storefront API ──────────────────────────────────────────────────
  static const String shopDomain = 'earthlyjewels.co';
  static const String storefrontApiVersion = '2026-07';
  static const String storefrontApiUrl =
      'https://$shopDomain/api/$storefrontApiVersion/graphql.json';
  static const String storefrontAccessToken = 'f0a6b56aed212f4ea6a306e9909e3fac';

  static const double horizontalPadding = 16.0;
  static const double sectionSpacing = 40.0;
  static const double cardSpacing = 12.0;
  static const double borderRadius = 4.0;

  // ── Hero banner slides — 5 collections with high-quality images ───────────
  static const List<String> bannerCollectionHandles = [
    'lab-grown-diamond-rings',
    'lab-grown-diamond-earrings',
    'lab-grown-diamond-necklace',
    'lab-grown-diamond-bracelets',
    'lab-grown-diamond-engagement-rings',
  ];

  // ── "Shop by Category" — 5 tiles matching the website ────────────────────
  static const List<String> categoryCollectionHandles = [
    'lab-grown-diamond-rings',
    'lab-grown-diamond-earrings',
    'lab-grown-diamond-necklace',
    'lab-grown-diamond-bracelets',
    'mens-ring',
  ];

  // ── "Perfect Sparkle for Every Occasion" — 4 tabs matching the website ───
  static const List<String> occasionHandles = [
    'lab-grown-diamond-engagement-rings',
    'eternity-rings',
    'dailywear',
    'gifts-for-her',
  ];

  // ── "Designer Rings Collection" — 8 cards matching the website ────────────
  static const List<String> designerRingHandles = [
    'lab-grown-diamond-rings',
    'twine',
    'fluid',
    'envy',
    'aura',
    'flora',
    'grace',
    'bezel',
  ];
}
