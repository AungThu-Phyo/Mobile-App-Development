import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/constants/session_constants.dart';
import '../../../models/session_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';
import '../widgets/session_upsert_form.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _facultyController = TextEditingController();
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _participantsController = TextEditingController();

  String _activityType = SessionConstants.defaultActivityType;
  double _minRating = 0.0;
  String _interactionPreference = SessionConstants.defaultInteractionPreference;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSubmitting = false;

  final _activityTypes = SessionConstants.activityTypes;

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

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
      final uid = authProvider.userId ?? '';
    final creatorName = authProvider.currentUser?.name ?? '';
    final now = DateTime.now();

    final days = int.tryParse(_daysController.text) ?? 0;
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final durationMinutes = days * 24 * 60 + hours * 60 + minutes;
    final maxParticipants =
      int.tryParse(_participantsController.text) ??
      SessionRules.defaultMaxParticipants;

    final sessionDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (!sessionDate.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please choose a future date and time'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      setState(() => _isSubmitting = false);
      return;
    }

    final session = SessionModel(
      sessionId: '${SessionConstants.sessionIdPrefix}${now.millisecondsSinceEpoch}',
      creatorUid: uid,
      creatorName: creatorName,
      activityType: _activityType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      date: sessionDate,
      durationMinutes: durationMinutes,
      maxParticipants: maxParticipants,
      minRating: _minRating,
      participantUids: [uid],
      interactionPreference: _interactionPreference,
      faculty: _facultyController.text.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final success = await sessionProvider.createSession(session);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.go(RouteNames.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sessionProvider.error ?? 'Failed to create session'),
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
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.primaryBlueLight,
              ),
              child: Icon(
                Icons.add_circle_rounded,
                size: 18,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Create Session'),
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
                child: SessionUpsertForm(
                  formKey: _formKey,
                  title: 'Create a new session',
                  subtitle:
                      'Set up the activity, timing, and preferences so the right people can join.',
                  submitLabel: 'Post Session',
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
