import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/home_provider.dart';
import '../../../data/models/home_api_model.dart';
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
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeProvider>().refresh(),
        color: AppColors.gold,
        backgroundColor: AppColors.background,
        child: CustomScrollView(
          slivers: [
          // ── Fixed header ────────────────────────────────────────────────────
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

          // ── SDUI sections ────────────────────────────────────────────────
          Consumer<HomeProvider>(
            builder: (context, home, _) {
              if (home.loading) {
                return SliverToBoxAdapter(child: _LoadingView());
              }

              if (home.error != null && home.sections.isEmpty) {
                return SliverToBoxAdapter(
                  child: _ErrorView(error: home.error!),
                );
              }

              final children = <Widget>[];

              for (final section in home.sections) {
                final widget = _buildSection(section);
                if (widget != null) children.add(widget);
              }

              // Footer
              if (home.global != null) {
                children.add(const SizedBox(height: AppConstants.sectionSpacing));
                children.add(_FooterSection(global: home.global!));
              }

              children.add(const SizedBox(height: 32));

              return SliverList(
                delegate: SliverChildListDelegate(children),
              );
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget? _buildSection(HomeSection section) {
    switch (section.type) {
      case 'hero_banner':
        final data = section.heroBannerData;
        if (data.slides.isEmpty) return null;
        return _HeroBannerSection(data: data);

      case 'product_grid':
        final data = section.productGridData;
        if (data.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ProductCarouselSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () => widget.onNavTap?.call(1),
            showBottomCta: true,
          ),
        );

      case 'oriole_exclusive':
        final orData = section.orioleExclusiveData;
        if (orData.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ProductCarouselSection(
            data: orData,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () {},
            showBottomCta: true,
          ),
        );

      case 'product_carousel':
        final data = section.productGridData;
        if (data.products.isEmpty) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ProductCarouselSection(
            data: data,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'image_text':
        final data = section.imageTextData;
        if (!data.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ImageTextSection(data: data),
        );

      case 'shop_by_category':
        final catData = section.collectionRowData;
        if (!catData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ShopByCategorySection(data: catData),
        );

      case 'collection_row':
        final colData = section.collectionRowData;
        if (!colData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _CollectionRowSection(
            data: colData,
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'designer_rings':
        final drData = section.collectionRowData;
        if (!drData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _DesignerRingsSection(
            data: drData,
            onViewAll: () => widget.onNavTap?.call(1),
          ),
        );

      case 'brand_values':
        final bvData = section.brandValuesData;
        if (!bvData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _BrandValuesSection(data: bvData),
        );

      case 'reviews_carousel':
        final rvData = section.reviewsCarouselData;
        if (!rvData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _ReviewsCarouselSection(data: rvData),
        );

      case 'occasions':
        final occData = section.occasionsData;
        if (!occData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _OccasionsSection(
            data: occData,
            onProductTap: (handle) =>
                Navigator.of(context).pushNamed('/product', arguments: handle),
          ),
        );

      case 'stackable_bands':
      case 'customize_cta':
      case 'virtual_call_cta':
      case 'full_width_cta':
        final ctaData = section.fullWidthCtaData;
        if (!ctaData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _FullWidthCtaSection(data: ctaData),
        );

      case 'faq_accordion':
        final faqData = section.faqData;
        if (!faqData.hasContent) return null;
        return Padding(
          padding: const EdgeInsets.only(top: AppConstants.sectionSpacing),
          child: _FaqAccordionSection(data: faqData),
        );

      default:
        return null;
    }
  }
}

// ─── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: [
          Container(height: 460, color: Colors.white),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 200, color: Colors.white),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppConstants.cardSpacing,
                    mainAxisSpacing: AppConstants.cardSpacing,
                    childAspectRatio: 0.62,
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

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text('Could not load content', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(error,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.read<HomeProvider>().initialize(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              color: AppColors.textPrimary,
              child: Text('Retry',
                  style: AppTextStyles.button
                      .copyWith(color: AppColors.textWhite)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section: hero_banner ─────────────────────────────────────────────────────

class _HeroBannerSection extends StatefulWidget {
  final HeroBannerData data;
  const _HeroBannerSection({required this.data});

  @override
  State<_HeroBannerSection> createState() => _HeroBannerSectionState();
}

class _HeroBannerSectionState extends State<_HeroBannerSection> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = widget.data.slides;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 480,
            viewportFraction: 1.0,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          items: slides
              .map((slide) => _HeroBannerSlide(slide: slide))
              .toList(),
        ),
        if (slides.length > 1)
          Positioned(
            bottom: 16,
            child: AnimatedSmoothIndicator(
              activeIndex: _index,
              count: slides.length,
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

class _HeroBannerSlide extends StatelessWidget {
  final HeroBannerSlide slide;
  const _HeroBannerSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: slide.image,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.cardBackground),
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.cardBackground),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: slide.overlay),
              ],
              stops: const [0.4, 1.0],
            ),
          ),
        ),
        if (slide.title.isNotEmpty || slide.ctaLabel.isNotEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slide.title.isNotEmpty)
                  Text(
                    slide.title,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      shadows: const [
                        Shadow(
                            color: Color(0x80000000),
                            blurRadius: 8,
                            offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                if (slide.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x60000000), blurRadius: 6)
                      ],
                    ),
                  ),
                ],
                if (slide.ctaLabel.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _OutlineButton(label: slide.ctaLabel),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Section: product_carousel / product_grid (horizontal carousel) ──────────

class _ProductCarouselSection extends StatelessWidget {
  final ProductGridData data;
  final ValueChanged<String> onProductTap;
  final VoidCallback onViewAll;
  final bool showBottomCta;

  const _ProductCarouselSection({
    required this.data,
    required this.onProductTap,
    required this.onViewAll,
    this.showBottomCta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: data.title,
              actionLabel: null,
              onActionTap: onViewAll,
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: data.products.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) {
              final p = data.products[i];
              return ProductCard(
                product: p.toProduct(),
                width: 175,
                onTap: () => onProductTap(p.handle),
              );
            },
          ),
        ),
        if (showBottomCta && data.ctaLabel.isNotEmpty) ...[
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textPrimary),
                ),
                child: Text(
                  data.ctaLabel,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Section: image_text ──────────────────────────────────────────────────────

class _ImageTextSection extends StatelessWidget {
  final ImageTextData data;
  const _ImageTextSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasImage = data.image.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: data.image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.cardBackground),
              ),
            ),
          if (data.title.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(data.title, style: AppTextStyles.headlineLarge),
          ],
          if (data.body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              data.body,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
            ),
          ],
          if (data.ctaLabel.isNotEmpty) ...[
            const SizedBox(height: 20),
            _DarkButton(label: data.ctaLabel),
          ],
          if (data.secondaryCtaLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OutlineButton(label: data.secondaryCtaLabel, dark: true),
          ],
        ],
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _FooterSection extends StatelessWidget {
  final HomeGlobal global;
  const _FooterSection({required this.global});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppConstants.horizontalPadding * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            global.shopName.toUpperCase(),
            style: AppTextStyles.labelLarge.copyWith(letterSpacing: 3),
          ),
          if (global.shopTagline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              global.shopTagline,
              style: AppTextStyles.bodySmall
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ],

          // Contact
          if (global.contact.phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ContactRow(
                icon: Icons.phone_outlined, text: global.contact.phone),
          ],
          if (global.contact.email.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ContactRow(
                icon: Icons.email_outlined, text: global.contact.email),
          ],
          if (global.contact.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            _ContactRow(
                icon: Icons.location_on_outlined,
                text: global.contact.address),
          ],

          // Footer link groups
          if (global.navigation.footerLinks.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...global.navigation.footerLinks.map(
              (group) => _FooterLinkGroup(group: group),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            '© ${DateTime.now().year} ${global.shopName}. All rights reserved.',
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    );
  }
}

