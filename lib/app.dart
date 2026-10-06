import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/shop_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/providers/customer_provider.dart';
import 'presentation/providers/home_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/wishlist_provider.dart';
import 'presentation/providers/chatbot_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

class EarthlyApp extends StatelessWidget {
  const EarthlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ChatbotProvider.instance),
      ],
      child: MaterialApp(
        title: 'Earthly Jewels',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
