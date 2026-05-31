// lib/features/settings/domain/models/reminder_settings_model.dart

class ReminderCategorySettings {
  final bool isEnabled;
  final bool isRepeat; // Deprecated: true = interval, false = exact time
  final String mode; // 'exact', 'repeat', 'smart'
  final int repeatHours;
  final String exactTime; // format "HH:mm"
  final DateTime? nextScheduledTime;
  final DateTime? lastTriggeredTime;

  const ReminderCategorySettings({
    this.isEnabled = false,
    this.isRepeat = true,
    this.mode = 'repeat',
    this.repeatHours = 3,
    this.exactTime = "08:00",
    this.nextScheduledTime,
    this.lastTriggeredTime,
  });

  factory ReminderCategorySettings.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility
    final bool legacyIsRepeat = json['isRepeat'] as bool? ?? true;
    final String parsedMode = json['mode'] as String? ?? (legacyIsRepeat ? 'repeat' : 'exact');

    return ReminderCategorySettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      isRepeat: legacyIsRepeat,
      mode: parsedMode,
      repeatHours: json['repeatHours'] as int? ?? 3,
      exactTime: json['exactTime'] as String? ?? "08:00",
      nextScheduledTime: json['nextScheduledTime'] != null
          ? DateTime.parse(json['nextScheduledTime'] as String)
          : null,
      lastTriggeredTime: json['lastTriggeredTime'] != null
          ? DateTime.parse(json['lastTriggeredTime'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'isRepeat': isRepeat, // Keep for backward compatibility
      'mode': mode,
      'repeatHours': repeatHours,
      'exactTime': exactTime,
      if (nextScheduledTime != null) 'nextScheduledTime': nextScheduledTime!.toIso8601String(),
      if (lastTriggeredTime != null) 'lastTriggeredTime': lastTriggeredTime!.toIso8601String(),
    };
  }

  ReminderCategorySettings copyWith({
    bool? isEnabled,
    bool? isRepeat,
    String? mode,
    int? repeatHours,
    String? exactTime,
    DateTime? nextScheduledTime,
    DateTime? lastTriggeredTime,
    bool clearNextScheduledTime = false,
  }) {
    return ReminderCategorySettings(
      isEnabled: isEnabled ?? this.isEnabled,
      isRepeat: isRepeat ?? this.isRepeat,
      mode: mode ?? this.mode,
      repeatHours: repeatHours ?? this.repeatHours,
      exactTime: exactTime ?? this.exactTime,
      nextScheduledTime: clearNextScheduledTime ? null : (nextScheduledTime ?? this.nextScheduledTime),
      lastTriggeredTime: lastTriggeredTime ?? this.lastTriggeredTime,
    );
  }
}

class ReminderSettingsModel {
  final bool isMasterEnabled;
  final ReminderCategorySettings feeding;
  final ReminderCategorySettings sleep;
  final ReminderCategorySettings diaper;

  const ReminderSettingsModel({
    this.isMasterEnabled = false,
    this.feeding = const ReminderCategorySettings(),
    this.sleep = const ReminderCategorySettings(),
    this.diaper = const ReminderCategorySettings(),
  });

  factory ReminderSettingsModel.fromJson(Map<String, dynamic> json) {
    return ReminderSettingsModel(
      isMasterEnabled: json['isMasterEnabled'] as bool? ?? false,
      feeding: json['feeding'] != null
          ? ReminderCategorySettings.fromJson(
              json['feeding'] as Map<String, dynamic>)
          : const ReminderCategorySettings(),
      sleep: json['sleep'] != null
          ? ReminderCategorySettings.fromJson(
              json['sleep'] as Map<String, dynamic>)
          : const ReminderCategorySettings(),
      diaper: json['diaper'] != null
          ? ReminderCategorySettings.fromJson(
              json['diaper'] as Map<String, dynamic>)
          : const ReminderCategorySettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isMasterEnabled': isMasterEnabled,
      'feeding': feeding.toJson(),
      'sleep': sleep.toJson(),
      'diaper': diaper.toJson(),
    };
  }

  ReminderSettingsModel copyWith({
    bool? isMasterEnabled,
    ReminderCategorySettings? feeding,
    ReminderCategorySettings? sleep,
    ReminderCategorySettings? diaper,
  }) {
    return ReminderSettingsModel(
      isMasterEnabled: isMasterEnabled ?? this.isMasterEnabled,
      feeding: feeding ?? this.feeding,
      sleep: sleep ?? this.sleep,
      diaper: diaper ?? this.diaper,
    );
  }
}
