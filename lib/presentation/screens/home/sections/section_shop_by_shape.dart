import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import '../../../widgets/section_header.dart';

const _kAllShapes = [
  ('Round',    'assets/icons/Round.svg',    'round-cut-diamonds'),
  ('Oval',     'assets/icons/Oval.svg',     'oval-cut-diamonds'),
  ('Pear',     'assets/icons/Pear.svg',     'pear-cut-diamonds'),
  ('Marquise', 'assets/icons/Marquise.svg', 'marquise-cut-diamonds'),
  ('Cushion',  'assets/icons/Cushion.svg',  'cushion-cut-diamonds'),
  ('Princess', 'assets/icons/Princess.svg', 'princess-cut-diamonds'),
  ('Emerald',  'assets/icons/Emerald.svg',  'emerald-cut-diamonds'),
  ('Heart',    'assets/icons/Heart.svg',    'heart-cut-diamonds'),
  ('Asscher',  'assets/icons/Asscher.svg',  'asscher-cut-diamonds'),
  ('Radiant',  'assets/icons/Radiant.svg',  'radiant-cut-diamonds'),
];

class ShopByShapeSection extends StatelessWidget {
  final CollectionRowData data;
  final VoidCallback onViewAll;
  final void Function(String shapeName, String handle) onTap;

  const ShopByShapeSection({
    super.key,
    required this.data,
    required this.onViewAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final apiHandles = <String, String>{
      for (final t in data.tiles) t.title.toLowerCase(): t.handle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
          child: SectionHeader(
            title: data.title.isNotEmpty ? data.title : 'Shop by Shape',
            actionLabel: 'View All',
            onActionTap: onViewAll,
          ),
        ),
        16.height,
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
            itemCount: _kAllShapes.length,
            separatorBuilder: (_, __) => 20.width,
            itemBuilder: (_, i) {
              final (name, svg, fallbackHandle) = _kAllShapes[i];
              final handle = apiHandles[name.toLowerCase()] ?? fallbackHandle;
              return _ShapeTile(label: name, svgPath: svg, onTap: () => onTap(name, handle));
            },
          ),
        ),
      ],
    );
  }
}

class _ShapeTile extends StatelessWidget {
  final String label;
  final String svgPath;
  final VoidCallback onTap;

  const _ShapeTile({required this.label, required this.svgPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                color: AppColors.surfaceCream,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(10),
              child: SvgPicture.asset(
                svgPath,
                colorFilter: const ColorFilter.mode(AppColors.teal, BlendMode.srcIn),
              ),
            ),
            6.height,
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary, fontSize: 10, letterSpacing: 0.3),
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
