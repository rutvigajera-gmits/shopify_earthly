import 'package:demo_earthly/locale/base_language.dart';
import 'package:demo_earthly/locale/language_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:nb_utils/nb_utils.dart';
import 'core/config/api_config.dart';
import 'core/theme/app_colors.dart';
import 'data/services/stripe_service.dart';
import 'app.dart';


//region Global Variables
Languages languages = LanguageEn();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Stripe.publishableKey = ApiConfig.stripePublishableKey;
  await StripeService.applySettings();

  // Wire nb_utils text color globals to brand tokens so that
  // primaryTextStyle() / boldTextStyle() / secondaryTextStyle() called
  // anywhere in the app automatically inherit AppColors without repeating color args.
  textPrimaryColorGlobal = AppColors.textPrimary;
  textSecondaryColorGlobal = AppColors.textSecondary;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const EarthlyApp());
}
