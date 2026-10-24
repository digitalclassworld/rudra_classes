import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/image_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_image_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context); // Theme shortcut
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(
              () => Stack(
            children: [
              // Content
              SingleChildScrollView(
                padding: EdgeInsets.all(Dimensions.height20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: Dimensions.height20),

                    // Image
                    Center(
                      child: CustomImageWidget(
                        imagePath:  ImageConstants.otpVerification,
                        height: 150,
                      ),
                    ),

                    SizedBox(height: Dimensions.height30),

                    // Title
                    Text(
                      'OTP Verification',
                      style: textTheme.headlineMedium?.copyWith(
                        fontSize: Dimensions.font24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: Dimensions.height10),

                    // Subtitle
                    Text(
                      'We have sent OTP to your mobile number',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: Dimensions.font16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: Dimensions.height10),

                    // Mobile number
                    Text(
                      authController.currentMobile.value,
                      style: TextStyle(
                        fontSize: Dimensions.font16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: Dimensions.height30),

                    // OTP fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                            (index) => SizedBox(
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:  BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:  BorderSide(color:  colorScheme.primary, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                // Auto-focus to next field
                                if (index < 3) {
                                  FocusScope.of(context).nextFocus();
                                }

                                // Update OTP controller
                                String currentOtp = authController.otpController.text;
                                if (currentOtp.length <= index) {
                                  authController.otpController.text = currentOtp + value;
                                } else {
                                  String newOtp = '';
                                  for (int i = 0; i < currentOtp.length; i++) {
                                    if (i == index) {
                                      newOtp += value;
                                    } else {
                                      newOtp += currentOtp[i];
                                    }
                                  }
                                  authController.otpController.text = newOtp;
                                }
                              } else {
                                // Remove digit from OTP controller
                                String currentOtp = authController.otpController.text;
                                if (currentOtp.isNotEmpty && currentOtp.length > index) {
                                  String newOtp = '';
                                  for (int i = 0; i < currentOtp.length; i++) {
                                    if (i == index) {
                                      // Skip this digit
                                    } else {
                                      newOtp += currentOtp[i];
                                    }
                                  }
                                  authController.otpController.text = newOtp;
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: Dimensions.height30),

                    // Verify button
                    CustomButton(
                      text: 'Verify OTP',
                      onPressed: authController.verifyOtp,
                      isLoading: authController.isLoading.value,
                    ),

                    SizedBox(height: Dimensions.height20),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Didn\'t receive OTP? ',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: Dimensions.font14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Resend OTP logic
                            if (authController.currentUser.value?.mobile.isNotEmpty ?? false) {
                              authController.login();
                            }
                          },
                          child: Text(
                            'Resend',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: Dimensions.font14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Loading overlay
              if (authController.isLoading.value)
                LoadingWidget(type: LoadingType.overlay),
            ],
          ),
        ),
      ),
    );
  }
}
