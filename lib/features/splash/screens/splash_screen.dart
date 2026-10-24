import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/image_constants.dart';
import '../../../core/widgets/tech_background.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final splashController = Get.find<SplashController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean, unboxed logo
                Image.asset(
                  ImageConstants.logo,
                  width: 220,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 60),
                
                // Corporate sleek loading bar
                Obx(
                  () => Visibility(
                    visible: splashController.isLoading.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 150,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0xFFCDE2F5), // Matches faint blue line
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0052CC)), // Professional CRM Blue
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'INITIALIZING WORKSPACE',
                          style: TextStyle(
                            color: Color(0xFF5E6C84), // Corporate grey
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
