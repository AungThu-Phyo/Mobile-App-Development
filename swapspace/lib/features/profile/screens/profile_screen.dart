import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<SessionProvider>().loadMySessions(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            ProfileHeader(user: user),
            const SizedBox(height: AppSpacing.lg),

            // Rating card
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
                            user.rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < user.rating.round() ? Icons.star : Icons.star_border,
                                    color: AppColors.warningOrange,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${user.totalSessions} sessions completed',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bio
            if (user.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('About', style: AppTextStyles.headingSmall),
                        const SizedBox(height: AppSpacing.sm),
                        Text(user.bio, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            if (user.bio.isNotEmpty) const SizedBox(height: AppSpacing.lg),

            // Info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  child: Column(
                    children: [
                      if (user.faculty.isNotEmpty)
                        _InfoRow(icon: Icons.school, label: 'Faculty', value: user.faculty),
                      _InfoRow(
                        icon: Icons.chat_bubble_outline,
                        label: 'Interaction',
                        value: user.interactionPreference[0].toUpperCase() +
                            user.interactionPreference.substring(1),
                      ),
                      if (user.activityPreferences.isNotEmpty)
                        _InfoRow(
                          icon: Icons.category,
                          label: 'Activities',
                          value: user.activityPreferences.join(', '),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // My Sessions
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
            Consumer<SessionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final uid = authProvider.firebaseUser?.uid ?? '';
                final sessions = _selectedTab == 0
                    ? provider.mySessions.where((s) => s.creatorUid == uid).toList()
                    : provider.mySessions.where((s) => s.creatorUid != uid && (s.partnerUid == uid || s.participantUids.contains(uid))).toList();

                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        _selectedTab == 0 ? 'No sessions created yet' : 'No sessions joined yet',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.sm),
                      child: _SessionRow(
                        session: sessions[index],
                        isCreator: _selectedTab == 0,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sign out
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(child: Text(value, style: AppTextStyles.labelLarge, textAlign: TextAlign.end)),
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
  final SessionModel session;
  final bool isCreator;
  const _SessionRow({required this.session, required this.isCreator});

  IconData _activityIcon(String type) {
    return switch (type.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeText) = switch (session.status) {
      'open' => (AppColors.successGreen, AppColors.successGreenLight, 'OPEN'),
      'matched' => (AppColors.primaryBlue, AppColors.primaryBlueLight, 'MATCHED'),
      'completed' => (AppColors.grey600, AppColors.grey100, 'DONE'),
      'cancelled' => (AppColors.errorRed, const Color(0xFFFFEBEE), 'CANCELLED'),
      _ => (AppColors.grey600, AppColors.grey100, session.status.toUpperCase()),
    };

    final now = DateTime.now();
    final cutoff = session.date.subtract(const Duration(hours: 1));
    final isFinished = session.status == 'completed' || session.status == 'cancelled';
    final canEdit = isCreator && !isFinished && now.isBefore(cutoff);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(RouteNames.sessionDetail, extra: session),
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
                    Text(
                      '${_formatDate(session.date)} · ${session.location}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(badgeText, style: AppTextStyles.labelSmall.copyWith(color: badgeColor)),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: 32,
                child: canEdit
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        onPressed: () => context.push(RouteNames.editSession, extra: session),
                        child: const Text('Update', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          side: const BorderSide(color: AppColors.grey600),
                        ),
                        onPressed: () => context.push(RouteNames.sessionDetail, extra: session),
                        child: const Text('View', style: TextStyle(fontSize: 12, color: AppColors.grey600)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }
}
