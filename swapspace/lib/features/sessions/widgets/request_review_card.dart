import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/session_constants.dart';
import '../../../models/join_request_model.dart';
import '../../../models/session_model.dart';
import '../../../models/user_model.dart';

class RequestReviewCard extends StatelessWidget {
  final JoinRequestModel request;
  final UserModel? requester;
  final SessionModel? session;
  final VoidCallback? onRequesterTap;
  final bool isActing;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final String acceptLabel;
  final String rejectLabel;
  final String? successMessage;
  final bool isAccepting;
  final bool isRejecting;

  const RequestReviewCard({
    super.key,
    required this.request,
    required this.requester,
    required this.session,
    this.onRequesterTap,
    required this.isActing,
    required this.onAccept,
    required this.onReject,
    required this.acceptLabel,
    required this.rejectLabel,
    this.successMessage,
    this.isAccepting = false,
    this.isRejecting = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLeaveRequest = request.requestType == JoinRequestType.leave;
    final requesterName = requester?.name ?? 'Someone';
    final sessionTitle = session?.title ?? 'your session';
    final canReview = isLeaveRequest
        ? (session != null && session!.status != SessionStatus.completed)
        : session?.status == SessionStatus.open;
    final isBusy = isActing || isAccepting || isRejecting;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (session != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  sessionTitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlueDark,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onRequesterTap,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 2,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primaryBlueLight,
                            backgroundImage:
                                requester != null && requester!.avatarUrl.isNotEmpty
                                ? NetworkImage(requester!.avatarUrl)
                                : null,
                            child: requester == null || requester!.avatarUrl.isEmpty
                                ? Text(
                                    requester?.name.isNotEmpty == true
                                        ? requester!.name[0]
                                        : '?',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.primaryBlue,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(requesterName, style: AppTextStyles.labelLarge),
                                Text(
                                  isLeaveRequest
                                      ? 'wants to leave this session'
                                      : 'wants to join this session',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (requester?.faculty.isNotEmpty == true)
                                  Text(requester!.faculty, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningOrangeLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppColors.warningOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        (requester?.rating ?? 0).toStringAsFixed(1),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warningOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text(
                  request.message,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (canReview)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.errorRed),
                      ),
                      onPressed: isBusy ? () {} : onReject,
                      child: isRejecting
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.errorRed,
                                ),
                              ),
                            )
                          : Text(
                              rejectLabel,
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isBusy ? () {} : onAccept,
                      child: isAccepting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(acceptLabel),
                    ),
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  isLeaveRequest
                      ? 'Session already completed'
                      : 'Session no longer open',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}