import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/review_provider.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/services/shopify_service.dart';
import '../../common/widgets/product_card.dart';
import 'widgets/product_gallery.dart';
import 'widgets/product_info_section.dart';
import 'widgets/product_customize_section.dart';
import 'widgets/product_actions_section.dart';
import 'widgets/product_ratings_grid.dart';
import 'widgets/product_accordions.dart';

class ProductDetailScreen extends StatefulWidget {
  final String handle;
  const ProductDetailScreen({super.key, required this.handle});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  final _pincodeController = TextEditingController();
  int _imageIndex = 0;
  Map<String, String> _selectedOptions = {};
  ProductVariant? _selectedVariant;
  bool _addingToCart = false;
  List<Product> _relatedProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductByHandle(widget.handle);
      context.read<ReviewProvider>().loadProductReviews(widget.handle);
      RecentlyViewedService.addHandle(widget.handle);
      _loadRelatedProducts();
    });
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final products =
          await ShopifyService.instance.fetchBestSellingProducts(first: 10);
      if (mounted) {
        setState(() {
          _relatedProducts = products
              .where((p) => p.handle != widget.handle)
              .take(6)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onOptionChanged(
      String name, String value, List<ProductVariant> variants) {
    setState(() {
      _selectedOptions = {..._selectedOptions, name: value};
      final isUiOnly =
          variants.every((v) => !v.selectedOptions.containsKey(name));
      if (isUiOnly) return;
      final variantOptions = Map.fromEntries(
        _selectedOptions.entries.where(
            (e) => variants.any((v) => v.selectedOptions.containsKey(e.key))),
      );
      final exact = variants.cast<ProductVariant?>().firstWhere(
            (v) => variantOptions.entries
                .every((e) => v!.selectedOptions[e.key] == e.value),
            orElse: () => null,
          );
      if (exact != null) {
        _selectedVariant = exact;
      } else {
        final partial = variants.cast<ProductVariant?>().firstWhere(
              (v) => v!.selectedOptions[name] == value,
              orElse: () => null,
            );
        if (partial != null) {
          _selectedVariant = partial;
          _selectedOptions = {
            ..._selectedOptions,
            ...partial.selectedOptions
          };
        }
      }
    });
  }

  Future<void> _addToCart(Product product) async {
    final variant = _selectedVariant ?? product.variants.firstOrNull;
    if (variant == null) return;
    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addItem(variant.id, 1);
      if (mounted) {
        Navigator.of(context).pushNamed(AppRoutes.cart);
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: AppColors.textPrimary),
      ),
      title: Text('EARTHLY',
          style: AppTextStyles.button.copyWith(fontSize: 14, letterSpacing: 3)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border,
              size: 22, color: AppColors.textPrimary),
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.wishlist),
        ),
        Consumer<CartProvider>(
          builder: (context, cart, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined,
                    size: 22, color: AppColors.textPrimary),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.cart),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: AppColors.badge,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildSku(Product product) {
    final prefix = product.handle.split('-').take(3).join('-');
    final optStr = _selectedOptions.entries
        .where((e) => e.key != 'Metal Type' && e.value.isNotEmpty)
        .map((e) => e.value.toLowerCase().replaceAll(' ', ''))
        .join('-');
    return optStr.isNotEmpty ? '$prefix-$optStr' : prefix;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loadingProduct) {
          return Scaffold(
              appBar: _buildAppBar(),
              body: const Center(child: CircularProgressIndicator()));
        }
        final product = provider.selectedProduct;
        if (product == null) {
          return Scaffold(
              appBar: _buildAppBar(),
              body: _ProductLoadError(error: provider.productError));
        }

        if (_selectedVariant == null ||
            !product.variants.any((v) => v.id == _selectedVariant!.id)) {
          final first = product.variants.firstOrNull;
          _selectedVariant = first;
          _selectedOptions =
              first != null ? Map.from(first.selectedOptions) : {};
        }
        if (!_selectedOptions.containsKey('Metal Type')) {
          _selectedOptions['Metal Type'] = 'Yellow Gold';
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(),
          bottomNavigationBar: _StickyBottomBar(
            product: product,
            selectedOptions: _selectedOptions,
            selectedVariant: _selectedVariant,
            addingToCart: _addingToCart,
            onAddToCart: () => _addToCart(product),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProductGallerySection(
                  mediaItems: product.mediaItems,
                  currentIndex: _imageIndex,
                  controller: _pageController,
                  onChanged: (i) => setState(() => _imageIndex = i),
                ),
              ),
              SliverToBoxAdapter(
                child: ProductInfoSection(
                    product: product, selectedVariant: _selectedVariant),
              ),
              SliverToBoxAdapter(
                child: ProductCustomizeSection(
                  product: product,
                  selectedOptions: _selectedOptions,
                  onOptionChanged: (name, val) =>
                      _onOptionChanged(name, val, product.variants),
                ),
              ),
              SliverToBoxAdapter(
                child: ProductActionButtons(
                    onBeginOrder: () => _addToCart(product),
                    addingToCart: _addingToCart),
              ),
              SliverToBoxAdapter(
                child: ProductDeliverySection(
                    pincodeController: _pincodeController),
              ),
              const SliverToBoxAdapter(
                  child: ProductConsultationBanner()),
              const SliverToBoxAdapter(child: ProductPickDiamondCard()),
              const SliverToBoxAdapter(child: ProductRatingsGrid()),
              SliverToBoxAdapter(
                child: ProductAccordionsSection(
                    product: product, sku: _buildSku(product)),
              ),
              if (_relatedProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: _YouMayAlsoLikeSection(
                    products: _relatedProducts,
                    onTap: (h) => Navigator.of(context)
                        .pushNamed(AppRoutes.product, arguments: h),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }
}

// ─── You May Also Like ────────────────────────────────────────────────────────

class _YouMayAlsoLikeSection extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<String> onTap;
  const _YouMayAlsoLikeSection(
      {required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: AppColors.border),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppConstants.horizontalPadding, 20,
            AppConstants.horizontalPadding, 12),
        child: Text('You may also like', style: AppTextStyles.headlineSmall),
      ),
      SizedBox(
        height: 230,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final p = products[i];
            return ProductCard(
              width: 150,
              product: p,
              onTap: () => onTap(p.handle),
            );
          },
        ),
      ),
      const SizedBox(height: 20),
    ]);
  }
}

