import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../providers/cart_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../home/home_screen.dart';
import '../products/products_screen.dart';
import '../account/account_screen.dart';
import '../../common/widgets/bottom_nav.dart';
import '../../common/widgets/chatbot_fab.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _tabFading = false;
  int _tabFadeKey = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().init();
      context.read<WishlistProvider>().init();
      context.read<CartProvider>().init();
    });
  }

  void _navigate(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
      _tabFading = true;
      _tabFadeKey++;
    });
  }

  void _openSearch() => Navigator.of(context).pushNamed(AppRoutes.search);
  void _openCart() => Navigator.of(context).pushNamed(AppRoutes.cart);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigate(0);
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onSearchTap: _openSearch,
                  onCartTap: _openCart,
                  onWishlistTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.wishlist),
                  onProfileTap: () => _navigate(4),
                  onNavTap: _navigate,
                ),
                ProductsScreen(
                  onSearchTap: _openSearch,
                  onCartTap: _openCart,
                  onProfileTap: () => _navigate(4),
                  onBackTap: () => _navigate(0),
                ),
                const _SearchTab(),
                const _CartTab(),
                AccountScreen(onBackTap: () => _navigate(0)),
              ],
            ),
            // Ring Matchmaker FAB — floats above all tabs
            const Positioned(
              right: 16,
              bottom: 16,
              child: ChatbotFab(),
            ),

            // Tab-switch fade overlay: hides the previous tab, then fades out
            // revealing the new tab. IndexedStack state is fully preserved.
            if (_tabFading)
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_tabFadeKey),
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  onEnd: () => setState(() => _tabFading = false),
                  builder: (_, v, __) => Opacity(
                    opacity: v,
                    child: const ColoredBox(color: AppColors.background),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: EarthlyBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 2) {
              _openSearch();
            } else if (i == 3) {
              _openCart();
            } else {
              _navigate(i);
            }
          },
        ),
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _CartTab extends StatelessWidget {
  const _CartTab();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
