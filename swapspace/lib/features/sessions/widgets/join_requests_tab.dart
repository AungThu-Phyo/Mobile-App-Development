import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/join_request_model.dart';
import '../../../providers/join_request_provider.dart';
import 'join_request_card.dart';

class JoinRequestsTab extends StatelessWidget {
  final ScrollController scrollController;

  const JoinRequestsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinRequestProvider>(
      builder: (context, provider, _) {
        final requests = provider.incomingRequests;

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No join requests yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return JoinRequestCard(request: requests[index]);
          },
        );
      },
    );
  }
}