// ─── Sticky Bottom Bar ────────────────────────────────────────────────────────

class _StickyBottomBar extends StatelessWidget {
  final Product product;
  final Map<String, String> selectedOptions;
  final ProductVariant? selectedVariant;
  final bool addingToCart;
  final VoidCallback onAddToCart;

  const _StickyBottomBar({
    required this.product,
    required this.selectedOptions,
    required this.selectedVariant,
    required this.addingToCart,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final price = selectedVariant != null
        ? FormatUtils.formatRsPrice(selectedVariant!.price)
        : product.formattedMinPrice;
    final optStr = selectedOptions.entries
        .where((e) => e.key != 'Metal Type' && e.value.isNotEmpty)
        .map((e) => e.value)
        .join(' / ');

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (optStr.isNotEmpty)
                  Text(optStr,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary)),
                Text(price,
                    style: AppTextStyles.priceText
                        .copyWith(color: AppColors.teal)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: addingToCart ? null : onAddToCart,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                  color: AppColors.teal, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: addingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Error ────────────────────────────────────────────────────────────────────

class _ProductLoadError extends StatelessWidget {
  final String? error;
  const _ProductLoadError({this.error});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          border: Border.all(color: const Color(0xFFFFCC80)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 18),
            SizedBox(width: 8),
            Text('Product could not load',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                    fontSize: 13)),
          ]),
          if (error != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFFFFF0F0),
              child: Text('Error: $error',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.red, height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Check your internet connection and API token.',
            style:
                TextStyle(fontSize: 11, color: Color(0xFF5D4037), height: 1.6),
          ),
        ]),
      ),
    );
  }
}
