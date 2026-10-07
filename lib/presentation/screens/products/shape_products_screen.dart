import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/shopify_service.dart';
import '../../common/widgets/fade_slide_in.dart';
import '../../common/widgets/product_card.dart';

const _kSortOptions = ['Featured', 'Price: Low to High', 'Price: High to Low'];

class ShapeProductsScreen extends StatefulWidget {
  /// Shape label, e.g. "Round" — used for the title and tag query.
  final String shapeName;

  /// Shape-specific collection handle, e.g. "round-cut-diamonds".
  /// Used as a fallback when the tag-filtered query returns nothing.
  final String collectionHandle;

  const ShapeProductsScreen({
    super.key,
    required this.shapeName,
    required this.collectionHandle,
  });

  @override
  State<ShapeProductsScreen> createState() => _ShapeProductsScreenState();
}

class _ShapeProductsScreenState extends State<ShapeProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
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
      final results = await ShopifyService.instance.fetchShapeProducts(
        shapeName: widget.shapeName,
        collectionHandle: widget.collectionHandle,
      );
      if (mounted) setState(() { _products = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Product> get _sorted {
    final list = List<Product>.from(_products);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${widget.shapeName} Diamond',
              style: AppTextStyles.headlineSmall,
            ),
            if (!_loading && _error == null)
              Text(
                '${_products.length} product${_products.length == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall,
              ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.neutral200),
            _SortBar(
            sortBy: _sortBy,
            onChanged: (v) => setState(() => _sortBy = v),
          ),
          const Divider(height: 1, color: AppColors.neutral200),
          Expanded(child: _body()),
        ],
      ),
    ),
    );
  }

  Widget _body() {
    if (_loading) return _skeleton();
    if (_error != null) return _errorView();
    if (_products.isEmpty) return _emptyView();

    final products = _sorted;
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 24,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => FadeSlideIn(
        delay: Duration(milliseconds: (i.clamp(0, 8) * 55)),
        child: ProductCard(
          product: products[i],
          onTap: () => Navigator.of(context)
              .pushNamed('/product', arguments: products[i].handle),
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
        mainAxisSpacing: 24,
        childAspectRatio: 0.65,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond_outlined, size: 48, color: AppColors.textLight),
            16.height,
            Text(
              'No ${widget.shapeName} Diamond products found',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
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
            const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textMuted),
            16.height,
            Text('Could not load products', style: AppTextStyles.headlineSmall),
            8.height,
            Text(
              _error ?? '',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            24.height,
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                color: AppColors.primary,
                child: Text(
                  'Retry',
                  style: AppTextStyles.button.copyWith(color: AppColors.textWhite),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sort bar ─────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onChanged;

  const _SortBar({required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.sort, size: 16, color: AppColors.textPrimary),
          4.width,
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: sortBy,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textPrimary),
              items: _kSortOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) { if (v != null) onChanged(v); },
            ),
          ),
        ],
      ),
    );
  }
}
