import 'package:flutter/material.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/search/search_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String product = '/product';
  static const String cart = '/cart';
  static const String search = '/search';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case product:
        final handle = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(handle: handle),
        );
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
