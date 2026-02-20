import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class FilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    const labels = [
      'All Activities',
      'Study',
      'Fitness',
      'Sports',
      'Walking',
      'Social',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.map((label) {
          final isSelected = label == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onFilterSelected(label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.grey200),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
