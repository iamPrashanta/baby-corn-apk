// lib/core/utils/age_calculator.dart

class AgeCalculator {
  static String formatAge(DateTime birthDate) {
    // Treat the day of birth as Day 1.
    final now = DateTime.now();
    // Normalize to dates without time for accurate day difference
    final birthDateOnly = DateTime(birthDate.year, birthDate.month, birthDate.day);
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    
    // Add 1 so the day of birth is Day 1
    final days = nowDateOnly.difference(birthDateOnly).inDays + 1;

    if (days <= 1) return '1 day old';

    if (days < 7) {
      return '$days days old';
    }

    if (days < 30) {
      final weeks = (days / 7).floor();
      final remainingDays = days % 7;
      if (remainingDays == 0) {
        return '$weeks week${weeks > 1 ? 's' : ''} old';
      }
      return '$weeks week${weeks > 1 ? 's' : ''} and $remainingDays day${remainingDays > 1 ? 's' : ''} old';
    }

    final months = (days / 30.44).floor();
    if (months < 24) {
      final remainingDays = (days - (months * 30.44)).round();
      if (remainingDays <= 0) {
        return '$months month${months > 1 ? 's' : ''} old';
      }
      return '$months month${months > 1 ? 's' : ''} and $remainingDays day${remainingDays > 1 ? 's' : ''} old';
    }

    final years = (months / 12).floor();
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years year${years > 1 ? 's' : ''} old';
    }
    return '$years year${years > 1 ? 's' : ''} and $remainingMonths month${remainingMonths > 1 ? 's' : ''} old';
  }
}
