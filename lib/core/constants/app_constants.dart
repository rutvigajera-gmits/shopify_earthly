class AppConstants {
  AppConstants._();

  // ── Layout ────────────────────────────────────────────────────────────────────
  static const double horizontalPadding = 16.0;
  static const double sectionSpacing = 40.0;
  static const double cardSpacing = 12.0;
  static const double borderRadius = 4.0;

  // ── Collection handles ────────────────────────────────────────────────────────
  static const List<String> bannerCollectionHandles = [
    'lab-grown-diamond-rings',
    'lab-grown-diamond-earrings',
    'lab-grown-diamond-necklace',
    'lab-grown-diamond-bracelets',
    'lab-grown-diamond-engagement-rings',
  ];

  static const List<String> categoryCollectionHandles = [
    'lab-grown-diamond-rings',
    'lab-grown-diamond-earrings',
    'lab-grown-diamond-necklace',
    'lab-grown-diamond-bracelets',
    'mens-ring',
  ];

  static const List<String> occasionHandles = [
    'lab-grown-diamond-engagement-rings',
    'eternity-rings',
    'dailywear',
    'gifts-for-her',
  ];

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

enum GalleryFileTypes { CANCEL, CAMERA, GALLERY }
