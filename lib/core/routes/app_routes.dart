import 'package:flutter/material.dart';
import '../../presentation/screens/products/designer_rings_collection_screen.dart';
import '../../presentation/screens/products/product_detail_screen.dart';
import '../../presentation/screens/products/shape_products_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
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
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => ProductDetailScreen(handle: handle),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case orderConfirmation:
        return MaterialPageRoute(
            builder: (_) => const OrderConfirmationScreen());
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case addresses:
        return MaterialPageRoute(builder: (_) => const AddressesScreen());
      case shapeProducts:
        final args = settings.arguments as Map<String, String>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ShapeProductsScreen(
            shapeName: args['shapeName'] ?? '',
            collectionHandle: args['handle'] ?? '',
          ),
        );
      case designerRingsCollection:
        final args = settings.arguments as Map<String, String>? ?? {};
        return MaterialPageRoute(
          builder: (_) => DesignerRingsCollectionScreen(
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
}
