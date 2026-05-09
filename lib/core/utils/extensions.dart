import 'package:intl/intl.dart';

/// Extension methods for String
extension StringExtensions on String {
  /// Convert string to uppercase
  String toUpperCaseFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }
}

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format date as "Jan 01, 2024"
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format time as "14:30"
  String get formattedTime {
    return DateFormat('HH:mm').format(this);
  }

  /// Format datetime as "Jan 01, 2024 at 14:30"
  String get formattedDateTime {
    return DateFormat('MMM dd, yyyy \'at\' HH:mm').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get time ago string (e.g., "2 hours ago", "3 days ago")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get date only (without time)
  DateTime get dateOnly {
    return DateTime(year, month, day);
  }
}

/// Extension methods for int
extension IntExtensions on int {
  /// Format number with commas (e.g., 1000 -> "1,000")
  String get formatted {
    return NumberFormat('#,###').format(this);
  }
}
