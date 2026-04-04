import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/privacy_provider.dart';

class ProfilePrivacyCard extends StatefulWidget {
  final AuthProvider authProvider;

  const ProfilePrivacyCard({required this.authProvider});

  @override
  State<ProfilePrivacyCard> createState() => _ProfilePrivacyCardState();
}

class _ProfilePrivacyCardState extends State<ProfilePrivacyCard> {
  Future<void> _exportData() async {
    final uid = widget.authProvider.userId ?? '';
    if (uid.isEmpty) return;
    final provider = context.read<PrivacyProvider>();
    final payload = await provider.exportMyData(uid);
    if (!context.mounted) return;

    if (payload == null || payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Unable to export data')),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My Data Export (JSON)'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(payload),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'This permanently deletes your account data and authentication user. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete || !context.mounted) return;

    final uid = widget.authProvider.userId ?? '';
    if (uid.isEmpty) return;

    final provider = context.read<PrivacyProvider>();
    _showDeleteProgress();
    final ok = await provider.deleteMyAccount(uid);
    _hideDeleteProgress();
    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Unable to delete account')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted successfully.')),
    );
    context.go(RouteNames.login);
  }

  void _showDeleteProgress() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Deleting account...')),
          ],
        ),
      ),
    );
  }

  void _hideDeleteProgress() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privacy Controls', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Export your data or permanently delete your account data.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export My Data'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.errorRed),
                  ),
                  onPressed: _confirmDelete,
                  icon: Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.errorRed,
                  ),
                  label: Text(
                    'Delete My Account',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
