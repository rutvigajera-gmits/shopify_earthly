import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/shop_provider.dart';
import '../../../data/providers/review_provider.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/models/review_model.dart';
import '../../widgets/announcement_bar.dart';
import '../../widgets/app_header.dart';
import '../../widgets/product_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final ValueChanged<int>? onNavTap;

  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onCartTap,
    this.onNavTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>()
        ..loadFeaturedProducts()
        ..loadCollections();
      context.read<ShopProvider>().initialize();
      context.read<ReviewProvider>().loadStoreReviews();
    });
  }

  String _title(ShopProvider shop, String key, String fallback) {
    final t = shop.sectionTitle(key);
    return t.isNotEmpty ? t : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const AnnouncementBar(),
                AppHeader(
                  onSearchTap: widget.onSearchTap,
                  onCartTap: widget.onCartTap,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero Banner Carousel ───────────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    if (shop.loading && shop.banners.isEmpty) {
                      return _BannerShimmer();
                    }
                    if (shop.banners.isEmpty) return const SizedBox.shrink();
                    return _HeroBanner(
                      banners: shop.banners,
                      index: _bannerIndex,
                      onPageChanged: (i) =>
                          setState(() => _bannerIndex = i),
                    );
                  },
                ),

                // ── 2. Why Earthly (brand values) ─────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    if (shop.brandValues.isEmpty) return const SizedBox.shrink();
                    return _WhyEarthlySection(
                      values: shop.brandValues,
                      title: _title(shop, 'why_earthly', 'Why EARTHLY Exists'),
                      subtitle: shop.sectionTitle('why_earthly_sub'),
                    );
                  },
                ),

                // ── 3. Customer Reviews ───────────────────────────────────
                Consumer2<ShopProvider, ReviewProvider>(
                  builder: (_, shop, rp, __) {
                    final reviews = shop.homeReviews.isNotEmpty
                        ? shop.homeReviews
                        : rp.storeReviews;
                    if (reviews.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: Consumer<ShopProvider>(
                        builder: (_, s, __) => _ReviewsSection(
                          reviews: reviews,
                          title: _title(s, 'reviews', 'What Our Customers Say'),
                        ),
                      ),
                    );
                  },
                ),

                // ── 4. Most Loved Pieces (best-selling products grid) ─────
                Consumer<ProductProvider>(
                  builder: (_, provider, __) {
                    if (provider.loadingFeatured) {
                      return Padding(
                        padding: const EdgeInsets.only(
                            top: AppConstants.sectionSpacing),
                        child: Consumer<ShopProvider>(
                          builder: (_, s, __) => _ProductGridShimmer(
                            title: _title(
                                s, 'featured_products', 'Most Loved Pieces'),
                          ),
                        ),
                      );
                    }
                    if (provider.featuredProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: Consumer<ShopProvider>(
                        builder: (_, shop, __) => _FeaturedProductsSection(
                          products: provider.featuredProducts,
                          title: _title(
                              shop, 'featured_products', 'Most Loved Pieces'),
                          onViewAll: () => widget.onNavTap?.call(1),
                          onProductTap: (p) => Navigator.of(context)
                              .pushNamed('/product', arguments: p.handle),
                        ),
                      ),
                    );
                  },
                ),

                // ── 5. Shop by Category (5 specific collections) ──────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    final cols = shop.categoryCollections
                        .where((c) => c.image != null)
                        .toList();
                    if (cols.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _CategoryGridSection(
                        collections: cols,
                        title: _title(shop, 'categories', 'Shop by Category'),
                        onTap: () => widget.onNavTap?.call(1),
                      ),
                    );
                  },
                ),

                // ── 6. Perfect Sparkle for Every Occasion ─────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    final occ = shop.occasionCollections
                        .where((c) => c.image != null)
                        .toList();
                    if (occ.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _OccasionSection(
                        collections: occ,
                        title: _title(shop, 'occasions',
                            'Perfect Sparkle for Every Occasion'),
                        onTap: () => widget.onNavTap?.call(1),
                      ),
                    );
                  },
                ),

                // ── 7. Designer Rings Collection ──────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    final cols = shop.designerCollections
                        .where((c) => c.image != null)
                        .toList();
                    if (cols.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _DesignerCollectionSection(
                        collections: cols,
                        onTap: () => widget.onNavTap?.call(1),
                      ),
                    );
                  },
                ),

                // ── 8. Feature / Second Banner ────────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    if (shop.featureBanner == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _FeatureBannerSection(banner: shop.featureBanner!),
                    );
                  },
                ),

                // ── 9. CTA ────────────────────────────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    if (shop.ctaBanner == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _CtaSection(banner: shop.ctaBanner!),
                    );
                  },
                ),

                // ── 10. Footer ────────────────────────────────────────────
                Consumer<ShopProvider>(
                  builder: (_, shop, __) {
                    if (shop.brand == null && !shop.initialized) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(
                          top: AppConstants.sectionSpacing),
                      child: _FooterInfo(
                        brand: shop.brand,
                        navItems: shop.navItems,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Banner Carousel ─────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  final List<ShopBanner> banners;
  final int index;
  final ValueChanged<int> onPageChanged;

  const _HeroBanner({
    required this.banners,
    required this.index,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 480,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (i, _) => onPageChanged(i),
          ),
          items: banners.asMap().entries.map((entry) {
            return _BannerSlide(
              banner: entry.value,
              // Overlay headline only on the first slide to match website
              overrideTitle: entry.key == 0 && entry.value.title.isEmpty
                  ? 'Bespoke Diamond Jewelry, Designed Around You'
                  : null,
              overrideCta:
                  entry.key == 0 && entry.value.ctaText.isEmpty ? 'Shop Now' : null,
            );
          }).toList(),
        ),
        if (banners.length > 1)
          Positioned(
            bottom: 16,
            child: AnimatedSmoothIndicator(
              activeIndex: index,
              count: banners.length,
              effect: const ExpandingDotsEffect(
                dotWidth: 6,
                dotHeight: 6,
                activeDotColor: Colors.white,
                dotColor: Colors.white54,
                expansionFactor: 3,
              ),
            ),
          ),
      ],
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final ShopBanner banner;
  final String? overrideTitle;
  final String? overrideCta;

  const _BannerSlide({
    required this.banner,
    this.overrideTitle,
    this.overrideCta,
  });

  @override
  Widget build(BuildContext context) {
    final title = overrideTitle ?? (banner.title.isNotEmpty ? banner.title : '');
    final cta = overrideCta ?? (banner.ctaText.isNotEmpty ? banner.ctaText : '');

    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: banner.imageUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.cardBackground),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xCC000000)],
              stops: [0.4, 1.0],
            ),
          ),
        ),
        if (title.isNotEmpty || cta.isNotEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      shadows: const [
                        Shadow(
                          color: Color(0x80000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                if (banner.subtitle != null &&
                    banner.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    banner.subtitle!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x60000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ],
                if (cta.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _OutlineButton(label: cta),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  const _OutlineButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      decoration: BoxDecoration(border: Border.all(color: Colors.white)),
      child: Text(
        label,
        style: AppTextStyles.button
            .copyWith(color: Colors.white, letterSpacing: 2),
      ),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(height: 480, color: Colors.white),
    );
  }
}

// ─── Feature / Second Banner ──────────────────────────────────────────────────

class _FeatureBannerSection extends StatelessWidget {
  final ShopBanner banner;
  const _FeatureBannerSection({required this.banner});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.cardBackground),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xAA000000)],
                stops: [0.35, 1.0],
              ),
            ),
          ),
          if (banner.title.isNotEmpty || banner.ctaText.isNotEmpty)
            Positioned(
              left: AppConstants.horizontalPadding,
              right: AppConstants.horizontalPadding,
              bottom: 32,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (banner.title.isNotEmpty)
                    Text(
                      banner.title,
                      style: AppTextStyles.displayMedium
                          .copyWith(color: Colors.white, height: 1.2),
                    ),
                  if (banner.subtitle != null &&
                      banner.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      banner.subtitle!,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                  if (banner.ctaText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _OutlineButton(label: banner.ctaText),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Why Earthly (horizontal cards) ──────────────────────────────────────────

class _WhyEarthlySection extends StatelessWidget {
  final List<BrandValue> values;
  final String title;
  final String subtitle;

  const _WhyEarthlySection({
    required this.values,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          vertical: AppConstants.horizontalPadding * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              child: Text(
                title,
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (subtitle.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              child: Text(
                subtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ] else
            const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              itemCount: values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _WhyEarthlyCard(value: values[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhyEarthlyCard extends StatelessWidget {
  final BrandValue value;
  const _WhyEarthlyCard({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.icon.isNotEmpty) ...[
            Text(value.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 10),
          ],
          Text(
            value.title,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value.body,
            style: AppTextStyles.bodySmall.copyWith(
              height: 1.4,
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Reviews ──────────────────────────────────────────────────────────────────

class _ReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final String title;

  const _ReviewsSection({required this.reviews, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(title: title),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StarRow(rating: review.rating),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (review.title != null && review.title!.isNotEmpty)
                  Text(review.title!,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    '"${review.body}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (review.reviewerName.isNotEmpty)
                Text(review.reviewerName, style: AppTextStyles.labelLarge),
              if (review.formattedDate.isNotEmpty)
                Text(review.formattedDate, style: AppTextStyles.bodySmall),
            ],
          ),
          if (review.productTitle != null && review.productTitle!.isNotEmpty)
            Text(
              review.productTitle!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.gold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          5,
          (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 14,
                color: AppColors.gold,
              )),
    );
  }
}

// ─── Featured Products ────────────────────────────────────────────────────────

class _FeaturedProductsSection extends StatelessWidget {
  final List<Product> products;
  final String title;
  final VoidCallback onViewAll;
  final ValueChanged<Product> onProductTap;

  const _FeaturedProductsSection({
    required this.products,
    required this.title,
    required this.onViewAll,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final display = products.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: title,
              actionLabel: 'View All Trending Designs',
              onActionTap: onViewAll,
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.cardSpacing,
              mainAxisSpacing: AppConstants.cardSpacing,
              childAspectRatio: 0.62,
            ),
            itemCount: display.length,
            itemBuilder: (_, i) => ProductCard(
              product: display[i],
              onTap: () => onProductTap(display[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductGridShimmer extends StatelessWidget {
  final String title;
  const _ProductGridShimmer({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(title: title),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.cardSpacing,
              mainAxisSpacing: AppConstants.cardSpacing,
              childAspectRatio: 0.62,
            ),
            itemCount: 4,
            itemBuilder: (_, __) => const ProductCardSkeleton(),
          ),
        ),
      ],
    );
  }
}

// ─── Shop by Category (5 specific collections) ───────────────────────────────

class _CategoryGridSection extends StatelessWidget {
  final List<Collection> collections;
  final String title;
  final VoidCallback onTap;

  const _CategoryGridSection({
    required this.collections,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show up to 6 in a 2-column grid (website shows 5)
    final display = collections.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: title,
              actionLabel: 'All Collections',
              onActionTap: onTap,
            ),
          ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: display.length,
            itemBuilder: (_, i) => _CategoryTile(
              collection: display[i],
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;

  const _CategoryTile({required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: collection.image!.url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.cardBackground),
          ),
          Container(color: Colors.black.withValues(alpha: 0.15)),
          Positioned(
            left: 14,
            bottom: 14,
            child: Text(
              collection.title,
              style: AppTextStyles.headlineSmall.copyWith(
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Occasions ────────────────────────────────────────────────────────────────

class _OccasionSection extends StatelessWidget {
  final List<Collection> collections;
  final String title;
  final VoidCallback onTap;

  const _OccasionSection({
    required this.collections,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: title,
              actionLabel: 'View all',
              onActionTap: onTap,
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _OccasionTile(
              collection: collections[i],
              onTap: onTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _OccasionTile extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const _OccasionTile({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: collection.image!.url,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.cardBackground),
            ),
            Container(color: Colors.black.withValues(alpha: 0.2)),
            Center(
              child: Text(
                collection.title,
                style: AppTextStyles.headlineSmall
                    .copyWith(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Designer Rings Collection ────────────────────────────────────────────────

class _DesignerCollectionSection extends StatelessWidget {
  final List<Collection> collections;
  final VoidCallback onTap;

  const _DesignerCollectionSection({
    required this.collections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: SectionHeader(
            title: 'Designer Rings Collection',
            actionLabel: 'View All',
            onActionTap: onTap,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: collections.length,
            itemBuilder: (_, i) =>
                _DesignerTile(collection: collections[i], onTap: onTap),
          ),
        ),
      ],
    );
  }
}

class _DesignerTile extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const _DesignerTile({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: collection.image!.url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.cardBackground),
          ),
          Container(color: Colors.black.withValues(alpha: 0.30)),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  collection.title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4)
                    ],
                  ),
                ),
                if (collection.description != null &&
                    collection.description!.isNotEmpty)
                  Text(
                    collection.description!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTA Section ─────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  final ShopBanner banner;
  const _CtaSection({required this.banner});

  @override
  Widget build(BuildContext context) {
    if (banner.imageUrl.isNotEmpty) {
      return SizedBox(
        height: 280,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.textPrimary),
            ),
            Container(color: Colors.black.withValues(alpha: 0.45)),
            _CtaContent(banner: banner, textColor: Colors.white),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      padding: const EdgeInsets.all(32),
      color: AppColors.textPrimary,
      child: _CtaContent(banner: banner, textColor: AppColors.textWhite),
    );
  }
}

class _CtaContent extends StatelessWidget {
  final ShopBanner banner;
  final Color textColor;

  const _CtaContent({required this.banner, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (banner.title.isNotEmpty)
            Text(
              banner.title,
              style: AppTextStyles.headlineLarge.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              banner.subtitle!,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: textColor.withValues(alpha: 0.75)),
              textAlign: TextAlign.center,
            ),
          ],
          if (banner.ctaText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 13),
              decoration: BoxDecoration(border: Border.all(color: textColor)),
              child: Text(
                banner.ctaText,
                style: AppTextStyles.button.copyWith(color: textColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _FooterInfo extends StatelessWidget {
  final ShopBrand? brand;
  final List<MenuItem> navItems;

  const _FooterInfo({required this.brand, required this.navItems});

  @override
  Widget build(BuildContext context) {
    final name = brand?.storeName.toUpperCase() ?? 'EARTHLY JEWELS';
    final desc = brand?.description ?? '';
    final slogan = brand?.slogan;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: AppTextStyles.labelLarge.copyWith(letterSpacing: 3)),
          const SizedBox(height: 8),
          if (slogan != null && slogan.isNotEmpty) ...[
            Text(slogan,
                style: AppTextStyles.bodySmall
                    .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
          ],
          if (desc.isNotEmpty) ...[
            Text(desc, style: AppTextStyles.bodySmall),
            const SizedBox(height: 16),
          ],
          // Store contact
          _FooterContact(
              icon: Icons.phone_outlined, text: '+91 93212 94329'),
          const SizedBox(height: 6),
          _FooterContact(
              icon: Icons.email_outlined, text: 'hello@earthlyjewels.co'),
          const SizedBox(height: 6),
          _FooterContact(
            icon: Icons.location_on_outlined,
            text:
                'Crystal Plaza, Opp Infinity Mall, New Link Road, Andheri West, Mumbai - 400053',
          ),
          if (navItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            ...navItems.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} ${brand?.storeName ?? 'Earthly Jewels'}. All rights reserved.',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _FooterContact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterContact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: AppTextStyles.bodySmall),
        ),
      ],
    );
  }
}
