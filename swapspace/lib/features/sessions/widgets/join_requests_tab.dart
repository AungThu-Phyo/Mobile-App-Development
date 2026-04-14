import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/join_request_provider.dart';
import 'join_request_card.dart';

class JoinRequestsTab extends StatefulWidget {
  final ScrollController scrollController;

  const JoinRequestsTab({super.key, required this.scrollController});

  @override
  State<JoinRequestsTab> createState() => _JoinRequestsTabState();
}

class _JoinRequestsTabState extends State<JoinRequestsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userId ?? '';
      if (uid.isEmpty) return;

      final provider = context.read<JoinRequestProvider>();
      provider.loadIncomingRequests(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JoinRequestProvider>(
      builder: (context, provider, _) {
        final uid = context.read<AuthProvider>().userId ?? '';
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
          controller: widget.scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: requests.length + (provider.isLoadingMoreIncomingRequests ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index >= requests.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (uid.isNotEmpty &&
                provider.hasMoreIncomingRequests &&
                !provider.isLoadingMoreIncomingRequests &&
                index >= requests.length - 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<JoinRequestProvider>().loadMoreIncomingRequests(uid);
                }
              });
            }

            return JoinRequestCard(request: requests[index]);
          },
        );
      },
    );
  }
}