class _FooterLinkGroup extends StatelessWidget {
  final HomeFooterGroup group;
  const _FooterLinkGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(group.heading,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
        const SizedBox(height: 8),
        ...group.links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              link.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Shared button widgets ────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final bool dark;

  const _OutlineButton({required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.textPrimary : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      decoration: BoxDecoration(border: Border.all(color: color)),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(color: color, letterSpacing: 2),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  final String label;
  const _DarkButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      color: AppColors.textPrimary,
      child: Text(
        label,
        style: AppTextStyles.button
            .copyWith(color: AppColors.textWhite, letterSpacing: 2),
      ),
    );
  }
}

// ─── Section: collection_row / designer_rings ─────────────────────────────────

class _CollectionRowSection extends StatelessWidget {
  final CollectionRowData data;
  final VoidCallback onViewAll;

  const _CollectionRowSection({required this.data, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: data.title,
              actionLabel: data.ctaLabel.isNotEmpty ? data.ctaLabel : null,
              onActionTap: onViewAll,
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: data.tiles.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) => _CollectionTileCard(
              tile: data.tiles[i],
              onTap: onViewAll,
            ),
          ),
        ),
      ],
    );
  }
}

class _CollectionTileCard extends StatelessWidget {
  final CollectionTile tile;
  final VoidCallback onTap;

