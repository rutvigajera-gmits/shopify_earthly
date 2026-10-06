import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:demo_earthly/core/constants/app_constants.dart';
import 'package:demo_earthly/data/models/home_api_model.dart';
import '../../../common/widgets/section_header.dart';
import 'home_shared.dart';

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
              mainAxisExtent: 310,
            ),
            itemCount: data.products.length,
            itemBuilder: (_, i) {
              final p = data.products[i];
              return HomeFeaturedCard(product: p.toProduct(), onTap: () => onProductTap(p.handle));
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
