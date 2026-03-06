import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/feedback_model.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/feedback_provider.dart';
import '../../../repositories/user_repository.dart';

class FeedbackScreen extends StatefulWidget {
  final SessionModel session;
  const FeedbackScreen({super.key, required this.session});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final UserRepository _userRepo = UserRepository();

  List<UserModel> _reviewees = [];
  bool _loading = true;
  final Map<String, int> _ratings = {};
  final Map<String, bool> _didShowUps = {};
  final Map<String, TextEditingController> _commentControllers = {};
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentUid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final feedbackProvider = context.read<FeedbackProvider>();

    // All other participant UIDs (everyone except current user)
    final otherUids = widget.session.participantUids
        .where((uid) => uid != currentUid)
        .toList();

    // Check if already submitted for all
    final submitted = await feedbackProvider.hasAllFeedbackSubmitted(
      widget.session.sessionId,
      currentUid,
      otherUids.length,
    );

    // Load all reviewee profiles
    final List<UserModel> reviewees = [];
    for (final uid in otherUids) {
      try {
        final user = await _userRepo.getUser(uid);
        if (user != null) {
          reviewees.add(user);
          _ratings[uid] = 0;
          _didShowUps[uid] = true;
          _commentControllers[uid] = TextEditingController();
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _reviewees = reviewees;
        _loading = false;
        _alreadySubmitted = submitted;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _allRated => _ratings.values.every((r) => r > 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Session Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alreadySubmitted
              ? _buildAlreadySubmitted()
              : _buildFeedbackForm(),
    );
  }

  Widget _buildAlreadySubmitted() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 72, color: AppColors.successGreen),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Feedback Already Submitted',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You have already submitted feedback for this session.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlueLight,
                      ),
                      child: Icon(
                        _activityIcon(widget.session.activityType),
                        size: 20,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.session.title, style: AppTextStyles.labelLarge),
                          Text(
                            widget.session.activityType[0].toUpperCase() +
                                widget.session.activityType.substring(1),
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section header
            Text(
              'Rate your partners (${_reviewees.length})',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Each participant stacked vertically
            ..._reviewees.map(_buildParticipantCard),

            const SizedBox(height: AppSpacing.lg),

            // Submit button
            Consumer<FeedbackProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    onPressed: !_allRated || provider.isLoading
                        ? null
                        : () => _submit(provider),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_allRated
                            ? 'Submit Feedback'
                            : 'Rate all partners to submit'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(UserModel reviewee) {
    final uid = reviewee.uid;
    final rating = _ratings[uid] ?? 0;
    final didShowUp = _didShowUps[uid] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile row with stars beside it
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryBlueLight,
                  backgroundImage: reviewee.avatarUrl.isNotEmpty
                      ? NetworkImage(reviewee.avatarUrl)
                      : null,
                  child: reviewee.avatarUrl.isEmpty
                      ? Text(
                          reviewee.name.isNotEmpty
                              ? reviewee.name[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.headingSmall
                              .copyWith(color: AppColors.primaryBlue),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reviewee.name, style: AppTextStyles.labelLarge),
                      if (reviewee.faculty.isNotEmpty)
                        Text(
                          reviewee.faculty,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                // Current rating badge
                Column(
                  children: [
                    const Icon(Icons.star, color: AppColors.warningOrange, size: 14),
                    Text(
                      reviewee.rating.toStringAsFixed(1),
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _ratings[uid] = starValue),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starValue <= rating ? Icons.star : Icons.star_border,
                      size: 36,
                      color: starValue <= rating
                          ? AppColors.warningOrange
                          : AppColors.grey400,
                    ),
                  ),
                );
              }),
            ),
            if (rating > 0)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    _ratingLabel(rating),
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),

            const Divider(height: AppSpacing.lg),

            // Did show up
            Row(
              children: [
                Text(
                  'Did they show up?',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                _MiniToggle(
                  label: 'Yes',
                  icon: Icons.check_circle,
                  selected: didShowUp,
                  color: AppColors.successGreen,
                  onTap: () => setState(() => _didShowUps[uid] = true),
                ),
                const SizedBox(width: AppSpacing.sm),
                _MiniToggle(
                  label: 'No',
                  icon: Icons.cancel,
                  selected: !didShowUp,
                  color: AppColors.errorRed,
                  onTap: () => setState(() => _didShowUps[uid] = false),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Comment
            TextField(
              controller: _commentControllers[uid],
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Comment (optional)...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(FeedbackProvider provider) async {
    final currentUid = context.read<AuthProvider>().firebaseUser?.uid ?? '';

    bool allSuccess = true;
    for (final reviewee in _reviewees) {
      final feedback = FeedbackModel(
        feedbackId:
            '${widget.session.sessionId}_${currentUid}_${reviewee.uid}',
        sessionId: widget.session.sessionId,
        reviewerUid: currentUid,
        revieweeUid: reviewee.uid,
        rating: _ratings[reviewee.uid] ?? 0,
        comment: (_commentControllers[reviewee.uid]?.text ?? '').trim(),
        didShowUp: _didShowUps[reviewee.uid] ?? true,
        createdAt: DateTime.now(),
      );
      final success = await provider.submitFeedback(feedback);
      if (!success) allSuccess = false;
    }

    if (mounted) {
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted! Thank you.')),
        );
        context.go(RouteNames.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(provider.error ?? 'Failed to submit feedback')),
        );
      }
    }
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => 'Poor',
      2 => 'Below Average',
      3 => 'Average',
      4 => 'Good',
      5 => 'Excellent',
      _ => 'Tap a star to rate',
    };
  }

  IconData _activityIcon(String type) {
    return switch (type.toLowerCase()) {
      'study' => Icons.menu_book,
      'gym' => Icons.fitness_center,
      'football' => Icons.sports_soccer,
      'walking' => Icons.directions_walk,
      _ => Icons.group,
    };
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MiniToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: selected ? color : AppColors.grey200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? color : AppColors.grey400, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? color : AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
