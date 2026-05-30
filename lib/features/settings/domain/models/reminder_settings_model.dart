// features/settings/domain/models/reminder_settings_model.dart

class ReminderCategorySettings {
  final bool isEnabled;
  final bool isRepeat; // true = interval (e.g. 3 hrs), false = exact time
  final int repeatHours;
  final String exactTime; // format "HH:mm"

  const ReminderCategorySettings({
    this.isEnabled = false,
    this.isRepeat = true,
    this.repeatHours = 3,
    this.exactTime = "08:00",
  });

  factory ReminderCategorySettings.fromJson(Map<String, dynamic> json) {
    return ReminderCategorySettings(
      isEnabled: json['isEnabled'] as bool? ?? false,
      isRepeat: json['isRepeat'] as bool? ?? true,
      repeatHours: json['repeatHours'] as int? ?? 3,
      exactTime: json['exactTime'] as String? ?? "08:00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'isRepeat': isRepeat,
      'repeatHours': repeatHours,
      'exactTime': exactTime,
    };
  }

  ReminderCategorySettings copyWith({
    bool? isEnabled,
    bool? isRepeat,
    int? repeatHours,
    String? exactTime,
  }) {
    return ReminderCategorySettings(
      isEnabled: isEnabled ?? this.isEnabled,
      isRepeat: isRepeat ?? this.isRepeat,
      repeatHours: repeatHours ?? this.repeatHours,
      exactTime: exactTime ?? this.exactTime,
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
          ? ReminderCategorySettings.fromJson(json['feeding'] as Map<String, dynamic>)
          : const ReminderCategorySettings(),
      sleep: json['sleep'] != null
          ? ReminderCategorySettings.fromJson(json['sleep'] as Map<String, dynamic>)
          : const ReminderCategorySettings(),
      diaper: json['diaper'] != null
          ? ReminderCategorySettings.fromJson(json['diaper'] as Map<String, dynamic>)
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
