import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/providers/cart_provider.dart';
import '../../data/providers/home_provider.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final String? title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onCartTap;

  const AppHeader({
    super.key,
    this.showBack = false,
    this.title,
    this.onSearchTap,
    this.onCartTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: AppColors.background,
      child: Row(
        children: [
          // Left action
          SizedBox(
            width: 56,
            child: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textPrimary,
                  )
                : IconButton(
                    icon: const Icon(Icons.search, size: 22),
                    onPressed: onSearchTap,
                    color: AppColors.textPrimary,
                  ),
          ),

          // Center — dynamic logo or title
          Expanded(
            child: Center(
              child: title != null
                  ? Text(title!, style: AppTextStyles.headlineSmall)
                  : const _DynamicLogo(),
            ),
          ),

          // Right — cart icon with badge
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [_CartIcon(onTap: onCartTap)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicLogo extends StatelessWidget {
  const _DynamicLogo();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, home, _) {
        final logoUrl = home.logoUrl;
        final shopName = home.shopName;

        if (logoUrl.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: logoUrl,
            height: 36,
            fit: BoxFit.contain,
            placeholder: (ctx, url) => _TextLogo(name: shopName),
            errorWidget: (ctx, url, err) => _TextLogo(name: shopName),
          );
        }

        return _TextLogo(name: shopName);
      },
    );
  }
}

class _TextLogo extends StatelessWidget {
  final String? name;
  const _TextLogo({this.name});

  @override
  Widget build(BuildContext context) {
    final parts = (name ?? 'EARTHLY JEWELS').toUpperCase().split(' ');
    final line1 = parts.isNotEmpty ? parts.first : 'EARTHLY';
    final line2 = parts.length > 1 ? parts.skip(1).join(' ') : 'JEWELS';
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line1,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 4,
            ),
          ),
          Text(
            line2,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 6,
            ),
          ),
        ],
      ),
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
            ),
            if (cart.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      cart.itemCount > 9 ? '9+' : '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
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
