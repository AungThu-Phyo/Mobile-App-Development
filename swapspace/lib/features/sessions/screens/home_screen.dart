import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../providers/session_provider.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/session_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SwapSpace', style: AppTextStyles.headingMedium),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search activities or locations',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Consumer<SessionProvider>(
              builder: (context, provider, _) {
                return FilterTabs(
                  selectedFilter: provider.selectedFilter,
                  onFilterSelected: provider.setFilter,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Consumer<SessionProvider>(
              builder: (context, provider, _) {
                final sessions = provider.filteredSessions;
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ).copyWith(bottom: AppSpacing.sm),
                      child: SessionCard(
                        session: session,
                        onTap: () => context.go(RouteNames.sessionDetail, extra: session),
                        onJoin: () => context.go(RouteNames.sessionDetail, extra: session),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
