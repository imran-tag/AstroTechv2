import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _isoFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// Format date as "dd/MM/yyyy"
  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  /// Format time as "HH:mm"
  static String formatTime(DateTime? date) {
    if (date == null) return '-';
    return _timeFormat.format(date);
  }

  /// Format date and time as "dd/MM/yyyy HH:mm"
  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return _dateTimeFormat.format(date);
  }

  /// Format as ISO string for API
  static String toIsoString(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parse ISO string from API
  static DateTime? fromIsoString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get relative time (e.g., "il y a 2 heures")
  static String getRelativeTime(DateTime? date) {
    if (date == null) return '-';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return formatDate(date);
    } else if (difference.inDays > 1) {
      return 'il y a ${difference.inDays} jours';
    } else if (difference.inDays == 1) {
      return 'hier';
    } else if (difference.inHours > 1) {
      return 'il y a ${difference.inHours} heures';
    } else if (difference.inHours == 1) {
      return 'il y a 1 heure';
    } else if (difference.inMinutes > 1) {
      return 'il y a ${difference.inMinutes} minutes';
    } else {
      return 'à l\'instant';
    }
  }

  /// Format duration (e.g., "2h 30min")
  static String formatDuration(int? hours, int? minutes) {
    if (hours == null && minutes == null) return '-';

    final h = hours ?? 0;
    final m = minutes ?? 0;

    if (h == 0 && m == 0) return '-';
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
