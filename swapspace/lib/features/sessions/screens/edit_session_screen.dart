import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/constants/session_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/session_model.dart';
import '../../../providers/session_provider.dart';
import '../widgets/session_upsert_form.dart';

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

  final _activityTypes = SessionConstants.activityTypes;

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
      lastDate: DateTime.now().add(const Duration(days: SessionRules.maxScheduleDays)),
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

    if (!SessionDateFormatter.canEditSession(widget.session.date)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot edit session less than 1 hour before start'),
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
    final maxParticipants =
      int.tryParse(_participantsController.text) ??
      SessionRules.defaultMaxParticipants;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Session'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SessionUpsertForm(
                  formKey: _formKey,
                  title: 'Update session details',
                  subtitle:
                      'Adjust the session without changing any of its existing rules or behavior.',
                  submitLabel: 'Save Changes',
                  isSubmitting: _isSubmitting,
                  activityTypes: _activityTypes,
                  interactionPreferences: SessionConstants.interactionPreferences,
                  selectedActivityType: _activityType,
                  minRating: _minRating,
                  interactionPreference: _interactionPreference,
                  selectedDate: _selectedDate,
                  selectedTime: _selectedTime,
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  locationController: _locationController,
                  facultyController: _facultyController,
                  daysController: _daysController,
                  hoursController: _hoursController,
                  minutesController: _minutesController,
                  participantsController: _participantsController,
                  onActivityTypeChanged: (v) => setState(() => _activityType = v),
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                  onMinRatingChanged: (v) => setState(() => _minRating = v),
                  onInteractionPreferenceChanged: (v) =>
                      setState(() => _interactionPreference = v),
                  onSubmit: _submit,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
