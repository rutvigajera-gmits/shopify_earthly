import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(product: product),
            const SizedBox(height: 10),
            _ProductInfo(product: product),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final Product product;
  const _ProductImage({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: product.primaryImage != null
              ? CachedNetworkImage(
                  imageUrl: product.primaryImage!.url,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => _shimmer(),
                  errorWidget: (ctx, url, err) => _placeholder(),
                )
              : _placeholder(),
        ),
        if (product.isMembersOnly)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.badgeBackground,
              child: Text('MEMBERS ONLY', style: AppTextStyles.badge),
            ),
          ),
        // Wishlist button
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(color: AppColors.cardBackground);
  }

  Widget _shimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Container(color: AppColors.shimmerBase),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.title,
            style: AppTextStyles.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'From ${product.formattedMinPrice}',
            style: AppTextStyles.priceText,
          ),
        ],
      ),
    );
  }
}

// Shimmer placeholder card shown while loading
class ProductCardSkeleton extends StatelessWidget {
  final double? width;
  const ProductCardSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(color: AppColors.shimmerBase),
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              width: double.infinity,
              color: AppColors.shimmerBase,
            ),
            const SizedBox(height: 6),
            Container(
              height: 12,
              width: 80,
              color: AppColors.shimmerBase,
            ),
          ],
        ),
      ),
    );
  }
}
