import 'package:flutter/material.dart';
import '../constants/session_constants.dart';

class SessionDateFormatter {
	static const List<String> _months = [
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

	static String formatDate(DateTime date) {
		return '${_months[date.month - 1]} ${date.day}, ${date.year}';
	}

	static String formatTimeOfDay(TimeOfDay time) {
		final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
		final minute = time.minute.toString().padLeft(2, '0');
		final period = time.period == DayPeriod.am ? 'AM' : 'PM';
		return '$hour:$minute $period';
	}

	static bool canEditSession(DateTime sessionStart, {DateTime? now}) {
		final current = now ?? DateTime.now();
		final cutoff = sessionStart.subtract(
			const Duration(hours: SessionRules.editCutoffHours),
		);
		return current.isBefore(cutoff);
	}
}

