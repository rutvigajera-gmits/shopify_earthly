import 'package:demo_earthly/component/loader_widget.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/wishlist_provider.dart';
import '../../common/widgets/app_header.dart';
import '../../common/widgets/fade_slide_in.dart';
import '../../common/widgets/product_card.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _listenerAdded = false;
  // Stored at addPostFrameCallback time so dispose() can safely remove the
  // listener without calling context.read on a deactivated element.
  WishlistProvider? _wishlist;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wishlist = context.read<WishlistProvider>();
      if (_wishlist!.handles.isNotEmpty) {
        _wishlist!.loadProducts();
      } else {
        // WishlistProvider.init() may not have completed yet — wait for handles
        _listenerAdded = true;
        _wishlist!.addListener(_onWishlistChanged);
      }
    });
  }

  void _onWishlistChanged() {
    if (!mounted) return;
    final wishlist = context.read<WishlistProvider>();
    if (wishlist.handles.isNotEmpty) {
      wishlist.removeListener(_onWishlistChanged);
      _listenerAdded = false;
      wishlist.loadProducts();
    }
  }

  @override
  void dispose() {
    if (_listenerAdded) {
      _wishlist?.removeListener(_onWishlistChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'My Wishlist', showBack: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Divider(height: 1),
            Expanded(
              child: Consumer<WishlistProvider>(
                builder: (_, wishlist, __) {
                  if (wishlist.handles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 56,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your wishlist is empty',
                            style: AppTextStyles.headlineSmall,
                          ),
                          8.height,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Save products you love and come back to them anytime',
                              style: AppTextStyles.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (wishlist.loadingProducts) {
                    return const Center(child: LoaderWidget());
                  }

                  final products = wishlist.products;
                  if (products.isEmpty) {
                    return const Center(child: LoaderWidget());
                  }

                  return GridView.builder(
                    padding:
                        const EdgeInsets.all(AppConstants.horizontalPadding),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppConstants.cardSpacing,
                      mainAxisSpacing: AppConstants.cardSpacing,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => FadeSlideIn(
                      delay: Duration(milliseconds: (i.clamp(0, 8) * 55)),
                      child: ProductCard(
                        product: products[i],
                        onTap: () => Navigator.of(context).pushNamed(
                          '/product',
                          arguments: products[i].handle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
