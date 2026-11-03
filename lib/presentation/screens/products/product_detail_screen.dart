import 'package:demo_earthly/component/empty_error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/cached_image_widget.dart';
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
  bool _variantExplicitlySelected = false;
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
          _relatedProducts =
              products.where((p) => p.handle != widget.handle).take(6).toList();
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
      _variantExplicitlySelected = true;
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

    if (product.variants.length > 1 && !_variantExplicitlySelected) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => _ConfirmAddToCartDialog(
          product: product,
          variant: variant,
          selectedOptions: _selectedOptions,
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _addingToCart = true);
    try {
      await context.read<CartProvider>().addItem(variant.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Item added to your bag',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'VIEW BAG',
            textColor: AppColors.teal,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart),
          ),
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
        IconButton(
          icon: const Icon(Icons.favorite_border,
              size: 22, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.wishlist),
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
          )
              .animate(delay: 180.ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.4, end: 0, duration: 350.ms, curve: Curves.easeOut),
          body: CustomScrollView(
            key: ValueKey(product.id),
            slivers: [
              SliverToBoxAdapter(
                child: ProductGallerySection(
                  mediaItems: product.mediaItems,
                  currentIndex: _imageIndex,
                  controller: _pageController,
                  onChanged: (i) => setState(() => _imageIndex = i),
                ).animate().fadeIn(duration: 320.ms, curve: Curves.easeOut),
              ),
              SliverToBoxAdapter(
                child: ProductInfoSection(
                  product: product,
                  selectedVariant: _selectedVariant,
                )
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 360.ms,
                        curve: Curves.easeOut),
              ),
              SliverToBoxAdapter(
                child: ProductCustomizeSection(
                  product: product,
                  selectedOptions: _selectedOptions,
                  onOptionChanged: (name, val) =>
                      _onOptionChanged(name, val, product.variants),
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 360.ms,
                        curve: Curves.easeOut),
              ),
              // SliverToBoxAdapter(
              //   child: ProductActionButtons(
              //     onBeginOrder: () => _addToCart(product),
              //     addingToCart: _addingToCart,
              //   )
              //       .animate(delay: 210.ms)
              //       .fadeIn(duration: 360.ms, curve: Curves.easeOut)
              //       .slideY(begin: 0.05, end: 0, duration: 360.ms, curve: Curves.easeOut),
              // ),
              SliverToBoxAdapter(
                child: ProductDeliverySection(
                  pincodeController: _pincodeController,
                )
                    .animate(delay: 270.ms)
                    .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                    .slideY(
                        begin: 0.05,
                        end: 0,
                        duration: 360.ms,
                        curve: Curves.easeOut),
              ),
              // SliverToBoxAdapter(
              //   child: const ProductConsultationBanner()
              //       .animate(delay: 320.ms)
              //       .fadeIn(duration: 360.ms, curve: Curves.easeOut),
              // ),
              // SliverToBoxAdapter(
              //   child: const ProductPickDiamondCard()
              //       .animate(delay: 370.ms)
              //       .fadeIn(duration: 360.ms, curve: Curves.easeOut),
              // ),
              // SliverToBoxAdapter(
              //   child: const ProductRatingsGrid()
              //       .animate(delay: 420.ms)
              //       .fadeIn(duration: 360.ms, curve: Curves.easeOut),
              // ),
              SliverToBoxAdapter(
                child: ProductAccordionsSection(
                  product: product,
                  sku: _buildSku(product),
                )
                    .animate(delay: 460.ms)
                    .fadeIn(duration: 360.ms, curve: Curves.easeOut),
              ),
              if (_relatedProducts.isNotEmpty)
                SliverToBoxAdapter(
                  child: _YouMayAlsoLikeSection(
                    products: _relatedProducts,
                    onTap: (h) => Navigator.of(context)
                        .pushNamed(AppRoutes.product, arguments: h),
                  )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 360.ms, curve: Curves.easeOut)
                      .slideY(
                          begin: 0.04,
                          end: 0,
                          duration: 360.ms,
                          curve: Curves.easeOut),
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

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Marquee(
                  directionMarguee: DirectionMarguee.oneDirection,
                  child: Text(product.title,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                  ),
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
          ElevatedButton(
            onPressed: addingToCart ? null : onAddToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.teal.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
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
        ]),
      ),
    );
  }
}

// ─── Confirm Add-to-Cart Dialog ───────────────────────────────────────────────

class _ConfirmAddToCartDialog extends StatelessWidget {
  final Product product;
  final ProductVariant variant;
  final Map<String, String> selectedOptions;

  const _ConfirmAddToCartDialog({
    required this.product,
    required this.variant,
    required this.selectedOptions,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImage?.url ?? '';
    final price = FormatUtils.formatRsPrice(variant.price);
    final options =
        selectedOptions.entries.where((e) => e.value.isNotEmpty).toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text('Confirm Selection',
                      style: AppTextStyles.headlineSmall),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Product snapshot ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedImageWidget(
                      url: imageUrl,
                      height: 72,
                      width: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(price,
                          style: AppTextStyles.priceText
                              .copyWith(color: AppColors.teal)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),

            // ── Selected options ────────────────────────────────────────
            Text(
              'YOUR SELECTION',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            ...options.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(e.key,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          e.value,
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // ── Buttons ─────────────────────────────────────────────────
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton(
            //     onPressed: () => Navigator.of(context).pop(false),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: AppColors.textPrimary,
            //       side: const BorderSide(color: AppColors.textPrimary),
            //       padding: const EdgeInsets.symmetric(vertical: 14),
            //       shape: const RoundedRectangleBorder(),
            //       elevation: 0,
            //     ),
            //     child: Text('CHANGE SELECTION',
            //         style: AppTextStyles.button),
            //   ),
            // ),
            // const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  'ADD TO CART',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