  const _CollectionTileCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: tile.imageUrl,
                fit: BoxFit.cover,
                width: 130,
                placeholder: (_, __) =>
                    Container(color: AppColors.cardBackground),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.cardBackground),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tile.title,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section: shop_by_category ───────────────────────────────────────────────

class _ShopByCategorySection extends StatelessWidget {
  final CollectionRowData data;

  const _ShopByCategorySection({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.tiles.isEmpty) return const SizedBox.shrink();
    final featured = data.tiles.first;
    final gridTiles = data.tiles.skip(1).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Text(data.title, style: AppTextStyles.headlineLarge),
          ),
        const SizedBox(height: 20),
        // Featured tile (Rings) — full width
        GestureDetector(
          onTap: () {},
          child: Stack(
            children: [
              SizedBox(
                height: 260,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: featured.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: AppColors.cardBackground),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.cardBackground),
                ),
              ),
              Container(
                height: 260,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      featured.title,
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: Colors.white),
                    ),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (gridTiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.3,
              ),
              itemCount: gridTiles.length,
              itemBuilder: (_, i) => _CategoryGridTile(tile: gridTiles[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryGridTile extends StatelessWidget {
  final CollectionTile tile;

  const _CategoryGridTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: tile.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                Container(color: AppColors.cardBackground),
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.cardBackground),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tile.title.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section: designer_rings ──────────────────────────────────────────────────

class _DesignerRingsSection extends StatelessWidget {
  final CollectionRowData data;
  final VoidCallback onViewAll;

  const _DesignerRingsSection({required this.data, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: data.title,
              actionLabel: null,
              onActionTap: onViewAll,
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: data.tiles.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) => _DesignerRingCard(tile: data.tiles[i]),
          ),
        ),
        if (data.ctaLabel.isNotEmpty) ...[
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary)),
                child: Text(
                  data.ctaLabel,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DesignerRingCard extends StatelessWidget {
  final CollectionTile tile;

  const _DesignerRingCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 200,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: tile.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.cardBackground),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.cardBackground),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tile.title.toUpperCase(),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (tile.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tile.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section: brand_values ────────────────────────────────────────────────────

class _BrandValuesSection extends StatelessWidget {
  final BrandValuesData data;

  const _BrandValuesSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.isNotEmpty)
            Text(data.title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: data.values.length.clamp(0, 4),
            itemBuilder: (_, i) {
              final v = data.values[i];
              return Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (v.icon.isNotEmpty)
                      Text(v.icon,
                          style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(v.title,
                        style: AppTextStyles.labelLarge
                            .copyWith(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      v.body,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Section: reviews_carousel ────────────────────────────────────────────────

class _ReviewsCarouselSection extends StatelessWidget {
  final ReviewsCarouselData data;

  const _ReviewsCarouselSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.sectionTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Text(data.sectionTitle,
                style: AppTextStyles.headlineLarge),
          ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: data.reviews.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) =>
                _ReviewCardWidget(review: data.reviews[i]),
          ),
        ),
      ],
    );
  }
}

class _ReviewCardWidget extends StatelessWidget {
  final ReviewCard review;

  const _ReviewCardWidget({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating.round() ? Icons.star : Icons.star_border,
                size: 14,
                color: AppColors.gold,
              );
            }),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              review.body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              overflow: TextOverflow.ellipsis,
              maxLines: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (review.avatarUrl.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: review.avatarUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(),
                  ),
                )
              else
                _avatarFallback(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.g_mobiledata,
                            size: 14, color: AppColors.textLight),
                        Text(' Google Review',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textLight, fontSize: 9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.border,
      ),
      child: const Icon(Icons.person, size: 18, color: AppColors.textLight),
    );
  }
}

