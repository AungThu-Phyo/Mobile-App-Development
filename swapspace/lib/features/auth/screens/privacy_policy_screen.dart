import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/consent_provider.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _accepted = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _accepted = context.read<ConsentProvider>().hasConsented;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const sections = <_PolicySection>[
      _PolicySection(
        title: 'What data we collect',
        bullets: [
          'Account data: name, email, and profile photo from Google Sign-In.',
          'Profile data: faculty, bio, activity preferences, and interaction preference.',
          'App data: sessions, join requests, feedback, and notification records.',
        ],
      ),
      _PolicySection(
        title: 'Why we collect it',
        bullets: [
          'To create your account and verify your identity.',
          'To match you with other students for sessions.',
          'To manage requests, feedback, and notifications.',
        ],
      ),
      _PolicySection(
        title: 'Third-party services',
        bullets: [
          'Firebase Authentication for login.',
          'Cloud Firestore for storing app data.',
          'Google Sign-In / Google Identity Services for authentication.',
        ],
      ),
      _PolicySection(
        title: 'Your control',
        bullets: [
          'You can decline consent and stop using the app.',
          'You can export your account data from Profile > Privacy Controls.',
          'You can request permanent account deletion from Profile > Privacy Controls.',
          'You should only share the minimum profile details needed.',
          'You can request deletion of your data through your project admin or lecturer workflow.',
        ],
      ),
      _PolicySection(
        title: 'Data retention',
        bullets: [
          'Account and activity data are kept while your account remains active.',
          'Deleted accounts are removed from client-accessible records after a deletion request is completed.',
        ],
      ),
    ];

    return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Policy'),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'SwapSpace Privacy Policy',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This page explains what personal data the app uses and why it is needed.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...sections.map((section) => _PolicyCard(section: section)),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (value) {
                          setState(() => _accepted = value ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I have read and agree to the privacy policy.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepted
                          ? () async {
                              final navigator = Navigator.of(context);
                              await context.read<ConsentProvider>().acceptConsent();
                              if (!mounted) return;
                              navigator.pop();
                            }
                          : null,
                      child: const Text('Agree and Back to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class _PolicySection {
  final String title;
  final List<String> bullets;

  const _PolicySection({required this.title, required this.bullets});
}

class _PolicyCard extends StatelessWidget {
  final _PolicySection section;

  const _PolicyCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              section.title,
              style: AppTextStyles.headingSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          ...section.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(
                      bullet,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}