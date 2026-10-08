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
            height: 350,
            viewportFraction: 1.0,
            autoPlay: slides.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOut,
            onPageChanged: (i, _) => setState(() => _index = i),
          ),
          items: List.generate(
            slides.length,
            (i) => _HeroBannerSlide(
              key: ValueKey(i),
              slide: slides[i],
              isActive: i == _index,
            ),
          ),
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

// ─── Slide widget ─────────────────────────────────────────────────────────────

class _HeroBannerSlide extends StatefulWidget {
  final HeroBannerSlide slide;
  final bool isActive;
  const _HeroBannerSlide({
    super.key,
    required this.slide,
    required this.isActive,
  });

  @override
  State<_HeroBannerSlide> createState() => _HeroBannerSlideState();
}

class _HeroBannerSlideState extends State<_HeroBannerSlide>
    with TickerProviderStateMixin {
  // Video
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  // Ken Burns — slow zoom on image background
  late final AnimationController _kb;
  late final Animation<double> _kbScale;

  // Staggered content entrance
  late final AnimationController _content;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _subOpacity;
  late final Animation<Offset> _subOffset;
  late final Animation<double> _ctaOpacity;
  late final Animation<Offset> _ctaOffset;

  static const _slideBegin = Offset(0, 0.22);

  @override
  void initState() {
    super.initState();

    // Ken Burns: 1.0 → 1.08 over 6 seconds
    _kb = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    _kbScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _kb, curve: Curves.easeOut),
    );

    // Staggered entrance: total 1200 ms
    _content = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleOpacity = _intervalFade(0.00, 0.50);
    _titleOffset  = _intervalSlide(0.00, 0.50);
    _subOpacity   = _intervalFade(0.18, 0.68);
    _subOffset    = _intervalSlide(0.18, 0.68);
    _ctaOpacity   = _intervalFade(0.36, 0.86);
    _ctaOffset    = _intervalSlide(0.36, 0.86);

    if (widget.isActive) _activate();
    if (widget.slide.hasVideo) _initVideo();
  }

  Animation<double> _intervalFade(double begin, double end) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _content,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );

  Animation<Offset> _intervalSlide(double begin, double end) =>
      Tween<Offset>(begin: _slideBegin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _content,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );

  void _activate() {
    _kb.forward(from: 0);
    _content.forward(from: 0);
  }

  @override
  void didUpdateWidget(_HeroBannerSlide old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _activate();
  }

  Future<void> _initVideo() async {
    final ctrl =
        VideoPlayerController.networkUrl(Uri.parse(widget.slide.videoUrl));
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
    _kb.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ────────────────────────────────────────────────────
          if (_videoReady && _videoCtrl != null)
            _CoverVideo(controller: _videoCtrl!)
          else if (widget.slide.image.isNotEmpty)
            AnimatedBuilder(
              animation: _kbScale,
              builder: (_, child) => Transform.scale(
                scale: _kbScale.value,
                child: child,
              ),
              child: CachedNetworkImage(
                imageUrl: widget.slide.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) =>
                    Container(color: AppColors.surfaceDark),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.surfaceDark),
              ),
            )
          else
            Container(color: AppColors.surfaceDark),

          // ── Gradient overlay ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.62),
                ],
                stops: const [0.25, 1.0],
              ),
            ),
          ),

          // ── Animated content ──────────────────────────────────────────────
          if (widget.slide.title.isNotEmpty ||
              widget.slide.ctaLabel.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.slide.title.isNotEmpty)
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleOffset,
                        child: Text(
                          widget.slide.title,
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  if (widget.slide.subtitle.isNotEmpty) ...[
                    10.height,
                    FadeTransition(
                      opacity: _subOpacity,
                      child: SlideTransition(
                        position: _subOffset,
                        child: Text(
                          widget.slide.subtitle,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white70),
                        ),
                      ),
                    ),
                  ],
                  if (widget.slide.ctaLabel.isNotEmpty) ...[
                    22.height,
                    FadeTransition(
                      opacity: _ctaOpacity,
                      child: SlideTransition(
                        position: _ctaOffset,
                        child: ElevatedButton(
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
                              ? () => launchUrl(
                                    Uri.parse(widget.slide.ctaUrl),
                                    mode: LaunchMode.externalApplication,
                                  )
                              : null,
                          child: Text(widget.slide.ctaLabel),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Cover-fit video ──────────────────────────────────────────────────────────

class _CoverVideo extends StatelessWidget {
  final VideoPlayerController controller;
  const _CoverVideo({required this.controller});

  @override
  Widget build(BuildContext context) {
    final videoSize = controller.value.size;
    if (videoSize == Size.zero) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (_, constraints) {
        final scale = (constraints.maxWidth / videoSize.width)
            .clamp(constraints.maxHeight / videoSize.height, double.infinity);
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
