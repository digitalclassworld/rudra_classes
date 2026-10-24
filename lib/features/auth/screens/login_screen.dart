import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/dimensions.dart';
import '../../../core/constants/image_constants.dart';
import '../../../core/utils/styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../routes/route_helper.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context); // Theme shortcut
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
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
                    SizedBox(height: Dimensions.height45),

                    // Logo
                    Center(
                      child: Image.asset(ImageConstants.logo, height: 100),
                    ),

                    SizedBox(height: Dimensions.height30),

                    // Title
                    Text(
                      'Login',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: Dimensions.height10),

                    // Subtitle
                    Text(
                      'Enter your mobile number to continue',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: Dimensions.height30),

                    // Form
                    Form(
                      key: authController.formKey,
                      child: Column(
                        children: [
                          // Mobile field
                          TextFormField(
                            controller: authController.mobileController,
                            keyboardType: TextInputType.phone,
                            decoration: Styles.inputDecoration(
                              context,
                              hintText: 'Mobile Number',
                              prefixIcon: Icon(
                                Icons.phone_android,
                                color: colorScheme.primary,
                              ),
                            ),
                            validator: authController.validateMobile,
                            maxLength: 10,
                          ),

                          SizedBox(height: Dimensions.height20),

                          // Login button
                          CustomButton(
                            text: 'Send OTP',
                            onPressed: authController.login,
                            isLoading: authController.isLoading.value,
                            buttonType: ButtonStyleType.filled,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Dimensions.height20),

                    // Signup link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              () => Get.toNamed(RouteHelper.getSignupRoute()),
                          child: Text(
                            'Sign Up',
                            style: textTheme.bodySmall?.copyWith(
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
