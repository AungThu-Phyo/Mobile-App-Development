import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SwapSpace'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlueLight,
                ),
                child: const Icon(
                  Icons.school,
                  size: 40,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('SwapSpace', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Find your activity partner',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.alternate_email),
                  label: const Text('Sign in with School Email'),
                  onPressed: () {
                    context.read<AuthProvider>().login('');
                    context.go(RouteNames.home);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Only verified university students can access SwapSpace',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
