import 'package:demo_earthly/component/empty_error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/loader_widget.dart';
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
import '../../providers/wishlist_provider.dart';
import '../../../data/services/recently_viewed_service.dart';
import '../../../data/services/shopify_service.dart';
import '../../common/widgets/product_card.dart';
import 'widgets/product_gallery.dart';
import 'widgets/product_info_section.dart';
import 'widgets/product_customize_section.dart';
import 'widgets/product_actions_section.dart';
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
    debugPrint('[PDS] initState handle=${widget.handle}');
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
          _relatedProducts =
              products.where((p) => p.handle != widget.handle).take(6).toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    debugPrint('[PDS] dispose handle=${widget.handle}');
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
          _selectedOptions = {..._selectedOptions, ...partial.selectedOptions};
        }
      }
    });
  }

  Future<void> _addToCart(Product product) async {
    final variant = _selectedVariant ?? product.variants.firstOrNull;
    if (variant == null) return;
    debugPrint('[PDS] _addToCart start variant=${variant.id}');
    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addItem(variant.id, 1);
      if (!mounted) return;
      final cartProvider = context.read<CartProvider>();
      debugPrint('[PDS] addItem done, hasError=${cartProvider.hasError}');
      if (cartProvider.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cartProvider.errorMessage ?? 'Failed to add item to cart',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Item added to your bag',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new,
            size: 18, color: AppColors.textPrimary),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text('EARTHLY',
          style: AppTextStyles.button.copyWith(fontSize: 14, letterSpacing: 3)),
      centerTitle: true,
      actions: [
        Consumer<WishlistProvider>(
          builder: (ctx, wishlist, _) {
            final handle =
                ctx.read<ProductProvider>().selectedProduct?.handle ?? '';
            final saved = handle.isNotEmpty && wishlist.contains(handle);
            return IconButton(
              icon: Icon(
                saved ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: saved ? AppColors.badge : AppColors.textPrimary,
              ),
              onPressed: () {
                if (handle.isNotEmpty) wishlist.toggle(handle);
              },
            );
          },
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
        debugPrint('[PDS] Consumer rebuild: loading=${provider.loadingProduct} hasProduct=${provider.selectedProduct != null} addingToCart=$_addingToCart');
        if (provider.loadingProduct) {
          return Scaffold(appBar: _buildAppBar(), body: const LoaderWidget());
        }
        final product = provider.selectedProduct;
        if (product == null) {
          return Scaffold(
              appBar: _buildAppBar(),
              body: NoDataWidget(
                title: 'Product not found',
                subTitle: 'The product you are looking for does not exist.',
                imageWidget: ErrorStateWidget(),
              ));
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
            key: ValueKey(product.id),
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
                  product: product,
                  selectedVariant: _selectedVariant,
                ),
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
                child: ProductDeliverySection(
                  pincodeController: _pincodeController,
                ),
              ),
              SliverToBoxAdapter(
                child: ProductAccordionsSection(
                  product: product,
                  sku: _buildSku(product),
                ),
              ),
              if (_relatedProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: _YouMayAlsoLikeSection(
                    products: _relatedProducts,
                    onTap: (h) => Navigator.of(context)
                        .pushNamed(AppRoutes.product, arguments: h),
                  ),
                ),
              SliverToBoxAdapter(child: 24.height),
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
  const _YouMayAlsoLikeSection({required this.products, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: AppColors.border),
      Text('You may also like', style: AppTextStyles.headlineSmall).paddingOnly(
        left: AppConstants.horizontalPadding,
        top: 20,
        right: AppConstants.horizontalPadding,
        bottom: 12,
      ),
      SizedBox(
        height: 230,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          itemCount: products.length,
          separatorBuilder: (_, __) => 12.width,
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
      20.height,
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

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPad),
      child: SizedBox(
        height: 52,
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
          12.width,
          SizedBox(
            width: 140,
            height: 48,
            child: ElevatedButton(
              onPressed: addingToCart ? null : onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
              child: addingToCart
                  ? const LoaderWidget(size: 20, color: Colors.white)
                  : const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
