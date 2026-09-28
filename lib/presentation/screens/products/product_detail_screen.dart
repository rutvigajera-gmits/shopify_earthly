import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/providers/product_provider.dart';
import '../../../data/providers/cart_provider.dart';
import '../../../data/providers/review_provider.dart';
import '../../../data/providers/wishlist_provider.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/review_model.dart';

// ─── Size chart data ──────────────────────────────────────────────────────────

const _kSizeRows = [
  (6,  '14.6', '45.9'),
  (7,  '15.0', '47.1'),
  (8,  '15.3', '48.1'),
  (9,  '15.6', '49.0'),
  (10, '15.9', '50.0'),
  (11, '16.2', '50.9'),
  (12, '16.5', '51.8'),
  (13, '16.8', '52.8'),
  (14, '17.2', '54.0'),
  (15, '17.5', '55.0'),
  (16, '17.8', '55.9'),
  (17, '18.1', '56.9'),
  (18, '18.4', '57.8'),
  (19, '18.7', '59.1'),
  (20, '19.1', '60.0'),
  (21, '19.4', '60.9'),
  (22, '19.7', '61.9'),
  (23, '20.0', '62.8'),
  (24, '20.3', '63.8'),
  (25, '20.6', '64.7'),
  (26, '21.0', '66.0'),
  (27, '21.3', '66.9'),
  (28, '21.6', '67.9'),
  (29, '22.0', '69.1'),
  (30, '22.3', '70.1'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final String handle;
  const ProductDetailScreen({super.key, required this.handle});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _imageIndex = 0;
  Map<String, String> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductByHandle(widget.handle);
      RecentlyViewedService.addHandle(widget.handle);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onOptionChanged(String name, String value, List<ProductVariant> variants) {
    setState(() {
      _selectedOptions = {..._selectedOptions, name: value};

      // UI-only options (not in Shopify variants) — just record the selection
      final isUiOnly = variants.every((v) => !v.selectedOptions.containsKey(name));
      if (isUiOnly) return;

      // Filter selected options to only those that exist in variants
      final variantOptions = Map.fromEntries(
        _selectedOptions.entries.where(
          (e) => variants.any((v) => v.selectedOptions.containsKey(e.key)),
        ),
      );

      // Try exact match first
      final exact = variants.cast<ProductVariant?>().firstWhere(
        (v) => variantOptions.entries.every((e) => v!.selectedOptions[e.key] == e.value),
        orElse: () => null,
      );
      if (exact != null) {
        _selectedVariant = exact;
      } else {
        // Fall back to first variant with the chosen value
        final partial = variants.cast<ProductVariant?>().firstWhere(
          (v) => v!.selectedOptions[name] == value,
          orElse: () => null,
        );
        if (partial != null) {
          _selectedVariant = partial;
          _selectedOptions = {..._selectedOptions, ...partial.selectedOptions};
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loadingProduct) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final product = provider.selectedProduct;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.textPrimary),
            ),
            body: _ProductLoadError(error: provider.productError),
          );
        }

        // Initialize options when product changes
        if (_selectedVariant == null ||
            !product.variants.any((v) => v.id == _selectedVariant!.id)) {
          final first = product.variants.isNotEmpty ? product.variants.first : null;
          _selectedVariant = first;
          _selectedOptions = first != null ? Map.from(first.selectedOptions) : {};
        }
        // Ensure Metal Type always has a default selection
        if (!_selectedOptions.containsKey('Metal Type')) {
          _selectedOptions['Metal Type'] = 'Gold';
        }

        final mediaItems = product.mediaItems;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _MediaGallerySliver(
                mediaItems: mediaItems,
                currentIndex: _imageIndex,
                pageController: _pageController,
                onIndexChanged: (i) => setState(() => _imageIndex = i),
                handle: product.handle,
                productTitle: product.title,
              ),
              // Thumbnail strip
              if (mediaItems.length > 1)
                SliverToBoxAdapter(
                  child: _ThumbnailStrip(
                    mediaItems: mediaItems,
                    currentIndex: _imageIndex,
                    onTap: (i) => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _ProductDetails(
                  product: product,
                  selectedVariant: _selectedVariant,
                  selectedOptions: _selectedOptions,
                  quantity: _quantity,
                  onOptionChanged: (name, value) =>
                      _onOptionChanged(name, value, product.variants),
                  onQuantityChanged: (q) => setState(() => _quantity = q),
                  onAddToCart: () => _addToCart(product),
                  addingToCart: _addingToCart,
                ),
              ),
              SliverToBoxAdapter(
                child: _ProductReviewsSection(handle: product.handle),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addToCart(Product product) async {
    final variant = _selectedVariant ?? product.variants.firstOrNull;
    if (variant == null) return;

    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addItem(variant.id, _quantity);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }
}

// ─── Media Gallery (SliverAppBar) ────────────────────────────────────────────

class _MediaGallerySliver extends StatelessWidget {
  final List<ProductMediaItem> mediaItems;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onIndexChanged;
  final String handle;
  final String productTitle;

  const _MediaGallerySliver({
    required this.mediaItems,
    required this.currentIndex,
    required this.pageController,
    required this.onIndexChanged,
    required this.handle,
    required this.productTitle,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 440,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
        ),
      ),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlist, _) {
            final saved = wishlist.contains(handle);
            return Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: IconButton(
                icon: Icon(
                  saved ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: saved ? Colors.red : AppColors.textPrimary,
                ),
                onPressed: () => wishlist.toggle(handle),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.share, size: 18),
            color: AppColors.textPrimary,
            onPressed: () => Share.share(
              'Check out this beautiful piece from Earthly Jewels!\nhttps://earthlyjewels.co/products/$handle',
              subject: productTitle,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: mediaItems.isNotEmpty
            ? PageView.builder(
                controller: pageController,
                itemCount: mediaItems.length,
                onPageChanged: onIndexChanged,
                itemBuilder: (_, i) {
                  final item = mediaItems[i];
                  if (item.type == ProductMediaType.video) {
                    return _ProductVideoItem(
                      videoUrl: item.url,
                      thumbnailUrl: item.thumbnailUrl,
                    );
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
      ),
    );
  }
}

// ─── Inline video player for product gallery ─────────────────────────────────

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
    _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _ctrl = ctrl;
    try {
      await ctrl.initialize();
      if (!mounted) return;
      await ctrl.setLooping(true);
      await ctrl.setVolume(0);
      await ctrl.play();
      setState(() => _ready = true);
    } catch (e) {
      debugPrint('[ProductVideo] init error: $e');
    }
  }

  void _toggleMute() {
    if (_ctrl == null) return;
    setState(() => _muted = !_muted);
    _ctrl!.setVolume(_muted ? 0 : 1);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: shimmer → video
        if (!_ready)
          widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.shimmerBase,
                    highlightColor: AppColors.shimmerHighlight,
                    child: Container(color: AppColors.shimmerBase),
                  ),
                  errorWidget: (_, __, ___) =>
                      Container(color: AppColors.cardBackground),
                )
              : Shimmer.fromColors(
                  baseColor: AppColors.shimmerBase,
                  highlightColor: AppColors.shimmerHighlight,
                  child: Container(color: AppColors.shimmerBase),
                ),
        if (_ready && _ctrl != null)
          LayoutBuilder(
            builder: (_, constraints) {
              final videoSize = _ctrl!.value.size;
              if (videoSize == Size.zero) return const SizedBox.shrink();
              final scale = (constraints.maxWidth / videoSize.width)
                  .clamp(constraints.maxHeight / videoSize.height, double.infinity);
              return ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    width: videoSize.width * scale,
                    height: videoSize.height * scale,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),
              );
            },
          ),
        // Mute / unmute button
        if (_ready)
          Positioned(
            right: 12,
            bottom: 12,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _muted ? Icons.volume_off : Icons.volume_up,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Thumbnail strip ──────────────────────────────────────────────────────────

class _ThumbnailStrip extends StatelessWidget {
  final List<ProductMediaItem> mediaItems;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ThumbnailStrip({
    required this.mediaItems,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding, vertical: 12),
        itemCount: mediaItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = mediaItems[i];
          final isSelected = i == currentIndex;
          final thumbUrl = item.displayThumbnail;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 64,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.teal : AppColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: AppColors.surfaceCream),
                    errorWidget: (_, __, ___) =>
                        Container(color: AppColors.surfaceCream),
                  ),
                  if (item.isVideo)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            size: 16, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Product Details ──────────────────────────────────────────────────────────

class _ProductDetails extends StatelessWidget {
  final Product product;
  final ProductVariant? selectedVariant;
  final Map<String, String> selectedOptions;
  final int quantity;
  final void Function(String name, String value) onOptionChanged;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final bool addingToCart;

  const _ProductDetails({
    required this.product,
    required this.selectedVariant,
    required this.selectedOptions,
    required this.quantity,
    required this.onOptionChanged,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.addingToCart,
  });

  @override
  Widget build(BuildContext context) {
    // Use API/variant options, always appending Metal Type if not already present
    final opts = [
      ...product.realOptions,
      if (!product.realOptions.any((o) => o.name.toLowerCase().contains('metal')))
        const ProductOption(name: 'Metal Type', values: ['Gold', 'Rose Gold', 'Silver']),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Badge
          if (product.isMembersOnly)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: AppColors.badgeBackground,
              child: Text('MEMBERS ONLY', style: AppTextStyles.badge),
            ),

          // Title
          Text(product.title, style: AppTextStyles.displaySmall),
          const SizedBox(height: 6),

          // Price
          Row(
            children: [
              Text(
                selectedVariant != null
                    ? _formatPrice(selectedVariant!.price)
                    : 'From ${product.formattedMinPrice}',
                style: AppTextStyles.priceLarge,
              ),
              if (selectedVariant?.hasDiscount == true) ...[
                const SizedBox(width: 10),
                Text(
                  _formatPrice(selectedVariant!.compareAtPrice!),
                  style: AppTextStyles.priceStrikethrough,
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),
          Text('Inclusive of all taxes', style: AppTextStyles.bodySmall),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 20),

          // Options — one section per API option
          if (opts.isNotEmpty) ...[
            ...opts.map((opt) => _OptionSection(
              name: opt.name,
              values: opt.values,
              selectedValue: selectedOptions[opt.name] ?? '',
              onChanged: (val) => onOptionChanged(opt.name, val),
            )),
            const Divider(),
            const SizedBox(height: 20),
          ],

          // Quantity
          Text('Quantity', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          _QuantitySelector(quantity: quantity, onChanged: onQuantityChanged),

          const SizedBox(height: 28),

          // Add to Cart
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addingToCart ? null : onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.textWhite,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: const RoundedRectangleBorder(),
                elevation: 0,
              ),
              child: addingToCart
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('ADD TO BAG',
                      style: AppTextStyles.button.copyWith(color: Colors.white)),
            ),
          ),

          const SizedBox(height: 12),

          // Wishlist
          SizedBox(
            width: double.infinity,
            child: Consumer<WishlistProvider>(
              builder: (context, wishlist, _) {
                final saved = wishlist.contains(product.handle);
                return OutlinedButton.icon(
                  onPressed: () => wishlist.toggle(product.handle),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(),
                  ),
                  icon: Icon(
                    saved ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: saved ? Colors.red : AppColors.textPrimary,
                  ),
                  label: Text(
                    saved ? 'SAVED TO WISHLIST' : 'ADD TO WISHLIST',
                    style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 20),

          // Description
          if (product.description != null && product.description!.isNotEmpty) ...[
            Text('Product Details', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Text(
              product.description!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.7),
            ),
            const SizedBox(height: 24),
          ],

          const _ProductUspStrip(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatPrice(String raw) {
    final price = double.tryParse(raw) ?? 0;
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }
}

// ─── Customize header button ──────────────────────────────────────────────────

// ─── Option section ───────────────────────────────────────────────────────────

class _OptionSection extends StatelessWidget {
  final String name;
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _OptionSection({
    required this.name,
    required this.values,
    required this.selectedValue,
    required this.onChanged,
  });

  bool get _isMetal => name.toLowerCase().contains('metal');
  bool get _isSize  => name.toLowerCase() == 'size';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
                  children: [
                    TextSpan(text: name),
                    if (!_isMetal && !_isSize && selectedValue.isNotEmpty) ...[
                      const TextSpan(text: ':  '),
                      TextSpan(
                        text: selectedValue,
                        style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 14, color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isSize) const _SizeChartLink(),
            ],
          ),
          const SizedBox(height: 10),
          if (_isMetal)
            _MetalTypePicker(values: values, selected: selectedValue, onChanged: onChanged)
          else if (_isSize)
            _SizeDropdown(values: values, selected: selectedValue, onChanged: onChanged)
          else
            _ChipPicker(values: values, selected: selectedValue, onChanged: onChanged),
          if (_isSize) ...[
            const SizedBox(height: 6),
            Text(
              'Price and weight will changes as per the size',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Chip option picker ───────────────────────────────────────────────────────

class _ChipPicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChipPicker({required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              v,
              style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Size dropdown ────────────────────────────────────────────────────────────

class _SizeDropdown extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _SizeDropdown({required this.values, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final effectiveValue = values.contains(selected) ? selected : (values.isNotEmpty ? values.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isExpanded: true,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ─── Metal type color picker ──────────────────────────────────────────────────

class _MetalTypePicker extends StatelessWidget {
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetalTypePicker({required this.values, required this.selected, required this.onChanged});

  Color _color(String v) {
    final l = v.toLowerCase();
    if (l.contains('rose') || l.contains('pink')) {
      return const Color(0xFFB87B6A);
    }
    if (l.contains('white') || l.contains('platinum') || l.contains('silver')) {
      return const Color(0xFFCECECE);
    }
    // yellow gold / gold / default
    return const Color(0xFFD4AF37);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((v) {
        final isSelected = v == selected;
        return GestureDetector(
          onTap: () => onChanged(v),
          child: Container(
            margin: const EdgeInsets.only(right: 14),
            // Outer ring: visible only when selected
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _color(v),
                // Subtle inner shadow for metallic depth
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Size chart link ──────────────────────────────────────────────────────────

class _SizeChartLink extends StatelessWidget {
  const _SizeChartLink();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _SizeChartSheet(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.straighten_outlined, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'Size chart',
            style: AppTextStyles.bodySmall.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textSecondary,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Size chart bottom sheet ──────────────────────────────────────────────────

class _SizeChartSheet extends StatelessWidget {
  const _SizeChartSheet();

  @override
  Widget build(BuildContext context) {
    // Split into two columns: 6-18 (13 rows) and 19-30 (12 rows)
    const mid = 13;
    final leftRows  = _kSizeRows.sublist(0, mid);
    final rightRows = _kSizeRows.sublist(mid);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Ring Size Chart',
                        style: AppTextStyles.headlineLarge.copyWith(fontSize: 22)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Table content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _SizeTable(rows: leftRows)),
                      const SizedBox(width: 8),
                      Expanded(child: _SizeTable(rows: rightRows)),
                    ],
                  ),
                ),
              ),
              // Bottom button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(),
                        elevation: 0,
                      ),
                      child: Text(
                        'How to Measure?',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SizeTable extends StatelessWidget {
  final List<(int, String, String)> rows;
  const _SizeTable({required this.rows});

  static const _headerStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF444444), height: 1.4);
  static const _cellStyle = TextStyle(
      fontSize: 11, color: Color(0xFF333333));

  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text,
          style: isHeader ? _headerStyle : _cellStyle,
          textAlign: TextAlign.center,
          maxLines: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppColors.border, width: 0.5),
      columnWidths: const {
        0: FlexColumnWidth(0.8),
        1: FlexColumnWidth(1.1),
        2: FlexColumnWidth(1.3),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: AppColors.surfaceWarm),
          children: [
            _cell('Ring\nSize', isHeader: true),
            _cell('Diameter\n(in mm)', isHeader: true),
            _cell('Circum-\nference\n(in mm)', isHeader: true),
          ],
        ),
        ...rows.map((r) => TableRow(
          children: [
            _cell('${r.$1}'),
            _cell(r.$2),
            _cell(r.$3),
          ],
        )),
      ],
    );
  }
}

// ─── Quantity selector ────────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 48,
            child: Text('$quantity',
                textAlign: TextAlign.center, style: AppTextStyles.labelLarge),
          ),
          _QtyButton(icon: Icons.add, onTap: () => onChanged(quantity + 1)),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.textLight : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─── USP strip ────────────────────────────────────────────────────────────────

class _ProductUspStrip extends StatelessWidget {
  const _ProductUspStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: const Column(
        children: [
          _UspRow(icon: Icons.verified_outlined,         label: 'Certified Lab-Grown Diamond'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.local_shipping_outlined,   label: 'Free Insured Shipping'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.replay_outlined,           label: '15-Day Easy Returns'),
          SizedBox(height: 12),
          _UspRow(icon: Icons.workspace_premium_outlined, label: 'Lifetime Warranty'),
        ],
      ),
    );
  }
}

class _UspRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UspRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

// ─── Product Load Error ───────────────────────────────────────────────────────

class _ProductLoadError extends StatelessWidget {
  final String? error;
  const _ProductLoadError({this.error});

  @override
  Widget build(BuildContext context) {
    final isTokenError = error != null &&
        (error!.contains('401') ||
            error!.contains('403') ||
            error!.contains('Unauthorized') ||
            error!.contains('GraphQL'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 18),
                SizedBox(width: 8),
                Text('Product could not load',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Color(0xFFE65100), fontSize: 13)),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                color: const Color(0xFFFFF0F0),
                child: Text('Error: $error',
                    style: const TextStyle(fontSize: 11, color: Colors.red, height: 1.4)),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              isTokenError
                  ? 'Fix: Your Shopify Storefront API token is invalid.\n\n'
                      '1. Open: earthlyjewels.co/admin/settings/apps\n'
                      '2. Click "Develop apps"\n'
                      '3. Open your app → Configuration tab\n'
                      '4. Enable all Storefront API scopes → Save\n'
                      '5. API credentials tab → Copy token\n'
                      '6. Paste in lib/core/constants/app_constants.dart'
                  : 'Product data comes from Shopify Storefront API.\n'
                      'Check your internet connection and API token.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reviews section ──────────────────────────────────────────────────────────

class _ProductReviewsSection extends StatefulWidget {
  final String handle;
  const _ProductReviewsSection({required this.handle});

  @override
  State<_ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<_ProductReviewsSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ReviewProvider>().loadProductReviews(widget.handle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, rp, _) {
        final loading = rp.isLoadingProduct(widget.handle);
        final summary = rp.productReviews(widget.handle);
        final reviews = summary?.reviews ?? [];
        final total   = summary?.totalCount ?? 0;
        final avg     = summary?.averageRating ?? 0;

        if (loading) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
              ),
            ),
          );
        }

        if (total == 0) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: _ReviewSummaryHeader(
                summary: ReviewSummary(averageRating: avg, totalCount: total, reviews: reviews),
              ),
            ),
            const SizedBox(height: 16),
            ...reviews.map((r) => _ReviewCard(review: r)),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}

class _ReviewSummaryHeader extends StatelessWidget {
  final ReviewSummary summary;
  const _ReviewSummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          summary.averageRating.toStringAsFixed(1),
          style: AppTextStyles.displaySmall.copyWith(fontSize: 36, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StarRow(rating: summary.averageRating, size: 18),
            const SizedBox(height: 4),
            Text(
              '${summary.totalCount} ${summary.totalCount == 1 ? 'review' : 'reviews'}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRow(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              if (review.formattedDate.isNotEmpty)
                Text(review.formattedDate,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          if (review.title != null && review.title!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.title!,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 6),
          Text(review.body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 10),
          Text(review.reviewerName,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half   = !filled && i < rating;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: size,
          color: AppColors.gold,
        );
      }),
    );
  }
}
