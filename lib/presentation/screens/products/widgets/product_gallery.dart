import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:video_player/video_player.dart';
import '../../../../component/loader_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';
import '../../../common/widgets/auto_scroll_slider.dart';

class ProductGallerySection extends StatelessWidget {
  final List<ProductMediaItem> mediaItems;
  final int currentIndex;
  final PageController controller;
  final ValueChanged<int> onChanged;

  const ProductGallerySection({
    super.key,
    required this.mediaItems,
    required this.currentIndex,
    required this.controller,
    required this.onChanged,
  });

  Widget _buildItem(BuildContext context, int i) {
    final item = mediaItems[i];

    if (item.type == ProductMediaType.video) {
      return _ProductVideoItem(
        key: ValueKey('video-$i-${item.url}'),
        videoUrl: item.url,
        thumbnailUrl: item.thumbnailUrl,
        pageIndex: i,
        pageController: controller,
        isInitiallyActive: i == currentIndex,
      );
    }

    // externalVideo (YouTube/Vimeo) — show thumbnail only, no native playback.
    if (item.type == ProductMediaType.externalVideo) {
      if (item.thumbnailUrl?.isNotEmpty == true) {
        return CachedNetworkImage(
          imageUrl: item.thumbnailUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.surfaceCream),
          errorWidget: (_, __, ___) => Container(color: AppColors.cardBackground),
        );
      }
      return Container(color: AppColors.cardBackground);
    }

    if (item.url.isEmpty) return Container(color: AppColors.cardBackground);

    return CachedNetworkImage(
      imageUrl: item.url,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surfaceCream),
      errorWidget: (_, __, ___) => Container(color: AppColors.cardBackground),
    )
        .animate(key: ValueKey('gallery-img-$i'))
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(1.03, 1.03),
          end: const Offset(1.0, 1.0),
          duration: 280.ms,
          curve: Curves.easeOut,
        );
  }

  @override
  Widget build(BuildContext context) {
    final total = mediaItems.length;

    return Column(
      children: [
        SizedBox(
          height: 360,
          child: Stack(
            children: [
              AutoScrollSlider(
                controller: controller,
                currentIndex: currentIndex,
                itemCount: total,
                onPageChanged: onChanged,
                canAdvance: (i) =>
                    i < mediaItems.length &&
                    mediaItems[i].type != ProductMediaType.video,
                itemBuilder: (ctx, i) => _buildItem(ctx, i),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _GalleryButton(icon: Icons.fullscreen, onTap: () {}),
              ),
              // Positioned(
              //   bottom: 12,
              //   right: 12,
              //   child: _GalleryButton(
              //     icon: Icons.auto_awesome,
              //     onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('AR Try-On coming soon!')),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
        if (total > 1)
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              itemCount: total,
              itemBuilder: (_, i) => _ThumbnailItem(
                item: mediaItems[i],
                selected: i == currentIndex,
                onTap: () => controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              )
                  .animate(
                    key: ValueKey('thumb-$i'),
                    delay: Duration(milliseconds: 80 + i * 55),
                  )
                  .fadeIn(duration: 240.ms, curve: Curves.easeOut)
                  .slideX(
                    begin: 0.35,
                    end: 0,
                    duration: 240.ms,
                    curve: Curves.easeOut,
                  ),
            ),
          ),
      ],
    );
  }
}

// ─── Gallery Button ───────────────────────────────────────────────────────────

class _GalleryButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _GalleryButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─── Thumbnail Strip Item ─────────────────────────────────────────────────────

class _ThumbnailItem extends StatelessWidget {
  final ProductMediaItem item;
  final bool selected;
  final VoidCallback onTap;
  const _ThumbnailItem(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 52,
        height: 52,
        margin: const EdgeInsets.only(right: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
            width: selected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: item.isVideo
            ? Stack(fit: StackFit.expand, children: [
                if (item.thumbnailUrl?.isNotEmpty == true)
                  CachedNetworkImage(
                    imageUrl: item.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ).cornerRadiusWithClipRRect(4).paddingSymmetric(horizontal: 0)
                else
                  Container(color: Colors.black),
                const Center(
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              ])
            : CachedNetworkImage(imageUrl: item.url, fit: BoxFit.cover)
                .cornerRadiusWithClipRRect(4)
                .paddingSymmetric(horizontal: 0),
      ),
    );
  }
}

// ─── Native Video Player Item ─────────────────────────────────────────────────

class _ProductVideoItem extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final int pageIndex;
  final PageController pageController;
  final bool isInitiallyActive;

  const _ProductVideoItem({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.pageIndex,
    required this.pageController,
    required this.isInitiallyActive,
  });

  @override
  State<_ProductVideoItem> createState() => _ProductVideoItemState();
}

class _ProductVideoItemState extends State<_ProductVideoItem> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _initializing = false;
  bool _muted = true;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(_onScroll);

    if (widget.isInitiallyActive) {
      _wasActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _init();
      });
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onScroll);
    _ctrl?.dispose();
    super.dispose();
  }

  void _onScroll() => _checkActive();

  void _checkActive() {
    if (!mounted) return;
    if (!widget.pageController.hasClients) return;

    final pageValue = widget.pageController.page;
    if (pageValue == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkActive());
      return;
    }

    final isActive = pageValue.round() == widget.pageIndex;

    if (isActive && !_wasActive) {
      _wasActive = true;
      if (_ready) {
        _ctrl?.play();
      } else {
        _init();
      }
    } else if (!isActive && _wasActive) {
      _wasActive = false;
      _ctrl?.pause();
    }
  }

  Future<void> _init() async {
    if (_initializing || _ready) return;
    if (mounted) setState(() => _initializing = true);

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      if (mounted) {
        setState(() {
          _ready = true;
          _initializing = false;
        });
      }
    } catch (e) {
      debugPrint('[Video] error on page ${widget.pageIndex}: $e');
      if (mounted) setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      widget.thumbnailUrl?.isNotEmpty == true
          ? CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceCream),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.cardBackground),
            )
          : Container(color: Colors.black87),

      if (_ready && _ctrl != null)
        LayoutBuilder(builder: (_, c) {
          final vs = _ctrl!.value.size;
          if (vs == Size.zero) return const SizedBox.shrink();
          final scale = (c.maxWidth / vs.width)
              .clamp(c.maxHeight / vs.height, double.infinity);
          return ClipRect(
            child: OverflowBox(
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: SizedBox(
                width: vs.width * scale,
                height: vs.height * scale,
                child: VideoPlayer(_ctrl!),
              ),
            ),
          );
        }),

      if (_initializing && !_ready)
        const Center(child: LoaderWidget(size: 36, color: Colors.white)),

      if (_ready)
        Positioned(
          right: 12,
          bottom: 12,
          child: GestureDetector(
            onTap: () {
              setState(() => _muted = !_muted);
              _ctrl?.setVolume(_muted ? 0 : 1);
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
    ]);
  }
}
