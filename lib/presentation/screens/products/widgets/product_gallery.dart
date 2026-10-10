import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
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

  void _openFullscreenGallery(BuildContext context, int startIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, __, ___) => _FullScreenGallery(
          mediaItems: mediaItems,
          initialIndex: startIndex,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int i) {
    final item = mediaItems[i];

    if (item.type == ProductMediaType.video) {
      return GestureDetector(
        onTap: () => _openFullscreenGallery(context, i),
        child: _ProductVideoItem(
          key: ValueKey('video-$i-${item.url}'),
          videoUrl: item.url,
          thumbnailUrl: item.thumbnailUrl,
          isActive: i == currentIndex,
        ),
      );
    }

    // externalVideo — show thumbnail, tap opens fullscreen gallery
    if (item.type == ProductMediaType.externalVideo) {
      if (item.thumbnailUrl?.isNotEmpty == true) {
        return GestureDetector(
          onTap: () => _openFullscreenGallery(context, i),
          child: CachedNetworkImage(
            imageUrl: item.thumbnailUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.surfaceCream),
            errorWidget: (_, __, ___) =>
                Container(color: AppColors.cardBackground),
          ),
        );
      }
      return Container(color: AppColors.cardBackground);
    }

    if (item.url.isEmpty) return Container(color: AppColors.cardBackground);

    // Standard image — tap opens fullscreen gallery with zoom
    return GestureDetector(
      onTap: () => _openFullscreenGallery(context, i),
      child: CachedNetworkImage(
        imageUrl: item.url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.surfaceCream),
        errorWidget: (_, __, ___) =>
            Container(color: AppColors.cardBackground),
      )
          .animate(key: ValueKey('gallery-img-$i'))
          .fadeIn(duration: 280.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(1.03, 1.03),
            end: const Offset(1.0, 1.0),
            duration: 280.ms,
            curve: Curves.easeOut,
          ),
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
                child: _GalleryButton(
                  icon: Icons.fullscreen,
                  onTap: () => _openFullscreenGallery(context, currentIndex),
                ),
              ),
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

// ─── Full-Screen Gallery ──────────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<ProductMediaItem> mediaItems;
  final int initialIndex;

  const _FullScreenGallery(
      {required this.mediaItems, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _current;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.mediaItems;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (items.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_current + 1} / ${items.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: _ctrl,
        itemCount: items.length,
        scrollPhysics: const BouncingScrollPhysics(),
        onPageChanged: (i) => setState(() => _current = i),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        builder: (ctx, index) {
          final item = items[index];

          if (item.isVideo) {
            final thumb = item.thumbnailUrl ?? '';
            return PhotoViewGalleryPageOptions.customChild(
              childSize: MediaQuery.of(ctx).size,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered,
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (thumb.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: thumb,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      )
                    else
                      Container(color: Colors.black54),
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white54, size: 72),
                  ],
                ),
              ),
            );
          }

          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(item.url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: Colors.white38, size: 64),
            ),
          );
        },
        loadingBuilder: (_, event) => Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            value: event?.expectedTotalBytes == null
                ? null
                : (event!.cumulativeBytesLoaded / event.expectedTotalBytes!),
          ),
        ),
      ),
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
  // Driven by currentIndex from the parent — no pageController listener needed.
  final bool isActive;

  const _ProductVideoItem({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.isActive,
  });

  @override
  State<_ProductVideoItem> createState() => _ProductVideoItemState();
}

class _ProductVideoItemState extends State<_ProductVideoItem> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _initializing = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _init();
      });
    }
  }

  @override
  void didUpdateWidget(_ProductVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _ready ? _ctrl?.play() : _init();
    } else {
      _ctrl?.pause();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
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
      if (widget.isActive) await ctrl.play();
      if (mounted) {
        setState(() {
          _ready = true;
          _initializing = false;
        });
      }
    } catch (e) {
      debugPrint('[Video] init error: $e');
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
