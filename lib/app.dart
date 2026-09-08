import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/product_provider.dart';
import 'data/providers/cart_provider.dart';
import 'data/providers/shop_provider.dart';
import 'data/providers/review_provider.dart';
import 'data/providers/customer_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/products/products_screen.dart';
import 'presentation/screens/account/account_screen.dart';
import 'presentation/widgets/bottom_nav.dart';

class EarthlyApp extends StatelessWidget {
  const EarthlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: MaterialApp(
        title: 'Earthly Jewels',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Restore customer session from persisted token.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().init();
    });
  }

  void _navigate(int index) => setState(() => _currentIndex = index);
  void _openSearch() => Navigator.of(context).pushNamed(AppRoutes.search);
  void _openCart() => Navigator.of(context).pushNamed(AppRoutes.cart);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onSearchTap: _openSearch,
            onCartTap: _openCart,
            onNavTap: _navigate,
          ),
          ProductsScreen(
            onSearchTap: _openSearch,
            onCartTap: _openCart,
          ),
          const _SearchTab(),
          const _CartTab(),
          const AccountScreen(),
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
