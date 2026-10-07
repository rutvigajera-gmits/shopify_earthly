import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/shopify_service.dart';
import '../../common/widgets/fade_slide_in.dart';
import '../../common/widgets/product_card.dart';

const _kShapes = [
  ('Round',    'assets/icons/Round.svg'),
  ('Oval',     'assets/icons/Oval.svg'),
  ('Pear',     'assets/icons/Pear.svg'),
  ('Marquise', 'assets/icons/Marquise.svg'),
  ('Cushion',  'assets/icons/Cushion.svg'),
  ('Princess', 'assets/icons/Princess.svg'),
  ('Emerald',  'assets/icons/Emerald.svg'),
  ('Heart',    'assets/icons/Heart.svg'),
  ('Asscher',  'assets/icons/Asscher.svg'),
  ('Radiant',  'assets/icons/Radiant.svg'),
];

const _kSortOptions = ['Featured', 'Price: Low to High', 'Price: High to Low'];

class DesignerRingsCollectionScreen extends StatefulWidget {
  final String collectionTitle;
  final String collectionHandle;
  final String collectionImageUrl;
  final bool showShapeFilter;

  const DesignerRingsCollectionScreen({
    super.key,
    required this.collectionTitle,
    required this.collectionHandle,
    required this.collectionImageUrl,
    this.showShapeFilter = true,
  });

  @override
  State<DesignerRingsCollectionScreen> createState() =>
      _DesignerRingsCollectionScreenState();
}

class _DesignerRingsCollectionScreenState
    extends State<DesignerRingsCollectionScreen> {
  List<Product> _allProducts = [];
  bool _loading = true;
  String? _error;
  String? _selectedShape;
  String _sortBy = 'Featured';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final col = await ShopifyService.instance.fetchCollectionByHandle(
        widget.collectionHandle,
        productCount: 60,
      );
      if (mounted) {
        setState(() {
          _allProducts = col?.products ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  List<Product> get _filtered {
    var list = _selectedShape == null
        ? List<Product>.from(_allProducts)
        : _allProducts.where((p) {
            final shape = _selectedShape!.toLowerCase();
            return p.tags.any((t) =>
                t.toLowerCase() == '$shape-diamond' ||
                t.toLowerCase().contains(shape));
          }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => (double.tryParse(a.minPrice) ?? 0)
            .compareTo(double.tryParse(b.minPrice) ?? 0));
      case 'Price: High to Low':
        list.sort((a, b) => (double.tryParse(b.minPrice) ?? 0)
            .compareTo(double.tryParse(a.minPrice) ?? 0));
    }
    return list;
  }

  void _onShapeTap(String shape) {
    setState(() {
      _selectedShape = _selectedShape == shape ? null : shape;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              collectionTitle: widget.collectionTitle,
              onBack: () => Navigator.of(context).pop(),
              onCartTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.cart),
            ),

            // ── Collection banner ─────────────────────────────────────────
            _CollectionBanner(
              title: widget.collectionTitle,
              imageUrl: widget.collectionImageUrl,
            ),

            // ── Explore Diamond Shapes — shown only for ring collections ──
            if (widget.showShapeFilter) ...[
              _ShapesRow(
                selectedShape: _selectedShape,
                onTap: _onShapeTap,
              ),
              const Divider(height: 1, color: AppColors.neutral200),
            ],

            // ── Sort / count bar ──────────────────────────────────────────
            _SortBar(
              sortBy: _sortBy,
              count: _loading ? null : filtered.length,
              onChanged: (v) => setState(() => _sortBy = v),
            ),

            const Divider(height: 1, color: AppColors.neutral200),

            // ── Products grid ─────────────────────────────────────────────
            Expanded(child: _buildBody(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Product> products) {
    if (_loading) return _skeleton();
    if (_error != null) return _errorView();
    if (products.isEmpty) return _emptyView();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding,
          AppConstants.horizontalPadding,
          AppConstants.horizontalPadding,
          AppConstants.horizontalPadding + 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => FadeSlideIn(
        delay: Duration(milliseconds: (i.clamp(0, 8) * 55)),
        child: ProductCard(
          product: products[i],
          onTap: () => Navigator.of(context)
              .pushNamed(AppRoutes.product, arguments: products[i].handle),
        ),
      ),
    );
  }

  Widget _skeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 20,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _emptyView() {
    final msg = _selectedShape != null
        ? 'No ${_selectedShape!} Diamond products in ${widget.collectionTitle}'
        : 'No products found in ${widget.collectionTitle}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_outlined,
                size: 48, color: AppColors.textLight),
            16.height,
            Text(msg,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            if (_selectedShape != null) ...[
              20.height,
              GestureDetector(
                onTap: () => setState(() => _selectedShape = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.teal),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Clear filter',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.teal)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 48, color: AppColors.textMuted),
            16.height,
            Text('Could not load products', style: AppTextStyles.headlineSmall),
            8.height,
            Text(_error ?? '',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            24.height,
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                color: AppColors.primary,
                child: Text('Retry',
                    style: AppTextStyles.button
                        .copyWith(color: AppColors.textWhite)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  final String collectionTitle;
  final VoidCallback onBack;
  final VoidCallback onCartTap;

  const _AppBar({
    required this.collectionTitle,
    required this.onBack,
    required this.onCartTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: onBack,
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Collections',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textMuted),
                Flexible(
                  child: Text(
                    collectionTitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined,
                color: AppColors.textPrimary, size: 22),
            onPressed: onCartTap,
          ),
        ],
      ),
    );
  }
}

// ─── Collection banner ─────────────────────────────────────────────────────────

class _CollectionBanner extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _CollectionBanner({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceCream),
              errorWidget: (_, __, ___) =>
                  Container(color: AppColors.surfaceCream),
            )
          else
            Container(color: AppColors.surfaceCream),

          // dark gradient at bottom for text legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.62),
                ],
                stops: const [0.35, 1.0],
              ),
            ),
          ),

          Positioned(
            left: AppConstants.horizontalPadding,
            bottom: 18,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Collections',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.4,
                  ),
                ),
                4.height,
                Text(
                  title,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shapes row ────────────────────────────────────────────────────────────────

class _ShapesRow extends StatelessWidget {
  final String? selectedShape;
  final ValueChanged<String> onTap;

  const _ShapesRow({required this.selectedShape, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppConstants.horizontalPadding, 14,
                AppConstants.horizontalPadding, 10),
            child: Text(
              'Explore Diamond Shapes',
              style: AppTextStyles.headlineSmall.copyWith(fontSize: 14),
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              itemCount: _kShapes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final (name, svg) = _kShapes[i];
                final selected = selectedShape == name;
                return GestureDetector(
                  onTap: () => onTap(name),
                  child: SizedBox(
                    width: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.teal.withValues(alpha: 0.10)
                                : AppColors.surfaceCream,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selected
                                  ? AppColors.teal
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            svg,
                            colorFilter: ColorFilter.mode(
                              selected
                                  ? AppColors.teal
                                  : AppColors.textSecondary,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        5.height,
                        Text(
                          name,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: selected
                                ? AppColors.teal
                                : AppColors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 0.3,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          10.height,
        ],
      ),
    );
  }
}

// ─── Sort bar ──────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final String sortBy;
  final int? count;
  final ValueChanged<String> onChanged;

  const _SortBar({
    required this.sortBy,
    required this.count,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Row(
        children: [
          if (count != null)
            Text(
              '$count product${count == 1 ? '' : 's'}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          const Spacer(),
          const Icon(Icons.sort, size: 16, color: AppColors.textPrimary),
          4.width,
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: AppColors.textPrimary),
              items: _kSortOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
