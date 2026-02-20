import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/route_names.dart';
import '../../../models/activity_session.dart';
import '../../../providers/session_provider.dart';
import '../widgets/create_session_form.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String _selectedCategory = 'Study';
  String _selectedInteraction = 'Silent';
  DateTime _selectedDate = DateTime.now();
  bool _isPM = false;
  double _minRating = 4.0;

  final _locationController = TextEditingController();
  final _hourController = TextEditingController();
  final _minuteController = TextEditingController();
  final _durationHourController = TextEditingController();
  final _durationMinuteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [_hourController, _minuteController, _durationHourController, _durationMinuteController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _durationHourController.dispose();
    _durationMinuteController.dispose();
    super.dispose();
  }

  void _postSession() {
    var hour = int.tryParse(_hourController.text) ?? 12;
    final minute = int.tryParse(_minuteController.text) ?? 0;
    if (_isPM && hour < 12) hour += 12;
    if (!_isPM && hour == 12) hour = 0;

    final durationH = int.tryParse(_durationHourController.text) ?? 0;
    final durationM = int.tryParse(_durationMinuteController.text) ?? 0;
    final duration = (durationH * 60) + durationM;

    final session = ActivitySession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: '$_selectedCategory Session',
      activityType: _selectedCategory,
      location: _locationController.text,
      startTime: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute),
      durationMinutes: duration,
      interactionLevel: _selectedInteraction,
      minPartnerRating: _minRating,
      createdBy: 'user_02',
      status: 'Open',
      notes: '',
    );

    context.read<SessionProvider>().addSession(session);
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Activity'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(RouteNames.home)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CreateSessionForm(
          selectedCategory: _selectedCategory,
          selectedInteraction: _selectedInteraction,
          selectedDate: _selectedDate,
          isPM: _isPM,
          minRating: _minRating,
          locationController: _locationController,
          hourController: _hourController,
          minuteController: _minuteController,
          durationHourController: _durationHourController,
          durationMinuteController: _durationMinuteController,
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
          onInteractionChanged: (v) => setState(() => _selectedInteraction = v),
          onDateChanged: (v) => setState(() => _selectedDate = v),
          onPMChanged: (v) => setState(() => _isPM = v),
          onRatingChanged: (v) => setState(() => _minRating = v),
          onSubmit: _postSession,
        ),
      ),
    );
  }
}

