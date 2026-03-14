import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class CreateSessionForm extends StatelessWidget {
  final String selectedCategory;
  final String selectedInteraction;
  final DateTime selectedDate;
  final bool isPM;
  final double minRating;
  final TextEditingController locationController;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController durationHourController;
  final TextEditingController durationMinuteController;
  final Function(String) onCategoryChanged;
  final Function(String) onInteractionChanged;
  final Function(DateTime) onDateChanged;
  final Function(bool) onPMChanged;
  final Function(double) onRatingChanged;
  final VoidCallback onSubmit;

  const CreateSessionForm({
    super.key,
    required this.selectedCategory,
    required this.selectedInteraction,
    required this.selectedDate,
    required this.isPM,
    required this.minRating,
    required this.locationController,
    required this.hourController,
    required this.minuteController,
    required this.durationHourController,
    required this.durationMinuteController,
    required this.onCategoryChanged,
    required this.onInteractionChanged,
    required this.onDateChanged,
    required this.onPMChanged,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day} ${date.year}';
  }

  String _durationDisplay() {
    final h = int.tryParse(durationHourController.text) ?? 0;
    final m = int.tryParse(durationMinuteController.text) ?? 0;
    if (h == 0 && m == 0) return '';
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '$m min';
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      borderSide: BorderSide.none,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity Category', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: border,
          ),
          items: [
            'Study',
            'Fitness',
            'Sports',
            'Walking',
            'Social',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => onCategoryChanged(v!),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Campus Location', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            hintText: 'Library, Main Hall...',
            prefixIcon: Icon(Icons.location_on, color: AppColors.primaryBlue),
            filled: true,
            fillColor: AppColors.surface,
            border: border,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Date', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _formatDate(selectedDate),
                  style: AppTextStyles.bodyMedium,
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppColors.grey600),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Start Time', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: hourController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '11',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: border,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: minuteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '00',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: border,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => onPMChanged(!isPM),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: !isPM ? AppColors.primaryBlue : AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Text(
                      'AM',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: !isPM ? Colors.white : AppColors.grey600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isPM ? AppColors.primaryBlue : AppColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                    child: Text(
                      'PM',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isPM ? Colors.white : AppColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Duration', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: durationHourController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'hr',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: border,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: durationMinuteController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'min',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: border,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Builder(
          builder: (_) {
            final display = _durationDisplay();
            if (display.isEmpty) return const SizedBox.shrink();
            return Text(
              display,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryBlue,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Text('Interaction Level', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: ['Silent', 'Social', 'Colab'].map((level) {
            final selected = selectedInteraction == level;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: level != 'Colab' ? AppSpacing.sm : 0,
                ),
                child: GestureDetector(
                  onTap: () => onInteractionChanged(level),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.grey200),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      level,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('Min. Partner Rating', style: AppTextStyles.labelLarge),
            const Spacer(),
            Text(
              minRating.toStringAsFixed(1),
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        Slider(
          value: minRating,
          min: 1.0,
          max: 5.0,
          divisions: 8,
          activeColor: AppColors.primaryBlue,
          onChanged: (v) => onRatingChanged(v),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSubmit,
            child: const Text('Post Session'),
          ),
        ),
      ],
    );
  }
}
