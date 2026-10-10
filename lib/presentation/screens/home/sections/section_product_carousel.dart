import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../common/widgets/section_header.dart';
import '../../../common/widgets/product_card.dart';

class ProductCarouselSection extends StatelessWidget {
  final ProductGridData data;
  final ValueChanged<String> onProductTap;
  final VoidCallback onViewAll;

  const ProductCarouselSection({
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
          SectionHeader(title: data.title, actionLabel: null, onActionTap: onViewAll)
              .paddingSymmetric(horizontal: AppConstants.horizontalPadding),
        16.height,
        SizedBox(
          height: 290,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            itemCount: data.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) {
              final p = data.products[i];
              return ProductCard(product: p.toProduct(), width: 168, onTap: () => onProductTap(p.handle));
            },
          ),
        ),
      ],
    );
  }
}
