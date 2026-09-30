import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/product_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final total = mediaItems.length;
    return Column(
      children: [
        SizedBox(
          height: 360,
          child: Stack(
            children: [
              total > 0
                  ? PageView.builder(
                      controller: controller,
                      itemCount: total,
                      onPageChanged: onChanged,
                      itemBuilder: (_, i) {
                        final item = mediaItems[i];
                        if (item.type == ProductMediaType.video) {
                          return _ProductVideoItem(
                              videoUrl: item.url,
                              thumbnailUrl: item.thumbnailUrl);
                        }
                        return CachedNetworkImage(
                          imageUrl: item.url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.shimmerBase,
                            highlightColor: AppColors.shimmerHighlight,
                            child: Container(color: AppColors.shimmerBase),
                          ),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.cardBackground),
                        );
                      },
                    )
                  : Container(color: AppColors.cardBackground),
              Positioned(
                top: 12,
                right: 12,
                child: _GalleryButton(icon: Icons.fullscreen, onTap: () {}),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: _GalleryButton(
                  icon: Icons.auto_awesome,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AR Try-On coming soon!')),
                  ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              itemCount: total,
              itemBuilder: (_, i) => _ThumbnailItem(
                item: mediaItems[i],
                selected: i == currentIndex,
                onTap: () => controller.animateToPage(i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
              ),
            ),
          ),
      ],
    );
  }
}

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
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.only(right: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.textPrimary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: item.type == ProductMediaType.video
            ? Stack(fit: StackFit.expand, children: [
                if (item.thumbnailUrl != null)
                  CachedNetworkImage(
                      imageUrl: item.thumbnailUrl!, fit: BoxFit.cover)
                else
                  Container(color: Colors.black),
                const Center(
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 18)),
              ])
            : CachedNetworkImage(imageUrl: item.url, fit: BoxFit.cover),
      ),
    );
  }
}

class _ProductVideoItem extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  const _ProductVideoItem({required this.videoUrl, this.thumbnailUrl});

  @override
  State<_ProductVideoItem> createState() => _ProductVideoItemState();
}

class _ProductVideoItemState extends State<_ProductVideoItem> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ctrl =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('[Video] $e');
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      if (!_ready)
        widget.thumbnailUrl?.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
            : Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Container(color: AppColors.shimmerBase),
              ),
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
                  child: VideoPlayer(_ctrl!)),
            ),
          );
        }),
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
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              child: Icon(_muted ? Icons.volume_off : Icons.volume_up,
                  size: 16, color: Colors.white),
            ),
          ),
        ),
    ]);
  }
}
