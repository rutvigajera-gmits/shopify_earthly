import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/home_provider.dart';
import '../../../data/models/home_api_model.dart';
import '../../widgets/app_header.dart';
import '../../widgets/product_card.dart';
import 'sections/section_hero_banner.dart';
import 'sections/section_shop_by_category.dart';
import 'sections/section_product_grid.dart';
import 'sections/section_oriole_exclusive.dart';
import 'sections/section_product_carousel.dart';
import 'sections/section_occasions.dart';
import 'sections/section_shop_by_shape.dart';
import 'sections/section_designer_rings.dart';
import 'sections/section_collection_row.dart';
import 'sections/section_brand_values.dart';
import 'sections/section_reviews.dart';
import 'sections/section_cta.dart';
import 'sections/section_faq.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onWishlistTap;
  final ValueChanged<int>? onNavTap;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onCartTap,
    this.onWishlistTap,
    this.onNavTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<HomeProvider>().refresh(),
          color: AppColors.orange,
          backgroundColor: AppColors.background,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    AppHeader(
                      showSearchBar: true,
                      onSearchTap: widget.onSearchTap,
                      onCartTap: widget.onCartTap,
                      onWishlistTap: widget.onWishlistTap,
                    ),
                    const Divider(height: 1, color: AppColors.neutral200),
                  ],
                ),
              ),
              Consumer<HomeProvider>(
                builder: (context, home, _) {
                  if (home.loading) {
                    return SliverToBoxAdapter(child: _LoadingView());
                  }
                  if (home.error != null && home.sections.isEmpty) {
                    return SliverToBoxAdapter(child: _ErrorView(error: home.error!));
                  }

                  debugPrint('[Home] sections: ${home.sections.map((s) => s.type).toList()}');
                  final children = <Widget>[];
                  CollectionRowData? shapeApiData;
                  HomeSection? orioleSection;

                  for (final section in home.sections) {
                    if (section.type == 'shop_by_shape') {
                      shapeApiData = section.collectionRowData;
                      continue;
                    }
                    if (section.type == 'oriole_exclusive') {
                      orioleSection = section;
                      continue;
                    }
                    final w = _buildSection(section);
                    if (w != null) children.add(w);
                  }

                  children.add(Padding(
                    padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
                    child: ShopByShapeSection(
                      data: shapeApiData ??
                          const CollectionRowData(
                            title: 'Shop by Shape',
                            ctaLabel: '',
                            ctaUrl: '',
                            tiles: [],
                          ),
                      onViewAll: () => widget.onNavTap?.call(1),
                      onTap: (shapeName, handle) => Navigator.of(context).pushNamed(
                        '/shape-products',
                        arguments: {'shapeName': shapeName, 'handle': handle},
                      ),
                    ),
                  ));

                  if (orioleSection != null) {
                    final w = _buildSection(orioleSection);
                    if (w != null) children.add(w);
                  }

                  children.add(48.height);

                  return SliverList(
                    key: const ValueKey('home_sections'),
                    delegate: SliverChildListDelegate(children),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildSection(HomeSection section) {
    const vPad = AppConstants.sectionSpacing;
    switch (section.type) {
      case 'hero_banner':
        final data = section.heroBannerData;
        if (data.slides.isEmpty) return null;
        return HeroBannerSection(data: data);

      case 'shop_by_category':
        final data = section.collectionRowData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: ShopByCategorySection(
            data: data,
            onTap: (handle) =>
                Navigator.of(context).pushNamed('/products', arguments: handle),
          ),
        );

      case 'product_grid':
        final data = section.productGridData;
        if (data.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: ProductGridSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'oriole_exclusive':
        final data = section.orioleExclusiveData;
        if (data.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: OrioleExclusiveSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () {},
          ),
        );

      case 'product_carousel':
        final data = section.productGridData;
        if (data.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: ProductCarouselSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'occasions':
        final data = section.occasionsData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: OccasionsSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'designer_rings':
        final data = section.collectionRowData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: DesignerRingsSection(
            data: data,
            onViewAll: () => widget.onNavTap?.call(1),
            onTap: (handle) =>
                Navigator.of(context).pushNamed('/products', arguments: handle),
          ),
        );

      case 'collection_row':
        final data = section.collectionRowData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: CollectionRowSection(data: data, onViewAll: () {}),
        );

      case 'brand_values':
        final data = section.brandValuesData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: BrandValuesSection(data: data),
        );

      case 'reviews_carousel':
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: ReviewsCarouselSection(data: section.reviewsCarouselData),
        );

      case 'stackable_bands':
      case 'customize_cta':
      case 'full_width_cta':
        final data = section.fullWidthCtaData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: FullWidthCtaSection(data: data),
        );

      case 'virtual_call_cta':
        final data = section.fullWidthCtaData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: VirtualCallSection(data: data),
        );

      case 'faq_accordion':
        final data = section.faqData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: FaqAccordionSection(data: data),
        );

      case 'image_text':
        final data = section.imageTextData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: vPad),
          child: ImageTextSection(data: data),
        );

      default:
        return null;
    }
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: [
          Container(height: 420, color: Colors.white),
          32.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 18, width: 180, color: Colors.white),
                16.height,
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.cardSpacing,
                    mainAxisSpacing: AppConstants.cardSpacing,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, __) => const ProductCardSkeleton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          48.height,
          const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textMuted),
          16.height,
          Text('Could not load content', style: AppTextStyles.headlineSmall),
          8.height,
          Text(
            error,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          24.height,
          GestureDetector(
            onTap: () => context.read<HomeProvider>().initialize(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              color: AppColors.primary,
              child: Text('Retry',
                  style: AppTextStyles.button.copyWith(color: AppColors.textWhite)),
            ),
          ),
        ],
      ),
    );
  }
}
