import 'package:flutter/material.dart';
import '../../buyer_section/screens/shared/placeholder_screen.dart';
import '../../buyer_section/screens/shared/auth_screen.dart';
import '../../buyer_section/screens/shared/otp_screen.dart';
import '../../buyer_section/auth/buyer_signup_screen.dart';
import '../../buyer_section/auth/buyer_forgot_password_email_screen.dart';
import '../../buyer_section/auth/buyer_signin_email_screen.dart';
import '../../buyer_section/auth/buyer_reset_password_screen.dart';
import '../../buyer_section/auth/buyer_otp_verification_screen.dart';
import '../../buyer_section/auth/buyer_verify_email_screen.dart';
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
import '../../buyer_section/wishlist/wishlist_screen.dart';
import '../../buyer_section/order/order_bargain_screen.dart';
import '../../buyer_section/seller/seller_dashboard_screen.dart';
import '../../buyer_section/product_detail/customization_request_screen.dart';
import '../../buyer_section/my_orders/buyer_orders_screen.dart';
import '../../buyer_section/my_orders/order_details_screen.dart';
import '../mock_data/products.dart';
import '../mock_data/responses.dart';
import '../../buyer_section/my_requests/buyer_requests_screen.dart';

import '../auth/role_selection_screen.dart';
import '../../producer_section/auth/producer_login_screen.dart';
import '../../producer_section/auth/producer_signup_screen.dart';
import '../../producer_section/home/producer_main_screen.dart';
import '../../producer_section/onboarding/producer_onboarding_screen.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String buyerAuthRoute = '/buyer_auth';
  static const String buyerSignupRoute = '/buyer_signup';
  static const String buyerForgotPasswordEmailRoute = '/buyer_forgot_password_email';
    static const String buyerResetPasswordRoute = '/buyer_reset_password';
  static const String buyerSignInEmailRoute = '/buyer_signin_email';
  static const String buyerOtpVerificationRoute = '/buyer_otp_verification';
  static const String buyerVerifyEmailRoute = '/buyer_verify_email';
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
  static const String wishlistRoute = '/wishlist';
  static const String orderBargainRoute = '/order_bargain';
  static const String sellerDashboardRoute = '/seller_dashboard';
  static const String customizationRoute = '/customization';
  static const String buyerOrdersRoute = '/buyer_orders';
  static const String orderDetailsRoute = '/order_details';

  static const String producerLoginRoute = '/producer_login';
  static const String producerSignupRoute = '/producer_signup';
  static const String producerHomeRoute = '/producer_home';
  static const String producerOnboardingRoute = '/producer_onboarding';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const RoleSelectionScreen());
      case buyerAuthRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const AuthScreen());
      case otpRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        final isVerificationMode = args?['isVerificationMode'] as bool? ?? false;
        final mobile = args?['mobile'] as String? ?? '';
        return MaterialPageRoute(settings: settings, builder: (_) => OtpScreen(
          isVerificationMode: isVerificationMode,
          mobile: mobile,
        ));
            case buyerSignInEmailRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerSignInEmailScreen());
      case buyerForgotPasswordEmailRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerForgotPasswordEmailScreen());
      case buyerResetPasswordRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerResetPasswordScreen());
      case buyerSignupRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerSignupScreen());
      case buyerOtpVerificationRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerOtpVerificationScreen());
      case buyerVerifyEmailRoute:
        final email = settings.arguments as String? ?? '';
        return MaterialPageRoute(settings: settings, builder: (_) => BuyerVerifyEmailScreen(email: email));
      case buyerOnboardingRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerOnboardingScreen());
      case buyerVerificationRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerVerificationScreen());
      case buyerCheckSubmitRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerCheckSubmitScreen());
      case buyerSuccessRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerSuccessScreen());
      case homeRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerMainScreen());
      case marketplaceRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const MarketplaceSearchScreen());
      case productDetailRoute:
        if (settings.arguments is Product) {
          return MaterialPageRoute(settings: settings, builder: (_) => ProductDetailScreen(product: settings.arguments as Product),
          );
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Product not found'))),
        );
      case postRequirementRoute:
        final category = settings.arguments as String?;
        return MaterialPageRoute(settings: settings, builder: (_) => PostRequirementScreen(prefilledCategory: category));
      case myRequestsRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerRequestsScreen());
      case comparisonRoute:
        if (settings.arguments is List<ProducerResponse>) {
          return MaterialPageRoute(settings: settings, builder: (_) => ComparisonScreen(responses: settings.arguments as List<ProducerResponse>),
          );
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Invalid arguments'))));
      case notificationsRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const NotificationsScreen());
      case wishlistRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerWishlistScreen());
      case orderBargainRoute:
        if (settings.arguments is Product) {
          return MaterialPageRoute(settings: settings, builder: (_) => OrderBargainScreen(product: settings.arguments as Product));
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Invalid product'))));
      case sellerDashboardRoute:
        if (settings.arguments is String) {
          return MaterialPageRoute(settings: settings, builder: (_) => SellerDashboardScreen(producerName: settings.arguments as String));
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Invalid producer name'))));
      case customizationRoute:
        if (settings.arguments is Product) {
          return MaterialPageRoute(settings: settings, builder: (_) => CustomizationRequestScreen(product: settings.arguments as Product));
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Invalid product'))));
      case buyerOrdersRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const BuyerOrdersScreen());
      case orderDetailsRoute:
        if (settings.arguments is MockOrder) {
          return MaterialPageRoute(settings: settings, builder: (_) => OrderDetailsScreen(order: settings.arguments as MockOrder));
        }
        return MaterialPageRoute(settings: settings, builder: (_) => const Scaffold(body: Center(child: Text('Invalid order'))));
      case producerLoginRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProducerLoginScreen());
      case producerSignupRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProducerSignupScreen());
      case producerHomeRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProducerMainScreen());
      case producerOnboardingRoute:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProducerOnboardingScreen());
      default:
        return MaterialPageRoute(settings: settings, builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
