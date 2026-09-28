import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo_earthly/core/constants/app_constants.dart';
import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/core/theme/app_text_styles.dart';
import 'package:demo_earthly/data/models/home_api_model.dart';
import 'home_shared.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class OrioleExclusiveSection extends StatelessWidget {
  final ProductGridData data;
  final ValueChanged<String> onProductTap;
  final VoidCallback onViewAll;

  const OrioleExclusiveSection({super.key,
    required this.data,
    required this.onProductTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.headlineMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w600, height: 1.2),
              children: [
                TextSpan(
                  text: data.title.isNotEmpty ? '${data.title} - ' : 'Oriole Diamonds - ',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const TextSpan(
                  text: 'Earthly Exclusive!',
                  style: TextStyle(color: AppColors.teal),
                ),
              ],
            ),
          ),
        ),
        20.height,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.cardSpacing,
              mainAxisSpacing: AppConstants.cardSpacing,
              mainAxisExtent: 320,
            ),
            itemCount: data.products.length,
            itemBuilder: (_, i) {
              final p = data.products[i];
              return _OrioleProductCard(product: p, onTap: () => onProductTap(p.handle));
            },
          ),
        ),
        if (data.ctaLabel.isNotEmpty) ...[
          24.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: HomePillBtn(label: data.ctaLabel, onTap: onViewAll),
          ),
        ],
      ],
    );
  }
}

class _OrioleProductCard extends StatelessWidget {
  final HomeProduct product;
  final VoidCallback? onTap;

  const _OrioleProductCard({required this.product, this.onTap});

  bool get _hasPrice => (double.tryParse(product.price) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4)),
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
                  product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surfaceCream),
                          errorWidget: (_, __, ___) => Container(color: AppColors.surfaceCream),
                        )
                      : Container(color: AppColors.surfaceCream),
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                      child: const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      width: 34, height: 34,
                      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
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
                    if (_hasPrice)
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: [
                          TextSpan(
                            text: 'From ',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                          ),
                          TextSpan(
                            text: product.formattedPrice,
                            style: AppTextStyles.priceText.copyWith(color: AppColors.teal, fontSize: 13),
                          ),
                        ]),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textPrimary, width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Ask For Price',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                          ),
                        ),
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
