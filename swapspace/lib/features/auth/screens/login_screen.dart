import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/consent_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _consentDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final consentProvider = context.read<ConsentProvider>();
    if (!consentProvider.hasConsented && !_consentDialogShown && consentProvider.isLoaded) {
      _consentDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showConsentDialog();
        }
      });
    }
  }

  Future<bool> _showConsentDialog() async {
    final consentProvider = context.read<ConsentProvider>();
    final screenContext = context;
    var agreed = consentProvider.hasConsented;
    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (builderContext, setDialogState) {
                return AlertDialog(
                  title: const Text('Privacy Consent'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SwapSpace uses your profile, sessions, requests, and feedback data to run matching and app features.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!mounted) return;
                            await screenContext.push(RouteNames.privacyPolicy);
                            if (!mounted) return;
                            _consentDialogShown = consentProvider.hasConsented;
                          });
                        },
                        child: const Text('Read Privacy Policy'),
                      ),
                      CheckboxListTile(
                        value: agreed,
                        onChanged: (value) {
                          setDialogState(() => agreed = value ?? false);
                        },
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('I have read and agree'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Decline'),
                    ),
                    if (agreed)
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Next'),
                      ),
                  ],
                );
              },
            );
          },
        ) ??
        false;

    if (accepted) {
      await consentProvider.acceptConsent();
    }
    return accepted;
  }

  Future<void> _handleSignIn() async {
    final consentProvider = context.read<ConsentProvider>();
    if (!consentProvider.hasConsented) {
      final accepted = await _showConsentDialog();
      if (!accepted || !mounted || !consentProvider.hasConsented) return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!success && authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.authBackgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.heroIconSurface,
                        border: Border.all(color: AppColors.grey200),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(
                              alpha: isDarkMode ? 0.2 : 0.16,
                            ),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.diversity_3,
                        size: 46,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'SwapSpace',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Meet your next study, gym, or activity partner on campus.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.heroPanel,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(color: AppColors.grey200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDarkMode ? 0.18 : 0.05,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.alternate_email),
                              label: const Text('Sign in with School Email'),
                              onPressed: _handleSignIn,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () => context.push(RouteNames.privacyPolicy),
                            child: const Text('Read Privacy Policy'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'By signing in, you agree to the collection and use of the minimum profile data needed to match students and manage sessions.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
