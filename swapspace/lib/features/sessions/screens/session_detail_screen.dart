import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/activity_session.dart';
import '../../../core/mock_data/mock_users.dart';

class SessionDetailScreen extends StatelessWidget {
  final ActivitySession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final creator = mockUsers.firstWhere(
      (u) => u.id == session.createdBy,
      orElse: () => mockUsers.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.primaryBlueLight,
              child: Center(
                child: Icon(
                  _activityIcon(),
                  size: 64,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryBlueLight,
                    child: Text(
                      creator.name.isNotEmpty ? creator.name[0] : '?',
                      style: AppTextStyles.headingSmall.copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(creator.name, style: AppTextStyles.labelLarge),
                        Text(creator.department, style: AppTextStyles.caption.copyWith(color: AppColors.primaryBlue)),
                      ],
                    ),
                  ),
                  const Icon(Icons.star, color: AppColors.warningOrange, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.xs),
                  Text('${creator.rating}', style: AppTextStyles.labelLarge),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: session.status == 'open' ? AppColors.successGreenLight : AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      session.status == 'open' ? 'OPEN' : 'CLOSED',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: session.status == 'open' ? AppColors.successGreen : AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('Activity Details', style: AppTextStyles.headingSmall),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.category, label: 'Type', value: session.activityType),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.calendar_today, label: 'Date', value: _formatDate()),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.timer, label: 'Duration', value: _formatDuration()),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.location_on, label: 'Location', value: session.location),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.people, label: 'Interaction', value: session.interactionLevel),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.star, label: 'Min Rating', value: '${session.minPartnerRating}'),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('Notes', style: AppTextStyles.headingSmall),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(session.notes, style: AppTextStyles.bodyMedium),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Request to Join'),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _activityIcon() {
    return switch (session.activityType) {
      'Study' => Icons.menu_book,
      'Fitness' => Icons.fitness_center,
      'Sports' => Icons.sports_basketball,
      'Walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  String _formatDate() {
    final d = session.startTime;
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.month}/${d.day}/${d.year} $h:${d.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration() {
    final dur = session.durationMinutes;
    if (dur >= 60) {
      return dur % 60 == 0 ? '${dur ~/ 60}h' : '${dur ~/ 60}h ${dur % 60}m';
    }
    return '${dur}m';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSpacing.iconSm, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppTextStyles.labelLarge),
      ],
    );
  }
}
