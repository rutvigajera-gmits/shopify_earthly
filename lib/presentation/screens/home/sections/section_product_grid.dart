import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:demo_earthly/core/constants/app_constants.dart';
import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/core/theme/app_text_styles.dart';
import 'package:demo_earthly/data/models/home_api_model.dart';
import '../../../common/widgets/product_card.dart';
import '../../../common/widgets/section_header.dart';

class ProductGridSection extends StatelessWidget {
  final ProductGridData data;
  final ValueChanged<String> onProductTap;
  final VoidCallback onViewAll;

  const ProductGridSection({
    super.key,
    required this.data,
    required this.onProductTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(title: data.title, actionLabel: null, onActionTap: onViewAll),
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
              mainAxisExtent: 240,
            ),
            itemCount: data.products.length,
            itemBuilder: (_, i) {
              final p = data.products[i];
              return ProductCard(product: p.toProduct(), onTap: () => onProductTap(p.handle));
            },
          ),
        ),
        if (data.ctaLabel.isNotEmpty) ...[
          24.height,
          Center(
            child: GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: Text(
                  data.ctaLabel,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.0,
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
