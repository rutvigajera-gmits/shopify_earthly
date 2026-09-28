import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/cart_provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final String? title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onWishlistTap;
  final bool showSearchBar;

  const AppHeader({
    super.key,
    this.showBack = false,
    this.title,
    this.onSearchTap,
    this.onCartTap,
    this.onWishlistTap,
    this.showSearchBar = false,
  });

  static const double _barHeight = 56;
  static const double _searchBarHeight = 48;
  static const double _searchBarPadding = 8;

  @override
  Size get preferredSize => Size.fromHeight(
        showSearchBar ? _barHeight + _searchBarHeight + _searchBarPadding : _barHeight,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _barHeight,
            child: Row(
              children: [
                // Left
                SizedBox(
                  width: 52,
                  child: showBack
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                          color: AppColors.textPrimary,
                        )
                      : IconButton(
                          icon: const Icon(Icons.menu, size: 22),
                          onPressed: onSearchTap,
                          color: AppColors.textPrimary,
                        ),
                ),

                // Center — logo or title
                Expanded(
                  child: Center(
                    child: title != null
                        ? Text(title!, style: AppTextStyles.headlineSmall)
                        : const _DynamicLogo(),
                  ),
                ),

                // Right — wishlist + cart
                SizedBox(
                  width: 96,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, size: 20),
                        onPressed: onWishlistTap,
                        color: AppColors.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      _CartIcon(onTap: onCartTap),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Optional search bar
          if (showSearchBar) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  height: _searchBarHeight,
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text(
                        'Search jewellery, diamonds...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DynamicLogo extends StatelessWidget {
  const _DynamicLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      height: 48,
      fit: BoxFit.contain,
    );
  }
}

class _CartIcon extends StatelessWidget {
  final VoidCallback? onTap;
  const _CartIcon({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, size: 22),
              onPressed: onTap,
              color: AppColors.textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
        );
      },
    );
  }
}
