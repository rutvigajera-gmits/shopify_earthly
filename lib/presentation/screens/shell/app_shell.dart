import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().init();
      context.read<WishlistProvider>().init();
      context.read<CartProvider>().init();
    });
  }

  void _navigate(int index) => setState(() => _currentIndex = index);
  void _openSearch() => Navigator.of(context).pushNamed(AppRoutes.search);
  void _openCart() => Navigator.of(context).pushNamed(AppRoutes.cart);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              ),
              const _SearchTab(),
              const _CartTab(),
              const AccountScreen(),
            ],
          ),
          // Ring Matchmaker FAB — floats above all tabs
          const Positioned(
            right: 16,
            bottom: 16,
            child: ChatbotFab(),
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
