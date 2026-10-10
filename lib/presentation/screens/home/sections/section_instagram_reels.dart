import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo_earthly/core/constants/app_constants.dart';
import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/core/theme/app_text_styles.dart';
import 'package:demo_earthly/data/models/home_api_model.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class InstagramReelsSection extends StatelessWidget {
  final InstagramReelsData data;

  const InstagramReelsSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _gradientIcon(),
            12.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title,
                    style: AppTextStyles.headlineMedium
                        .copyWith(fontSize: 20)),
                4.height,
                Text(
                  data.instagramHandle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ).paddingSymmetric(horizontal: AppConstants.horizontalPadding),
        if (data.reels.isNotEmpty) ...[
          20.height,
          SizedBox(
            height: 224,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              itemCount: data.reels.length,
              separatorBuilder: (_, __) => 10.width,
              itemBuilder: (_, i) => _ReelCard(reel: data.reels[i]),
            ),
          ),
        ],
        24.height,
        Center(
          child: GestureDetector(
            onTap: () async {
              final uri =
                  Uri.parse('https://www.instagram.com/earthlyjewels.co/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF833AB4),
                    Color(0xFFFD1D1D),
                    Color(0xFFFCAF45)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 18),
                  8.width,
                  Text(
                    'FOLLOW ON INSTAGRAM',
                    style: AppTextStyles.button
                        .copyWith(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.play_circle_outline,
          color: Colors.white, size: 22),
    );
  }
}

class _ReelCard extends StatelessWidget {
  final InstagramReelItem reel;

  const _ReelCard({required this.reel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (reel.reelUrl.isEmpty) return;
        final uri = Uri.parse(reel.reelUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 126,
          height: 224,
          child: Stack(
            fit: StackFit.expand,
            children: [
              reel.thumbnailUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: reel.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppColors.surfaceCream),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppColors.surfaceCream),
                    )
                  : Container(
                      color: AppColors.surfaceCream,
                      child: const Icon(Icons.play_circle_outline,
                          size: 48, color: AppColors.textMuted),
                    ),
              // bottom gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Instagram gradient badge (top-right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFCAF45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 16),
                ),
              ),
              if (reel.caption.isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    reel.caption,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
