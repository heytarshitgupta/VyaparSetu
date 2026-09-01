import 'package:flutter/material.dart';
import '../../buyer_section/screens/shared/placeholder_screen.dart';
import '../../buyer_section/screens/shared/auth_screen.dart';
import '../../buyer_section/screens/shared/otp_screen.dart';
import '../../buyer_section/onboarding/buyer_onboarding_screen.dart';
import '../../buyer_section/onboarding/buyer_verification_screen.dart';
import '../../buyer_section/home/buyer_main_screen.dart';

import '../../producer_section/auth/producer_login_screen.dart';
import '../../producer_section/auth/producer_signup_screen.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String otpRoute = '/otp';
  static const String buyerOnboardingRoute = '/buyer_onboarding';
  static const String buyerVerificationRoute = '/buyer_verification';
  
  static const String homeRoute = '/home';
  static const String marketplaceRoute = '/marketplace';
  static const String productDetailRoute = '/product_detail';
  static const String postRequirementRoute = '/post_requirement';
  static const String myRequestsRoute = '/my_requests';

  static const String producerLoginRoute = '/producer_login';
  static const String producerSignupRoute = '/producer_signup';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case otpRoute:
        return MaterialPageRoute(builder: (_) => const OtpScreen());
      case buyerOnboardingRoute:
        return MaterialPageRoute(builder: (_) => const BuyerOnboardingScreen());
      case buyerVerificationRoute:
        return MaterialPageRoute(builder: (_) => const BuyerVerificationScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const BuyerMainScreen());
      case marketplaceRoute:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'Marketplace'));
      case productDetailRoute:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'Product Detail'));
      case postRequirementRoute:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'Post Requirement'));
      case myRequestsRoute:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'My Requests'));
      case producerLoginRoute:
        return MaterialPageRoute(builder: (_) => const ProducerLoginScreen());
      case producerSignupRoute:
        return MaterialPageRoute(builder: (_) => const ProducerSignupScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
