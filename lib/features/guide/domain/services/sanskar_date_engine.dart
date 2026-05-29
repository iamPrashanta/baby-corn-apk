import '../models/sanskar_model.dart';

class SanskarDateEngine {
  /// Calculates the default recommended date based on the baby's DOB and the SanskarRule.
  static DateTime calculateDefaultDate(DateTime birthDate, SanskarRule rule) {
    switch (rule.unit) {
      case SanskarOffsetUnit.days:
        return birthDate.add(Duration(days: rule.offset));
      case SanskarOffsetUnit.months:
        return _addMonths(birthDate, rule.offset);
      case SanskarOffsetUnit.years:
        return _addMonths(birthDate, rule.offset * 12);
      case SanskarOffsetUnit.beforeBirth:
        return birthDate.subtract(Duration(days: rule.offset));
    }
  }

  /// Calculates the effective date. Prioritizes the user's customDate over the calculated default.
  static DateTime getEffectiveDate(SanskarModel sanskar, DateTime birthDate) {
    if (sanskar.customDate != null) {
      return sanskar.customDate!;
    }
    return calculateDefaultDate(birthDate, sanskar.defaultRule);
  }

  /// Helper to safely add months to a DateTime without messing up leap years or end-of-month days.
  static DateTime _addMonths(DateTime date, int monthsToAdd) {
    int newYear = date.year;
    int newMonth = date.month + monthsToAdd;

    if (newMonth > 12) {
      newYear += (newMonth - 1) ~/ 12;
      newMonth = (newMonth - 1) % 12 + 1;
    } else if (newMonth <= 0) {
      newYear += (newMonth - 12) ~/ 12;
      newMonth = 12 + (newMonth % 12);
    }

    // Handle end-of-month clamping (e.g. Jan 31 + 1 month = Feb 28)
    int newDay = date.day;
    int daysInNewMonth = _daysInMonth(newYear, newMonth);
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return DateTime(newYear, newMonth, newDay, date.hour, date.minute, date.second);
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      bool isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonth = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }
}
