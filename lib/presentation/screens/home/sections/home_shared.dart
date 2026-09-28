import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/product_model.dart';

// Reusable product card — used by ProductGridSection and OccasionsSection
class HomeFeaturedCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const HomeFeaturedCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.primaryImage != null
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage!.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surfaceCream),
                          errorWidget: (_, __, ___) => Container(color: AppColors.surfaceCream),
                        )
                      : Container(color: AppColors.surfaceCream),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 36,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.title,
                      style: AppTextStyles.productName.copyWith(fontSize: 12, height: 1.35),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'From ',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                        TextSpan(
                          text: product.formattedMinPrice,
                          style: AppTextStyles.priceText.copyWith(color: AppColors.teal, fontSize: 13),
                        ),
                      ]),
                    ),
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

// Full-width dark pill button
class HomePillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const HomePillBtn({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(color: Colors.white, letterSpacing: 1.0),
        ),
      ),
    );
  }
}

// White outlined button — used on dark/image backgrounds
class HomeOutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const HomeOutlineBtn({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: AppTextStyles.button.copyWith(color: Colors.white, letterSpacing: 1.5)),
    );
  }
}

// Solid dark inline button
class HomeDarkBtn extends StatelessWidget {
  final String label;

  const HomeDarkBtn({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
      color: AppColors.primary,
      child: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.textWhite, letterSpacing: 1.5)),
    );
  }
}
