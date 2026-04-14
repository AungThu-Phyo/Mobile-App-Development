import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/input_validator.dart';
import 'session_form_components.dart';

class SessionUpsertForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final String subtitle;
  final String submitLabel;
  final bool isSubmitting;

  final List<String> activityTypes;
  final List<String> interactionPreferences;

  final String selectedActivityType;
  final double minRating;
  final String interactionPreference;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController facultyController;
  final TextEditingController daysController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final TextEditingController participantsController;

  final ValueChanged<String> onActivityTypeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<double> onMinRatingChanged;
  final ValueChanged<String> onInteractionPreferenceChanged;
  final VoidCallback onSubmit;

  const SessionUpsertForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.subtitle,
    required this.submitLabel,
    required this.isSubmitting,
    required this.activityTypes,
    required this.interactionPreferences,
    required this.selectedActivityType,
    required this.minRating,
    required this.interactionPreference,
    required this.selectedDate,
    required this.selectedTime,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.facultyController,
    required this.daysController,
    required this.hoursController,
    required this.minutesController,
    required this.participantsController,
    required this.onActivityTypeChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onMinRatingChanged,
    required this.onInteractionPreferenceChanged,
    required this.onSubmit,
  });

  InputDecoration _fieldDecor({String? hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _durationFieldDecor(String hint) {
    return _fieldDecor(hint: hint).copyWith(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.heroGradientCoolToWarm,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SessionFormSection(
            title: 'Basics',
            subtitle: 'What the session is about.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activity Type', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedActivityType,
                  decoration: _fieldDecor(),
                  items: activityTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => onActivityTypeChanged(v ?? selectedActivityType),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Title', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: titleController,
                  decoration: _fieldDecor(hint: 'e.g. Study for Math Exam'),
                  maxLength: 100,
                  validator: (v) => InputValidator.validateRequiredText(
                    v,
                    fieldName: 'Title',
                    minLength: 3,
                    maxLength: 100,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Description', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: _fieldDecor(hint: 'Describe your session...'),
                  validator: (v) => InputValidator.validateOptionalText(
                    v,
                    fieldName: 'Description',
                    maxLength: 300,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Location', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: locationController,
                  decoration: _fieldDecor(
                    hint: 'e.g. MFU Library Floor 2',
                    prefix: Icon(Icons.location_on, color: AppColors.primaryBlue),
                  ),
                  maxLength: 100,
                  validator: (v) => InputValidator.validateRequiredText(
                    v,
                    fieldName: 'Location',
                    minLength: 2,
                    maxLength: 100,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SessionFormSection(
            title: 'Schedule',
            subtitle: 'When it happens and how long it lasts.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SessionPickerTile(
                  icon: Icons.calendar_today,
                  label: SessionDateFormatter.formatDate(selectedDate),
                  onTap: onPickDate,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Start Time', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SessionPickerTile(
                  icon: Icons.access_time,
                  label: SessionDateFormatter.formatTimeOfDay(selectedTime),
                  onTap: onPickTime,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Duration', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        cursorColor: AppColors.primaryBlueDark,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MaxValueFormatter(30),
                        ],
                        decoration: _durationFieldDecor('Days'),
                        validator: (v) {
                          final d = int.tryParse(v ?? '') ?? 0;
                          final h = int.tryParse(hoursController.text) ?? 0;
                          final m = int.tryParse(minutesController.text) ?? 0;
                          if (d == 0 && h == 0 && m == 0) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: hoursController,
                        keyboardType: TextInputType.number,
                        cursorColor: AppColors.primaryBlueDark,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MaxValueFormatter(23),
                        ],
                        decoration: _durationFieldDecor('Hours'),
                        validator: (v) {
                          final d = int.tryParse(daysController.text) ?? 0;
                          final h = int.tryParse(v ?? '') ?? 0;
                          final m = int.tryParse(minutesController.text) ?? 0;
                          if (d == 0 && h == 0 && m == 0) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: minutesController,
                        keyboardType: TextInputType.number,
                        cursorColor: AppColors.primaryBlueDark,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          MaxValueFormatter(59),
                        ],
                        decoration: _durationFieldDecor('Minutes'),
                        validator: (v) {
                          final m = int.tryParse(v ?? '') ?? 0;
                          if (m >= 60) return 'Max 59';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Max Participants', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: participantsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    MaxValueFormatter(50),
                  ],
                  decoration: _fieldDecor(
                    hint: 'e.g. 2',
                    prefix: Icon(Icons.group, color: AppColors.primaryBlue),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '') ?? 0;
                    if (n < 2) return 'At least 2';
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SessionFormSection(
            title: 'Preferences',
            subtitle: 'Choose who this session is best suited for.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Minimum Rating', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: minRating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: minRating.toStringAsFixed(1),
                        activeColor: AppColors.primaryBlue,
                        onChanged: onMinRatingChanged,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            minRating.toStringAsFixed(1),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Interaction Preference', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: interactionPreferences.map((pref) {
                    final selected = interactionPreference == pref;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: pref == interactionPreferences.last ? 0 : AppSpacing.sm,
                        ),
                        child: GestureDetector(
                          onTap: () => onInteractionPreferenceChanged(pref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryBlue : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                              border: Border.all(
                                color: selected ? AppColors.primaryBlue : AppColors.grey200,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  pref == 'silent' ? Icons.volume_off : Icons.chat_bubble_outline,
                                  size: 18,
                                  color: selected ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  pref[0].toUpperCase() + pref.substring(1),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: selected ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text('Faculty (optional)', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: facultyController,
                  maxLength: 60,
                  decoration: _fieldDecor(hint: 'e.g. Science, Engineering'),
                  validator: (v) => InputValidator.validateOptionalText(
                    v,
                    fieldName: 'Faculty',
                    maxLength: 60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(submitLabel),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
