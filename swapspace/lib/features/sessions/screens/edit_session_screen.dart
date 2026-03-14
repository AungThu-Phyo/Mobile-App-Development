import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/session_model.dart';
import '../../../providers/session_provider.dart';

class EditSessionScreen extends StatefulWidget {
  final SessionModel session;
  const EditSessionScreen({super.key, required this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _facultyController;
  late final TextEditingController _daysController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _participantsController;

  late String _activityType;
  late double _minRating;
  late String _interactionPreference;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isSubmitting = false;

  final _activityTypes = ['study', 'gym', 'football', 'walking', 'other'];

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleController = TextEditingController(text: s.title);
    _descriptionController = TextEditingController(text: s.description);
    _locationController = TextEditingController(text: s.location);
    _facultyController = TextEditingController(text: s.faculty);
    final totalMinutes = s.durationMinutes;
    final days = totalMinutes ~/ (24 * 60);
    final remainAfterDays = totalMinutes % (24 * 60);
    _daysController = TextEditingController(text: days > 0 ? '$days' : '');
    _hoursController = TextEditingController(text: '${remainAfterDays ~/ 60}');
    _minutesController = TextEditingController(text: '${remainAfterDays % 60}');
    _participantsController = TextEditingController(
      text: '${s.maxParticipants}',
    );
    _activityType = s.activityType;
    _minRating = s.minRating;
    _interactionPreference = s.interactionPreference;
    _selectedDate = s.date;
    _selectedTime = TimeOfDay(hour: s.date.hour, minute: s.date.minute);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _facultyController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final cutoff = widget.session.date.subtract(const Duration(hours: 1));
    if (now.isAfter(cutoff)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot edit session less than 1 hour before start'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final sessionDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final durationMinutes = days * 24 * 60 + hours * 60 + minutes;
    final maxParticipants = int.tryParse(_participantsController.text) ?? 2;

    final updated = widget.session.copyWith(
      activityType: _activityType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      date: sessionDate,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      minRating: _minRating,
      interactionPreference: _interactionPreference,
      faculty: _facultyController.text.trim(),
    );

    final provider = context.read<SessionProvider>();
    final success = await provider.updateSession(updated);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Session updated')));
      context.go(RouteNames.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update session'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
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
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.warningOrangeLight,
              ),
              child: Icon(
                Icons.edit_rounded,
                size: 18,
                color: AppColors.warningOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Edit Session'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(RouteNames.home),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
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
                            colors: AppColors.heroGradientWarmToCool,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update session details',
                              style: AppTextStyles.headingMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Adjust the session without changing any of its existing rules or behavior.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FormSection(
                        title: 'Basics',
                        subtitle: 'Core activity information.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activity Type',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              value: _activityType,
                              decoration: _fieldDecor(),
                              items: _activityTypes.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                  ),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _activityType = v!),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Title',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _titleController,
                              decoration: _fieldDecor(
                                hint: 'e.g. Study for Math Exam',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Title is required'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Description',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: _fieldDecor(
                                hint: 'Describe your session...',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Location',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _locationController,
                              decoration: _fieldDecor(
                                hint: 'e.g. MFU Library Floor 2',
                                prefix: Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Location is required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FormSection(
                        title: 'Schedule',
                        subtitle: 'Timing and capacity.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date', style: AppTextStyles.labelLarge),
                            const SizedBox(height: AppSpacing.sm),
                            _PickerTile(
                              icon: Icons.calendar_today,
                              label: _formatDate(_selectedDate),
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Start Time',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _PickerTile(
                              icon: Icons.access_time,
                              label: _formatTime(_selectedTime),
                              onTap: _pickTime,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Duration',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _daysController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _MaxValueFormatter(30),
                                    ],
                                    decoration: _fieldDecor(hint: 'Days'),
                                    validator: (v) {
                                      final d = int.tryParse(v ?? '') ?? 0;
                                      final h =
                                          int.tryParse(_hoursController.text) ??
                                          0;
                                      final m =
                                          int.tryParse(
                                            _minutesController.text,
                                          ) ??
                                          0;
                                      if (d == 0 && h == 0 && m == 0)
                                        return 'Required';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: TextFormField(
                                    controller: _hoursController,
                                    keyboardType: TextInputType.number,
                                    cursorColor: AppColors.primaryBlueDark,
                                    style: AppTextStyles.bodyLarge,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _MaxValueFormatter(23),
                                    ],
                                    decoration: _fieldDecor(
                                      hint: 'Hours',
                                      prefix: Icon(
                                        Icons.schedule,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    validator: (v) {
                                      final d =
                                          int.tryParse(_daysController.text) ??
                                          0;
                                      final h = int.tryParse(v ?? '') ?? 0;
                                      final m =
                                          int.tryParse(
                                            _minutesController.text,
                                          ) ??
                                          0;
                                      if (d == 0 && h == 0 && m == 0)
                                        return 'Required';
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: TextFormField(
                                    controller: _minutesController,
                                    keyboardType: TextInputType.number,
                                    cursorColor: AppColors.primaryBlueDark,
                                    style: AppTextStyles.bodyLarge,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      _MaxValueFormatter(59),
                                    ],
                                    decoration: _fieldDecor(hint: 'Minutes'),
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
                            const Text(
                              'Max Participants',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _participantsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _MaxValueFormatter(50),
                              ],
                              decoration: _fieldDecor(
                                hint: 'e.g. 2',
                                prefix: Icon(
                                  Icons.group,
                                  color: AppColors.primaryBlue,
                                ),
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
                      _FormSection(
                        title: 'Preferences',
                        subtitle: 'Who this session is for.',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Minimum Rating',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: _minRating,
                                    min: 0,
                                    max: 5,
                                    divisions: 10,
                                    label: _minRating.toStringAsFixed(1),
                                    activeColor: AppColors.primaryBlue,
                                    onChanged: (v) =>
                                        setState(() => _minRating = v),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusLg,
                                    ),
                                    border: Border.all(
                                      color: AppColors.grey200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _minRating.toStringAsFixed(1),
                                        style: AppTextStyles.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Interaction Preference',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: ['silent', 'social'].map((pref) {
                                final selected = _interactionPreference == pref;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: pref == 'silent'
                                          ? AppSpacing.sm
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _interactionPreference = pref,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.primaryBlue
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusLg,
                                          ),
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.primaryBlue
                                                : AppColors.grey200,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              pref == 'silent'
                                                  ? Icons.volume_off
                                                  : Icons.chat_bubble_outline,
                                              size: 18,
                                              color: selected
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            Text(
                                              pref[0].toUpperCase() +
                                                  pref.substring(1),
                                              style: AppTextStyles.labelLarge
                                                  .copyWith(
                                                    color: selected
                                                        ? Colors.white
                                                        : AppColors
                                                              .textSecondary,
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
                            const Text(
                              'Faculty (optional)',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _facultyController,
                              decoration: _fieldDecor(
                                hint: 'e.g. Science, Engineering',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Icon(Icons.arrow_drop_down, color: AppColors.grey600),
          ],
        ),
      ),
    );
  }
}

/// Limits numeric input to a maximum value.
class _MaxValueFormatter extends TextInputFormatter {
  final int max;
  _MaxValueFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value > max) return oldValue;
    return newValue;
  }
}
