import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import '../../presentation/screens/products/designer_rings_collection_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/shape_products_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/shopify_web_checkout_screen.dart';
import '../../presentation/screens/checkout/order_confirmation_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/wishlist/wishlist_screen.dart';
import '../../presentation/screens/account/addresses_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String product = '/product';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String search = '/search';
  static const String wishlist = '/wishlist';
  static const String addresses = '/addresses';
  static const String shapeProducts = '/shape-products';
  static const String designerRingsCollection = '/designer-rings-collection';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case product:
        final handle = settings.arguments as String? ?? '';
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => ProductDetailScreen(handle: handle),
          transitionsBuilder: (_, animation, secondaryAnimation, child) =>
              SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          ),
        );
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case checkout:
        return MaterialPageRoute(
            builder: (_) => const ShopifyWebCheckoutScreen());
      case orderConfirmation:
        return MaterialPageRoute(
            builder: (_) => const OrderConfirmationScreen());
      case search:
        return _sharedAxisRoute(settings, const SearchScreen());
      case wishlist:
        return _sharedAxisRoute(settings, const WishlistScreen());
      case addresses:
        return _sharedAxisRoute(settings, const AddressesScreen());
      case shapeProducts:
        final args = settings.arguments as Map<String, String>? ?? {};
        return _sharedAxisRoute(
          settings,
          ShapeProductsScreen(
            shapeName: args['shapeName'] ?? '',
            collectionHandle: args['handle'] ?? '',
          ),
        );
      case designerRingsCollection:
        final args = settings.arguments as Map<String, String>? ?? {};
        return _sharedAxisRoute(
          settings,
          DesignerRingsCollectionScreen(
            collectionTitle: args['title'] ?? '',
            collectionHandle: args['handle'] ?? '',
            collectionImageUrl: args['imageUrl'] ?? '',
            showShapeFilter: args['showShapeFilter'] != 'false',
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  static PageRouteBuilder<dynamic> _sharedAxisRoute(
      RouteSettings settings, Widget page) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          SharedAxisTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        transitionType: SharedAxisTransitionType.horizontal,
        child: child,
      ),
    );
  }
}
