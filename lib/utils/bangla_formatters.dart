/// Small, dependency-free formatters used across the UI.
///
/// Every formatter understands both English and Bangla, so widgets can pass
/// `context.l10n.language` and keep dates, digits and relative times in sync
/// with the selected interface language.
library;

import '../l10n/app_language.dart';

const List<String> _banglaDigits = <String>[
  '০',
  '১',
  '২',
  '৩',
  '৪',
  '৫',
  '৬',
  '৭',
  '৮',
  '৯',
];

const List<String> _banglaMonths = <String>[
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

const List<String> _englishMonths = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _banglaWeekdays = <String>[
  'সোমবার',
  'মঙ্গলবার',
  'বুধবার',
  'বৃহস্পতিবার',
  'শুক্রবার',
  'শনিবার',
  'রবিবার',
];

const List<String> _englishWeekdays = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Converts every ASCII digit in [value] to its Bangla equivalent.
String toBanglaDigits(Object? value) {
  final text = value?.toString() ?? '';
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      buffer.write(_banglaDigits[rune - 0x30]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Localizes digits for the selected language.
String localizeDigits(Object? value, AppLanguage language) {
  final text = value?.toString() ?? '';
  return language.isBangla ? toBanglaDigits(text) : text;
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Example: `Friday, 7 November 2026` or `শুক্রবার, ৭ নভেম্বর ২০২৬`.
String formatDate(DateTime date, AppLanguage language) {
  final weekday = language.isBangla
      ? _banglaWeekdays[date.weekday - 1]
      : _englishWeekdays[date.weekday - 1];
  final month = language.isBangla
      ? _banglaMonths[date.month - 1]
      : _englishMonths[date.month - 1];
  return localizeDigits(
    '$weekday, ${date.day} $month ${date.year}',
    language,
  );
}

/// Example: `7:30 PM` or `সন্ধ্যা ৭:৩০`.
String formatTime(DateTime date, AppLanguage language) {
  final hour = date.hour;
  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final minute = _twoDigits(date.minute);

  if (!language.isBangla) {
    final period = hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  final period = switch (hour) {
    >= 4 && < 6 => 'ভোর',
    >= 6 && < 12 => 'সকাল',
    >= 12 && < 16 => 'দুপুর',
    >= 16 && < 18 => 'বিকেল',
    >= 18 && < 20 => 'সন্ধ্যা',
    _ => 'রাত',
  };
  return '$period ${localizeDigits('$hour12:$minute', language)}';
}

/// `Today`, `Tomorrow`, `Yesterday` or a full date.
String formatRelativeDay(
  DateTime date, {
  DateTime? now,
  AppLanguage language = AppLanguage.english,
}) {
  final today = now ?? DateTime.now();
  final target = DateTime(date.year, date.month, date.day);
  final current = DateTime(today.year, today.month, today.day);
  final difference = target.difference(current).inDays;

  return switch (difference) {
    0 => language.isBangla ? 'আজ' : 'Today',
    1 => language.isBangla ? 'আগামীকাল' : 'Tomorrow',
    -1 => language.isBangla ? 'গতকাল' : 'Yesterday',
    _ => formatDate(date, language),
  };
}

/// Example: `Today • 7:30 PM` or `আজ • সন্ধ্যা ৭:৩০`.
String formatMatchDateTime(
  DateTime date, {
  DateTime? now,
  AppLanguage language = AppLanguage.english,
}) {
  return '${formatRelativeDay(date, now: now, language: language)} • '
      '${formatTime(date, language)}';
}

/// Relative label used on highlight cards.
String formatRelativeTime(
  DateTime date, {
  DateTime? now,
  AppLanguage language = AppLanguage.english,
}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(date);
  if (difference.isNegative) {
    return formatRelativeDay(date, now: current, language: language);
  }

  final bangla = language.isBangla;
  if (difference.inMinutes < 1) return bangla ? 'এইমাত্র' : 'Just now';
  if (difference.inMinutes < 60) {
    final minutes = localizeDigits(difference.inMinutes, language);
    return bangla ? '$minutes মিনিট আগে' : '$minutes min ago';
  }
  if (difference.inHours < 24) {
    final hours = localizeDigits(difference.inHours, language);
    return bangla ? '$hours ঘণ্টা আগে' : '$hours hr ago';
  }
  if (difference.inDays == 1) return bangla ? 'গতকাল' : 'Yesterday';
  if (difference.inDays < 7) {
    final days = localizeDigits(difference.inDays, language);
    return bangla ? '$days দিন আগে' : '$days days ago';
  }
  if (difference.inDays < 30) {
    final weeks = localizeDigits(difference.inDays ~/ 7, language);
    return bangla ? '$weeks সপ্তাহ আগে' : '$weeks weeks ago';
  }
  if (difference.inDays < 365) {
    final months = localizeDigits(difference.inDays ~/ 30, language);
    return bangla ? '$months মাস আগে' : '$months months ago';
  }
  final years = localizeDigits(difference.inDays ~/ 365, language);
  return bangla ? '$years বছর আগে' : '$years years ago';
}

/// Formats a playback duration as `02:05` / `০২:০৫` or `1:02:05` / `১:০২:০৫`.
String formatVideoDuration(
  Duration duration, {
  AppLanguage language = AppLanguage.english,
}) {
  final totalSeconds = duration.inSeconds.clamp(0, 359999);
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final text = hours > 0
      ? '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}'
      : '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  return localizeDigits(text, language);
}

/// Short countdown used by upcoming-match cards.
String formatCountdown(
  Duration duration, {
  AppLanguage language = AppLanguage.english,
}) {
  if (duration.inSeconds <= 0) {
    return language.isBangla ? 'এখনই শুরু' : 'Starting now';
  }

  final days = duration.inDays;
  final hours = duration.inHours % 24;
  final minutes = duration.inMinutes % 60;

  if (language.isBangla) {
    if (days > 0) {
      return '${toBanglaDigits(days)} দিন ${toBanglaDigits(hours)} ঘণ্টা';
    }
    if (hours > 0) {
      return '${toBanglaDigits(hours)} ঘণ্টা ${toBanglaDigits(minutes)} মিনিট';
    }
    return '${toBanglaDigits(minutes)} মিনিট';
  }

  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m';
}

/// Converts an ISO 3166-1 alpha-2 country code into a flag emoji.
String countryFlag(String? countryCode) {
  if (countryCode == null || countryCode.length != 2) return '';
  final code = countryCode.toUpperCase();
  if (!RegExp(r'^[A-Z]{2}$').hasMatch(code)) return '';
  return String.fromCharCodes(
    code.codeUnits.map((unit) => 0x1F1E6 + (unit - 0x41)),
  );
}
