import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../screens/products/product_detail_screen.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;

  const ProductCard({super.key, required this.product, this.onTap, this.width});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OpenContainer<bool>(
        transitionDuration: const Duration(milliseconds: 680),
        transitionType: ContainerTransitionType.fade,
        openBuilder: (_, __) => ProductDetailScreen(handle: widget.product.handle),
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        closedColor: AppColors.surfaceBase,
        closedElevation: 0,
        openColor: AppColors.surfaceBase,
        tappable: false,
        closedBuilder: (_, openContainer) {
          return GestureDetector(
            onTap: () {
              setState(() => _pressed = false);
              openContainer();
            },
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.965 : 1.0,
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                      aspectRatio: 1.0,
                      child: _ProductImage(product: widget.product)),
                  Flexible(child: _ProductInfo(product: widget.product)),
                ],
              ),
            ),
          );
        },
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
      fit: StackFit.expand,
      children: [
        product.primaryImage != null && product.primaryImage!.url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: product.primaryImage!.url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _shimmer(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
        Positioned(
          top: 8,
          right: 8,
          child: Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              final saved = wishlist.contains(product.handle);
              return GestureDetector(
                onTap: () => wishlist.toggle(product.handle),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    size: 15,
                    color: saved ? Colors.red : AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(color: AppColors.neutral100);

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(color: AppColors.shimmerBase),
      );
}

class _ProductInfo extends StatelessWidget {
  final Product product;
  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    final subtitle =
        product.vendor?.isNotEmpty == true ? product.vendor! : '';
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Marquee(
              directionMarguee: DirectionMarguee.oneDirection,
              child: Text(product.title,
                  style: AppTextStyles.productName,),

            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 5),
            Text(product.formattedMinPrice,
                style: AppTextStyles.priceText
                    .copyWith(color: AppColors.teal, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  final double? width;
  const ProductCardSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(color: AppColors.shimmerBase),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: 13,
                        width: double.infinity,
                        color: AppColors.shimmerBase),
                    const SizedBox(height: 6),
                    Container(
                        height: 11, width: 90, color: AppColors.shimmerBase),
                    const SizedBox(height: 6),
                    Container(
                        height: 13, width: 70, color: AppColors.shimmerBase),
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
