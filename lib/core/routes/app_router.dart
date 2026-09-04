import 'package:flutter/material.dart';
import '../../buyer_section/screens/shared/placeholder_screen.dart';
import '../../buyer_section/screens/shared/auth_screen.dart';
import '../../buyer_section/screens/shared/otp_screen.dart';
import '../../buyer_section/onboarding/buyer_onboarding_screen.dart';
import '../../buyer_section/onboarding/buyer_verification_screen.dart';
import '../../buyer_section/onboarding/buyer_check_submit_screen.dart';
import '../../buyer_section/onboarding/buyer_success_screen.dart';
import '../../buyer_section/home/buyer_main_screen.dart';
import '../../buyer_section/marketplace/marketplace_search_screen.dart';
import '../../buyer_section/product_detail/product_detail_screen.dart';
import '../../buyer_section/post_requirement/post_requirement_screen.dart';
import '../../buyer_section/comparison/comparison_screen.dart';
import '../../buyer_section/notifications/notifications_screen.dart';
import '../mock_data/products.dart';
import '../mock_data/responses.dart';

import '../auth/role_selection_screen.dart';
import '../../producer_section/auth/producer_login_screen.dart';
import '../../producer_section/auth/producer_signup_screen.dart';
import '../../producer_section/home/producer_placeholder_screen.dart';
import '../../producer_section/onboarding/producer_onboarding_screen.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String buyerAuthRoute = '/buyer_auth';
  static const String otpRoute = '/otp';
  static const String buyerOnboardingRoute = '/buyer_onboarding';
  static const String buyerVerificationRoute = '/buyer_verification';
  static const String buyerCheckSubmitRoute = '/buyer_check_submit';
  static const String buyerSuccessRoute = '/buyer_success';
  
  static const String homeRoute = '/home';
  static const String marketplaceRoute = '/marketplace';
  static const String productDetailRoute = '/product_detail';
  static const String postRequirementRoute = '/post_requirement';
  static const String myRequestsRoute = '/my_requests';
  static const String comparisonRoute = '/comparison';
  static const String notificationsRoute = '/notifications';

  static const String producerLoginRoute = '/producer_login';
  static const String producerSignupRoute = '/producer_signup';
  static const String producerHomeRoute = '/producer_home';
  static const String producerOnboardingRoute = '/producer_onboarding';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case buyerAuthRoute:
        return MaterialPageRoute(builder: (_) => const AuthScreen());
      case otpRoute:
        return MaterialPageRoute(builder: (_) => const OtpScreen());
      case buyerOnboardingRoute:
        return MaterialPageRoute(builder: (_) => const BuyerOnboardingScreen());
      case buyerVerificationRoute:
        return MaterialPageRoute(builder: (_) => const BuyerVerificationScreen());
      case buyerCheckSubmitRoute:
        return MaterialPageRoute(builder: (_) => const BuyerCheckSubmitScreen());
      case buyerSuccessRoute:
        return MaterialPageRoute(builder: (_) => const BuyerSuccessScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const BuyerMainScreen());
      case marketplaceRoute:
        return MaterialPageRoute(builder: (_) => const MarketplaceSearchScreen());
      case productDetailRoute:
        if (settings.arguments is Product) {
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: settings.arguments as Product),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Product not found'))),
        );
      case postRequirementRoute:
        final category = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => PostRequirementScreen(prefilledCategory: category));
      case myRequestsRoute:
        return MaterialPageRoute(builder: (_) => const PlaceholderScreen(title: 'My Requests'));
      case comparisonRoute:
        if (settings.arguments is List<ProducerResponse>) {
          return MaterialPageRoute(
            builder: (_) => ComparisonScreen(responses: settings.arguments as List<ProducerResponse>),
          );
        }
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('Invalid arguments'))));
      case notificationsRoute:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case producerLoginRoute:
        return MaterialPageRoute(builder: (_) => const ProducerLoginScreen());
      case producerSignupRoute:
        return MaterialPageRoute(builder: (_) => const ProducerSignupScreen());
      case producerHomeRoute:
        return MaterialPageRoute(builder: (_) => const ProducerPlaceholderScreen());
      case producerOnboardingRoute:
        return MaterialPageRoute(builder: (_) => const ProducerOnboardingScreen());
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
