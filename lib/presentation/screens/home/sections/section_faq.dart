import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';

class FaqAccordionSection extends StatelessWidget {
  final FaqData data;
  const FaqAccordionSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.title.isNotEmpty) Text(data.title, style: AppTextStyles.headlineLarge),
        16.height,
        ...data.items.map((item) => _FaqTile(item: item)),
      ],
    ).paddingSymmetric(horizontal: AppConstants.horizontalPadding);
  }
}

class _FaqTile extends StatefulWidget {
  final FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(widget.item.question,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
              ),
              Icon(_expanded ? Icons.remove : Icons.add, size: 18, color: AppColors.textSecondary),
            ],
          ).paddingSymmetric(vertical: 14),
        ),
        if (_expanded)
          Text(
            widget.item.answer,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.6),
          ).paddingOnly(bottom: 14),
        const Divider(height: 1, color: AppColors.neutral200),
      ],
    );
  }
}
