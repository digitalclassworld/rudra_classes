import 'package:get/get.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/splash/screens/splash_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/webview/screens/webview_screen.dart';
import 'app_routes.dart';

class RouteHelper {
  static String getSplashRoute() => AppRoutes.splash;
  static String getLoginRoute() => AppRoutes.login;
  static String getSignupRoute() => AppRoutes.signup;
  static String getOtpRoute() => AppRoutes.otp;
  static String getHomeRoute() => AppRoutes.home;
  static String getOnboardingRoute() => AppRoutes.onboarding;
  static String getWebViewRoute() => AppRoutes.webview;

  static List<GetPage> routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.webview,
      page: () => const MainWebViewScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
