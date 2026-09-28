import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/home_api_model.dart';

class HeroBannerSection extends StatefulWidget {
  final HeroBannerData data;
  const HeroBannerSection({super.key, required this.data});

  @override
  State<HeroBannerSection> createState() => _HeroBannerSectionState();
}

class _HeroBannerSectionState extends State<HeroBannerSection> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final slides = widget.data.slides;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 440,
            viewportFraction: 1.0,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          items: slides.map((s) => _HeroBannerSlide(slide: s)).toList(),
        ),
        if (slides.length > 1)
          Positioned(
            bottom: 20,
            child: AnimatedSmoothIndicator(
              activeIndex: _index,
              count: slides.length,
              effect: const ExpandingDotsEffect(
                dotWidth: 5,
                dotHeight: 5,
                activeDotColor: Colors.white,
                dotColor: Colors.white38,
                expansionFactor: 3,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroBannerSlide extends StatefulWidget {
  final HeroBannerSlide slide;
  const _HeroBannerSlide({required this.slide});

  @override
  State<_HeroBannerSlide> createState() => _HeroBannerSlideState();
}

class _HeroBannerSlideState extends State<_HeroBannerSlide> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.slide.hasVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.slide.videoUrl),
    );
    _videoCtrl = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('[Banner] video init error: $e');
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background: video or image ──────────────────────────────────────
        if (_videoReady && _videoCtrl != null)
          _CoverVideo(controller: _videoCtrl!)
        else if (widget.slide.image.isNotEmpty)
          CachedNetworkImage(
            imageUrl: widget.slide.image,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceDark),
            errorWidget: (_, __, ___) => Container(color: AppColors.surfaceDark),
          )
        else
          Container(color: AppColors.surfaceDark),

        // ── Gradient overlay ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),

        // ── Title / CTA ─────────────────────────────────────────────────────
        if (widget.slide.title.isNotEmpty || widget.slide.ctaLabel.isNotEmpty)
          Positioned(
            left: 20, right: 20, bottom: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.slide.title.isNotEmpty)
                  Text(widget.slide.title,
                      style: AppTextStyles.displayLarge.copyWith(
                          color: Colors.white, height: 1.15)),
                if (widget.slide.subtitle.isNotEmpty) ...[
                  10.height,
                  Text(widget.slide.subtitle,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70)),
                ],
                if (widget.slide.ctaLabel.isNotEmpty) ...[
                  22.height,
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: AppTextStyles.button
                          .copyWith(fontSize: 14, letterSpacing: 0.5),
                    ),
                    onPressed: widget.slide.ctaUrl.isNotEmpty
                        ? () => launchUrl(Uri.parse(widget.slide.ctaUrl),
                            mode: LaunchMode.externalApplication)
                        : null,
                    child: Text(widget.slide.ctaLabel),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ── Cover-fit video helper ───────────────────────────────────────────────────

class _CoverVideo extends StatelessWidget {
  final VideoPlayerController controller;
  const _CoverVideo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    if (videoSize == Size.zero) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (_, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final scale = (screenW / videoSize.width)
            .clamp(screenH / videoSize.height, double.infinity);
        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              width: videoSize.width * scale,
              height: videoSize.height * scale,
              child: VideoPlayer(controller),
            ),
          ),
        );
      },
    );
  }
}
