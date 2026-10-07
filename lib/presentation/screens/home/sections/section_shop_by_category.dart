import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo_earthly/core/constants/app_constants.dart';
import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/core/theme/app_text_styles.dart';
import 'package:demo_earthly/data/models/home_api_model.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ShopByCategorySection extends StatelessWidget {
  final CollectionRowData data;
  final ValueChanged<CollectionTile> onTap;

  const ShopByCategorySection({super.key, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (data.tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: Text('Shop by Category', style: AppTextStyles.headlineLarge),
        ),
        16.height,
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            itemCount: data.tiles.length,
            separatorBuilder: (_, __) => 14.width,
            itemBuilder: (_, i) => _CategoryTile(
              tile: data.tiles[i],
              onTap: () => onTap(data.tiles[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CollectionTile tile;
  final VoidCallback onTap;

  const _CategoryTile({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surfaceCream,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.antiAlias,
              child: tile.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: tile.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppColors.surfaceCream),
                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceCream),
                    )
                  : Container(color: AppColors.surfaceCream),
            ),
            6.height,
            Text(
              tile.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
