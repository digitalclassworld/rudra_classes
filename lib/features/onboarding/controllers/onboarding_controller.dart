import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage/shared_prefs.dart';
import '../../../routes/route_helper.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    // 5 pages total, so index goes up to 4
    if (currentPage.value < 4) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      finishOnboarding();
    }
  }

  void skip() {
    finishOnboarding();
  }

  void finishOnboarding() {
    SharedPrefs.setBool(AppConstants.isOnboardingCompleted, true);
    Get.offAllNamed(RouteHelper.getWebViewRoute());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
