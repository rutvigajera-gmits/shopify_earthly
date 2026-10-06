import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../common/widgets/section_header.dart';

class CollectionRowSection extends StatelessWidget {
  final CollectionRowData data;
  final VoidCallback onViewAll;

  const CollectionRowSection({super.key, required this.data, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: SectionHeader(
              title: data.title,
              actionLabel: data.ctaLabel.isNotEmpty ? data.ctaLabel : null,
              onActionTap: onViewAll,
            ),
          ),
        16.height,
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            itemCount: data.tiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) => _CollectionCard(tile: data.tiles[i], onTap: onViewAll),
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CollectionTile tile;
  final VoidCallback onTap;

  const _CollectionCard({required this.tile, required this.onTap});

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
                placeholder: (_, __) => Container(color: AppColors.cardBackground),
                errorWidget: (_, __, ___) => Container(color: AppColors.cardBackground),
              ),
            ),
            8.height,
            Text(
              tile.title,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
