import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../common/widgets/section_header.dart';
import 'home_shared.dart';

class DesignerRingsSection extends StatelessWidget {
  final CollectionRowData data;
  final VoidCallback onViewAll;
  final ValueChanged<String> onTap;

  const DesignerRingsSection({
    super.key,
    required this.data,
    required this.onViewAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = data.tiles;
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: SectionHeader(
            title: data.title.isNotEmpty ? data.title : 'Rings Collection',
            actionLabel: null,
            onActionTap: onViewAll,
          ),
        ),
        14.height,
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppConstants.cardSpacing),
            itemBuilder: (_, i) => SizedBox(
              width: 148,
              child: _RingCollectionCard(tile: tiles[i], onTap: () => onTap(tiles[i].handle)),
            ),
          ),
        ),
        if (data.ctaLabel.isNotEmpty) ...[
          20.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            child: HomePillBtn(label: data.ctaLabel, onTap: onViewAll),
          ),
        ],
      ],
    );
  }
}

class _RingCollectionCard extends StatelessWidget {
  final CollectionTile tile;
  final VoidCallback onTap;

  const _RingCollectionCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCream,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tile.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: tile.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceCream),
                errorWidget: (_, __, ___) => Container(color: AppColors.surfaceCream),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 12, right: 12, bottom: 14,
              child: Text(
                tile.title,
                style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white, fontSize: 18, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
