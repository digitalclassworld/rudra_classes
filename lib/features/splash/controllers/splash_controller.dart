import 'dart:async';
import 'package:get/get.dart';
import '../../../core/services/storage/shared_prefs.dart';
import '../../../core/constants/app_constants.dart';
import '../../../routes/route_helper.dart';
import '../domain/services/splash_service.dart';

class SplashController extends GetxController {
  final SplashService _splashService;

  SplashController(this._splashService);

  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    initApp();
  }

  Future<void> initApp() async {
    try {
      isLoading.value = true;

      // Initialize splash service
      final isReady = await _splashService.initialize();

      if (isReady) {
        // Instant bypass of splash screen
        await Future.delayed(Duration.zero);

        // Check if onboarding is completed
        final isOnboardingCompleted = SharedPrefs.getBool(AppConstants.isOnboardingCompleted) ?? false;
        
        if (!isOnboardingCompleted) {
          Get.offAllNamed(RouteHelper.getOnboardingRoute());
        } else {
          // If onboarding is done, go directly to Webview (skipping login)
          Get.offAllNamed(RouteHelper.getWebViewRoute());
        }
      } else {
        // Handle maintenance or version issues
        Get.offAllNamed(RouteHelper.getWebViewRoute());
      }
    } catch (e) {
      // Handle errors
      Get.offAllNamed(RouteHelper.getWebViewRoute());
    } finally {
      isLoading.value = false;
    }
  }
}
