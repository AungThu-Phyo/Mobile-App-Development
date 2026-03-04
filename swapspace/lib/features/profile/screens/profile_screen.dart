import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/mock_data/mock_profile.dart';
import '../../../models/activity_session.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final sessions = _selectedTab == 0 ? mockCreatedSessions : mockJoinedSessions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            ProfileHeader(user: mockCurrentUser),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${mockCurrentUser.rating}',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                          const Spacer(),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _RatingBar(stars: 5, percent: 83),
                                _RatingBar(stars: 4, percent: 10),
                                _RatingBar(stars: 3, percent: 5),
                                _RatingBar(stars: 2, percent: 2),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('${mockCurrentUser.totalSessions} REVIEWS', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Based on previous session feedback', style: AppTextStyles.captionSmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: const Text('My Sessions', style: AppTextStyles.headingSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _TabButton(label: 'Created', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  const SizedBox(width: AppSpacing.md),
                  _TabButton(label: 'Joined', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.sm),
                  child: _SessionRow(session: sessions[index]),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.errorRed),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.errorRed),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorRed),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () {
                    context.read<AuthProvider>().signOut();
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final int percent;
  const _RatingBar({required this.stars, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: AppTextStyles.caption),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.grey200,
              color: AppColors.primaryBlue,
              minHeight: 6,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$percent%', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? AppColors.primaryBlue : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: selected ? AppColors.primaryBlue : AppColors.textSecondary)),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ActivitySession session;
  const _SessionRow({required this.session});

  IconData _activityIcon(String type) {
    return switch (type) {
      'Study' => Icons.menu_book,
      'Fitness' => Icons.fitness_center,
      'Sports' => Icons.sports_basketball,
      'Walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = session.status == 'open';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlueLight),
              child: Icon(_activityIcon(session.activityType), size: 20, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: AppTextStyles.labelLarge),
                  Text('${session.startTime.month}/${session.startTime.day} · ${session.location}', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isOpen ? AppColors.successGreenLight : AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(isOpen ? 'ACTIVE' : 'PAST', style: AppTextStyles.labelSmall.copyWith(color: isOpen ? AppColors.successGreen : AppColors.grey600)),
            ),
          ],
        ),
      ),
    );
  }
}
