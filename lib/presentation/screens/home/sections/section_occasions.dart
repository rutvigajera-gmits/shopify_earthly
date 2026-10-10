import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../common/widgets/product_card.dart';
import 'home_shared.dart';

class OccasionsSection extends StatefulWidget {
  final OccasionsData data;
  final ValueChanged<String> onProductTap;
  final VoidCallback onViewAll;

  const OccasionsSection({
    super.key,
    required this.data,
    required this.onProductTap,
    required this.onViewAll,
  });

  @override
  State<OccasionsSection> createState() => _OccasionsSectionState();
}

class _OccasionsSectionState extends State<OccasionsSection> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = widget.data.tabs;
    if (tabs.isEmpty) return const SizedBox.shrink();
    final selected = tabs[_selectedTab];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.data.title.isNotEmpty)
          Text(widget.data.title, style: AppTextStyles.headlineLarge)
              .paddingSymmetric(horizontal: AppConstants.horizontalPadding),
        14.height,

        // Pill-shaped filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final isActive = e.key == _selectedTab;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.neutral200,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    e.value.title,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive ? AppColors.textWhite : AppColors.textPrimary,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        16.height,

        if (selected.products.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.cardSpacing,
              mainAxisSpacing: AppConstants.cardSpacing,
              mainAxisExtent: 240,
            ),
            itemCount: selected.products.take(4).length,
            itemBuilder: (_, i) {
              final p = selected.products[i];
              return ProductCard(product: p.toProduct(), onTap: () => widget.onProductTap(p.handle));
            },
          ).paddingSymmetric(horizontal: AppConstants.horizontalPadding)
        else if (selected.imageUrl.isNotEmpty)
          AspectRatio(
            aspectRatio: 4 / 3,
            child: CachedNetworkImage(
              imageUrl: selected.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.cardBackground),
              errorWidget: (_, __, ___) => Container(color: AppColors.cardBackground),
            ),
          ).paddingSymmetric(horizontal: AppConstants.horizontalPadding),

        if (widget.data.ctaLabel.isNotEmpty) ...[
          24.height,
          HomePillBtn(label: widget.data.ctaLabel, onTap: widget.onViewAll)
              .paddingSymmetric(horizontal: AppConstants.horizontalPadding),
        ],
      ],
    );
  }
}