// ─── Section: occasions ───────────────────────────────────────────────────────

class _OccasionsSection extends StatefulWidget {
  final OccasionsData data;
  final ValueChanged<String> onProductTap;

  const _OccasionsSection({
    required this.data,
    required this.onProductTap,
  });

  @override
  State<_OccasionsSection> createState() => _OccasionsSectionState();
}

class _OccasionsSectionState extends State<_OccasionsSection> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = widget.data.tabs;
    final selected = tabs[_selectedTab];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Text(widget.data.title,
                style: AppTextStyles.headlineLarge),
          ),
        const SizedBox(height: 16),
        // Tab chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final isSelected = e.key == _selectedTab;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = e.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.textPrimary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    e.value.title,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.textWhite
                          : AppColors.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        // Products for selected tab
        if (selected.products.isNotEmpty)
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              itemCount: selected.products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.cardSpacing),
              itemBuilder: (_, i) {
                final p = selected.products[i];
                return ProductCard(
                  product: p.toProduct(),
                  width: 160,
                  onTap: () => widget.onProductTap(p.handle),
                );
              },
            ),
          )
        else if (selected.imageUrl.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: selected.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.cardBackground),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.cardBackground),
              ),
            ),
          ),
        if (widget.data.ctaLabel.isNotEmpty) ...[
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textPrimary)),
                child: Text(
                  widget.data.ctaLabel,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Section: faq_accordion ───────────────────────────────────────────────────

class _FaqAccordionSection extends StatelessWidget {
  final FaqData data;

  const _FaqAccordionSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.title.isNotEmpty)
            Text(data.title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: 16),
          ...data.items.map((item) => _FaqTile(item: item)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final FaqItem item;

  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.question,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  _expanded ? Icons.remove : Icons.add,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              widget.item.answer,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// ─── Section: full_width_cta ──────────────────────────────────────────────────

class _FullWidthCtaSection extends StatelessWidget {
  final FullWidthCtaData data;

  const _FullWidthCtaSection({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.imageUrl.isNotEmpty) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.cardBackground),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.cardBackground),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _CtaContent(data: data, dark: false),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(32),
        color: AppColors.surface,
        child: _CtaContent(data: data, dark: true),
      ),
    );
  }
}

class _CtaContent extends StatelessWidget {
  final FullWidthCtaData data;
  final bool dark;

  const _CtaContent({required this.data, required this.dark});

  @override
  Widget build(BuildContext context) {
    final textColor = dark ? AppColors.textPrimary : Colors.white;
    final subColor =
        dark ? AppColors.textSecondary : Colors.white.withValues(alpha: 0.8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.title.isNotEmpty)
          Text(
            data.title,
            style: AppTextStyles.headlineLarge.copyWith(color: textColor),
          ),
        if (data.subtitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: subColor),
          ),
        ],
        if (data.ctaLabel.isNotEmpty) ...[
          const SizedBox(height: 24),
          dark
              ? _DarkButton(label: data.ctaLabel)
              : _OutlineButton(label: data.ctaLabel),
        ],
      ],
    );
  }
}
