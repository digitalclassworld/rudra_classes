import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/image_constants.dart';
import '../../../core/widgets/tech_background.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OnboardingController controller = Get.put(OnboardingController());

    final List<Map<String, dynamic>> pages = [
      {
        'title': 'Welcome to Rudra Classes',
        'description': 'Your ultimate platform for managing your educational institution efficiently and effectively.',
        'icon': 'LOGO',
      },
      {
        'title': 'Student Management',
        'description': 'Easily manage student records, track progress, and keep all information organized in one place.',
        'icon': Icons.people_outline,
      },
      {
        'title': 'Fee Management',
        'description': 'Keep track of payments, generate receipts, and manage all financial transactions securely.',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'Staff Management',
        'description': 'Manage staff attendance, payroll, and schedules efficiently.',
        'icon': Icons.badge_outlined,
      },
      {
        'title': 'Attendance Management',
        'description': 'Easily monitor and record student and staff attendance accurately.',
        'icon': Icons.fact_check_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: TechBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // Main Foreground Content
              Column(
                children: [
                  // Top Bar with Skip
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0, top: 20.0),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: controller.skip,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        ),
                        child: const Text(
                          'SKIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.0,
                            color: Color(0xFF091E42),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Central Structured Glassmorphism Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.65), // Frosted glass
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9), // Glass border highlight
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0052CC).withOpacity(0.1),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                        child: Column(
                          children: [
                            // Sliding Content inside the glass card
                            Expanded(
                              child: PageView.builder(
                                controller: controller.pageController,
                                onPageChanged: controller.onPageChanged,
                                itemCount: pages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      // Floating glass bubble icons (Strictly in the 4 corners to avoid text)
                                      Positioned(top: 15, left: 15, child: Transform.rotate(angle: -0.2 + (index * 0.1), child: _buildGlassBubble(Icons.school, 28))),
                                      Positioned(top: 35, right: 15, child: Transform.rotate(angle: 0.3 - (index * 0.1), child: _buildGlassBubble(Icons.menu_book, 24))),
                                      Positioned(bottom: 15, left: 15, child: Transform.rotate(angle: 0.5 + (index * 0.1), child: _buildGlassBubble(Icons.edit, 22))),
                                      Positioned(bottom: 35, right: 15, child: Transform.rotate(angle: -0.4 - (index * 0.1), child: _buildGlassBubble(Icons.calculate, 26))),
                                      
                                      // Main Page Content
                                      Padding(
                                        padding: const EdgeInsets.all(30.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            // Icon / Logo with subtle glowing backdrop
                                            Expanded(
                                              child: Center(
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Glow effect
                                                    Container(
                                                      width: 150,
                                                      height: 150,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFF0052CC).withOpacity(0.08),
                                                            blurRadius: 50,
                                                            spreadRadius: 20,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Foreground content
                                                    pages[index]['icon'] == 'LOGO'
                                                        ? Image.asset(
                                                            ImageConstants.logo,
                                                            fit: BoxFit.contain,
                                                            width: 240,
                                                          )
                                                        : Container(
                                                            padding: const EdgeInsets.all(25),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              shape: BoxShape.circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: const Color(0xFF0052CC).withOpacity(0.15),
                                                                  blurRadius: 25,
                                                                  spreadRadius: 2,
                                                                  offset: const Offset(0, 8),
                                                                )
                                                              ],
                                                            ),
                                                            child: Icon(
                                                              pages[index]['icon'],
                                                              size: 80,
                                                              color: const Color(0xFF0052CC), // CRM Blue
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            
                                            // Title
                                            Text(
                                              pages[index]['title'],
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF091E42), // Dark Navy/Black
                                                letterSpacing: -0.5,
                                                height: 1.2,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            
                                            // Subtitle
                                            Text(
                                              pages[index]['description'],
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF5E6C84), // Corporate grey
                                                height: 1.5,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            
                            // Bottom Controls Fixed inside the card
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                              child: Column(
                                children: [
                                  // Glassmorphic Dots
                                  Obx(
                                    () => Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        pages.length,
                                        (index) => AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 5),
                                          width: controller.currentPage.value == index ? 28 : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: controller.currentPage.value == index
                                                ? const Color(0xFF0052CC) // CRM Blue
                                                : Colors.white,
                                            border: controller.currentPage.value == index
                                                ? null
                                                : Border.all(color: const Color(0xFF0052CC).withOpacity(0.3)),
                                            borderRadius: BorderRadius.circular(4),
                                            boxShadow: controller.currentPage.value == index ? [
                                              BoxShadow(
                                                color: const Color(0xFF0052CC).withOpacity(0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ] : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 35),
                                  
                                  // Premium Gradient Button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF0052CC), Color(0xFF1E70E8)], // Rich Blue Gradient
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0052CC).withOpacity(0.4),
                                          blurRadius: 15,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Obx(
                                      () => ElevatedButton(
                                        onPressed: controller.nextPage,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent, // Let gradient show
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          controller.currentPage.value == pages.length - 1
                                              ? 'Get Started'
                                              : 'Continue',
                                          style: const TextStyle(
                                            fontSize: 17, 
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBubble(IconData icon, double size) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052CC).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Icon(
        icon,
        size: size,
        color: const Color(0xFF0052CC).withOpacity(0.5),
      ),
    );
  }
}
