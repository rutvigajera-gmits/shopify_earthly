import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';
import 'home_shared.dart';

class FullWidthCtaSection extends StatelessWidget {
  final FullWidthCtaData data;
  const FullWidthCtaSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.imageUrl.isNotEmpty) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: CachedNetworkImage(
              imageUrl: data.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceDark),
              errorWidget: (_, __, ___) => Container(color: AppColors.surfaceDark),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24, right: 24, bottom: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data.title.isNotEmpty)
                  Text(data.title,
                      style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
                if (data.subtitle.isNotEmpty) ...[
                  8.height,
                  Text(data.subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                ],
                if (data.ctaLabel.isNotEmpty) ...[
                  20.height,
                  HomeOutlineBtn(label: data.ctaLabel),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(28),
        color: AppColors.surfaceWarm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data.title.isNotEmpty) Text(data.title, style: AppTextStyles.headlineLarge),
            if (data.subtitle.isNotEmpty) ...[
              8.height,
              Text(data.subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ],
            if (data.ctaLabel.isNotEmpty) ...[
              20.height,
              HomeDarkBtn(label: data.ctaLabel),
            ],
          ],
        ),
      ),
    );
  }
}

class VirtualCallSection extends StatelessWidget {
  final FullWidthCtaData data;
  const VirtualCallSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceBase,
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            data.title.isNotEmpty ? data.title : 'Book a Virtual Call With Your Advisor',
            style: AppTextStyles.headlineLarge,
            textAlign: TextAlign.center,
          ),
          if (data.subtitle.isNotEmpty) ...[
            12.height,
            Text(
              data.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
          24.height,
          HomeDarkBtn(label: data.ctaLabel.isNotEmpty ? data.ctaLabel : 'Schedule Your Call'),
        ],
      ),
    );
  }
}

class ImageTextSection extends StatelessWidget {
  final ImageTextData data;
  const ImageTextSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.image.isNotEmpty)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: CachedNetworkImage(
                imageUrl: data.image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: AppColors.cardBackground),
              ),
            ),
          if (data.title.isNotEmpty) ...[
            16.height,
            Text(data.title, style: AppTextStyles.headlineLarge),
          ],
          if (data.body.isNotEmpty) ...[
            10.height,
            Text(data.body,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.6)),
          ],
          if (data.ctaLabel.isNotEmpty) ...[
            20.height,
            HomeDarkBtn(label: data.ctaLabel),
          ],
        ],
      ),
    );
  }
}
