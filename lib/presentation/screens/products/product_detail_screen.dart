import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/review_provider.dart';
import '../../../data/providers/shop_provider.dart';
import '../../../data/providers/wishlist_provider.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final String handle;
  const ProductDetailScreen({super.key, required this.handle});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}


class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductByHandle(widget.handle);
      RecentlyViewedService.addHandle(widget.handle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loadingProduct) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final product = provider.selectedProduct;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: _ProductLoadError(error: provider.productError),
          );
        }

        _selectedVariant ??= product.variants.isNotEmpty
            ? product.variants.first
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _ImageGallerySliver(
                images: product.images,
                currentIndex: _imageIndex,
                onIndexChanged: (i) => setState(() => _imageIndex = i),
                handle: product.handle,
                productTitle: product.title,
              ),
              SliverToBoxAdapter(
                child: _ProductDetails(
                  product: product,
                  selectedVariant: _selectedVariant,
                  quantity: _quantity,
                  onVariantSelected: (v) =>
                      setState(() => _selectedVariant = v),
                  onQuantityChanged: (q) => setState(() => _quantity = q),
                  onAddToCart: () => _addToCart(product),
                  addingToCart: _addingToCart,
                ),
              ),
              SliverToBoxAdapter(
                child: _ProductReviewsSection(handle: product.handle),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart(Product product) async {
    final variant = _selectedVariant ?? product.variants.firstOrNull;
    if (variant == null) return;

    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addItem(variant.id, _quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }
}

class _ImageGallerySliver extends StatelessWidget {
  final List<ProductImage> images;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final String handle;
  final String productTitle;

  const _ImageGallerySliver({
    required this.images,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.handle,
    required this.productTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 440,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 16, color: AppColors.textPrimary),
        ),
      ),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlist, _) {
            final saved = wishlist.contains(handle);
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: saved ? Colors.red : AppColors.textPrimary,
                ),
                onPressed: () => wishlist.toggle(handle),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.share, size: 18),
            color: AppColors.textPrimary,
            onPressed: () => Share.share(
              'Check out this beautiful piece from Earthly Jewels!\nhttps://earthlyjewels.co/products/$handle',
              subject: productTitle,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (images.isNotEmpty)
              PageView.builder(
                itemCount: images.length,
                onPageChanged: onIndexChanged,
                itemBuilder: (_, i) => CachedNetworkImage(
                  imageUrl: images[i].url,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(color: AppColors.shimmerBase),
                  ),
                  errorWidget: (ctx, url, err) =>
                      Container(color: AppColors.cardBackground),
                ),
              )
            else
              Container(color: AppColors.cardBackground),
            // Thumbnail strip
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: currentIndex == i ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: currentIndex == i
                            ? AppColors.textPrimary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetails extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;
  final int quantity;
  final ValueChanged<ProductVariant> onVariantSelected;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final bool addingToCart;

  const _ProductDetails({
    required this.product,
    required this.selectedVariant,
    required this.quantity,
    required this.onVariantSelected,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.addingToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Badge
          if (product.isMembersOnly)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: AppColors.badgeBackground,
              child: Text('MEMBERS ONLY', style: AppTextStyles.badge),
            ),

          // Title
          Text(product.title, style: AppTextStyles.displaySmall),
          const SizedBox(height: 6),

          // Price
          Row(
            children: [
              Text(
                selectedVariant != null
                    ? _formatPrice(selectedVariant!.price)
                    : 'From ${product.formattedMinPrice}',
                style: AppTextStyles.priceLarge,
              ),
              if (selectedVariant?.hasDiscount == true) ...[
                const SizedBox(width: 10),
                Text(
                  _formatPrice(selectedVariant!.compareAtPrice!),
                  style: AppTextStyles.priceStrikethrough,
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),
          Text(
            'Inclusive of all taxes',
            style: AppTextStyles.bodySmall,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),

          // Variant options
          if (product.variants.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Option', style: AppTextStyles.labelLarge),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse(
                        'https://earthlyjewels.co/pages/ring-size-chart'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    'Size Guide',
                    style: AppTextStyles.bodySmall.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: product.variants.map((v) {
                final isSelected = selectedVariant?.id == v.id;
                return GestureDetector(
                  onTap: () => onVariantSelected(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.background,
                    ),
                    child: Text(
                      v.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: isSelected
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
          ],

          // Quantity
          Text('Quantity', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          _QuantitySelector(
            quantity: quantity,
            onChanged: onQuantityChanged,
          ),

          const SizedBox(height: 28),

          // Add to Cart button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addingToCart ? null : onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const RoundedRectangleBorder(),
                elevation: 0,
              ),
              child: addingToCart
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'ADD TO BAG',
                      style: AppTextStyles.button.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Wishlist
          SizedBox(
            width: double.infinity,
            child: Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                final saved = wishlist.contains(product.handle);
                return OutlinedButton.icon(
                  onPressed: () => wishlist.toggle(product.handle),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: saved ? Colors.red : AppColors.textPrimary,
                  ),
                  label: Text(
                    saved ? 'SAVED TO WISHLIST' : 'ADD TO WISHLIST',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),

          // Description
          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            Text('Product Details', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Text(
              product.description!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // USPs
          const _ProductUspStrip(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatPrice(String raw) {
    final price = double.tryParse(raw) ?? 0;
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '₹$formatted';
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge,
            ),
          ),
          _QtyButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textLight : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ProductUspStrip extends StatelessWidget {
  const _ProductUspStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: const Column(
        children: [
          _UspRow(icon: Icons.verified_outlined, label: 'Certified Lab-Grown Diamond'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.local_shipping_outlined, label: 'Free Insured Shipping'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.replay_outlined, label: '15-Day Easy Returns'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.workspace_premium_outlined, label: 'Lifetime Warranty'),
        ],
      ),
    );
  }
}

class _UspRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UspRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
        )),
      ],
    );
  }
}

// ─── Product Load Error ───────────────────────────────────────────────────────

class _ProductLoadError extends StatelessWidget {
  final String? error;
  const _ProductLoadError({this.error});

  @override
  Widget build(BuildContext context) {
    final isTokenError = error != null &&
        (error!.contains('401') ||
            error!.contains('403') ||
            error!.contains('Unauthorized') ||
            error!.contains('GraphQL'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              border: Border.all(color: const Color(0xFFFFCC80)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFE65100), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Product could not load',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFFFFF0F0),
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.red, height: 1.4),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (isTokenError)
                  const Text(
                    'Fix: Your Shopify Storefront API token is invalid.\n\n'
                    '1. Open: earthlyjewels.co/admin/settings/apps\n'
                    '2. Click "Develop apps"\n'
                    '3. Open your app → Configuration tab\n'
                    '4. Enable all Storefront API scopes → Save\n'
                    '5. API credentials tab → Copy token\n'
                    '6. Paste in lib/core/constants/app_constants.dart\n'
                    '   storefrontAccessToken = \'your_new_token\'',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5D4037),
                        height: 1.6),
                  )
                else
                  const Text(
                    'Product data comes from Shopify Storefront API.\n'
                    'Check your internet connection and API token.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF5D4037),
                        height: 1.6),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product Reviews Section ──────────────────────────────────────────────────

class _ProductReviewsSection extends StatefulWidget {
  final String handle;
  const _ProductReviewsSection({required this.handle});

  @override
  State<_ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<_ProductReviewsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReviewProvider>().loadProductReviews(widget.handle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReviewProvider, ShopProvider>(
      builder: (context, rp, shop, _) {
        final loading = rp.isLoadingProduct(widget.handle);
        final summary = rp.productReviews(widget.handle);

        // Use product-specific reviews from developer's API / SPR,
        // or fall back to store-level home API reviews.
        final List<Review> reviews;
        final int total;
        final double avg;

        if (summary != null && summary.totalCount > 0) {
          reviews = summary.reviews;
          total = summary.totalCount;
          avg = summary.averageRating;
        } else if (!loading && shop.homeReviews.isNotEmpty) {
          // Filter by productHandle or show all store reviews
          final filtered = shop.homeReviews
              .where((r) =>
                  r.productHandle == widget.handle ||
                  (r.productTitle != null &&
                      r.productTitle!
                          .toLowerCase()
                          .contains(widget.handle.replaceAll('-', ' '))))
              .toList();
          final display =
              filtered.isNotEmpty ? filtered : shop.homeReviews.take(5).toList();
          reviews = display;
          total = display.length;
          avg = display.isEmpty
              ? 0
              : display.fold(0.0, (s, r) => s + r.rating) / display.length;
        } else {
          reviews = [];
          total = 0;
          avg = 0;
        }

        if (loading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        }

        if (total == 0) return const SizedBox.shrink();

        final displaySummary = ReviewSummary(
          averageRating: avg,
          totalCount: total,
          reviews: reviews,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _ReviewSummaryHeader(summary: displaySummary),
            ),
            const SizedBox(height: 16),
            ...reviews.map((r) => _ReviewCard(review: r)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _ReviewSummaryHeader extends StatelessWidget {
  final ReviewSummary summary;
  const _ReviewSummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          summary.averageRating.toStringAsFixed(1),
          style: AppTextStyles.displaySmall.copyWith(
            fontSize: 36,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StarRow(rating: summary.averageRating, size: 18),
            const SizedBox(height: 4),
            Text(
              '${summary.totalCount} ${summary.totalCount == 1 ? 'review' : 'reviews'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRow(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              if (review.formattedDate.isNotEmpty)
                Text(
                  review.formattedDate,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.title!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            review.body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            review.reviewerName,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && i < rating;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: AppColors.gold,
        );
      }),
    );
  }
}
