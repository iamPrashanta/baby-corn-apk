// lib/features/reminders/domain/models/alarm_profile_model.dart

class AlarmProfile {
  final String id;
  final String alarmType; // 'notification' or 'full_alarm'
  final String ringtoneUri; // 'default' | 'assets/audio/alarm.wav' | 'content://...'
  final String ringtoneTitle; // e.g., 'Morning Flower' or 'Phone Default Alarm'
  final bool vibrationEnabled;
  final int snoozeMinutes;
  final int autoDismissMinutes;
  // Phase 5: Google Clock-style gradual volume
  final bool gradualVolume;
  final int gradualVolumeDurationSeconds;

  const AlarmProfile({
    required this.id,
    this.alarmType = 'full_alarm',
    this.ringtoneUri = 'assets/audio/alarm.wav',
    this.ringtoneTitle = 'Baby Corn Soft Bell',
    this.vibrationEnabled = true,
    this.snoozeMinutes = 5,
    this.autoDismissMinutes = 15,
    this.gradualVolume = false,
    this.gradualVolumeDurationSeconds = 30,
  });

  factory AlarmProfile.fromJson(Map<String, dynamic> json) {
    return AlarmProfile(
      id: json['id'] as String,
      alarmType: json['alarmType'] as String? ?? 'full_alarm',
      ringtoneUri: json['ringtoneUri'] as String? ?? 'assets/audio/alarm.wav',
      ringtoneTitle: json['ringtoneTitle'] as String? ?? 'Baby Corn Soft Bell',
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      autoDismissMinutes: json['autoDismissMinutes'] as int? ?? 15,
      gradualVolume: json['gradualVolume'] as bool? ?? false,
      gradualVolumeDurationSeconds:
          json['gradualVolumeDurationSeconds'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarmType': alarmType,
      'ringtoneUri': ringtoneUri,
      'ringtoneTitle': ringtoneTitle,
      'vibrationEnabled': vibrationEnabled,
      'snoozeMinutes': snoozeMinutes,
      'autoDismissMinutes': autoDismissMinutes,
      'gradualVolume': gradualVolume,
      'gradualVolumeDurationSeconds': gradualVolumeDurationSeconds,
    };
  }

  AlarmProfile copyWith({
    String? id,
    String? alarmType,
    String? ringtoneUri,
    String? ringtoneTitle,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    int? autoDismissMinutes,
    bool? gradualVolume,
    int? gradualVolumeDurationSeconds,
  }) {
    return AlarmProfile(
      id: id ?? this.id,
      alarmType: alarmType ?? this.alarmType,
      ringtoneUri: ringtoneUri ?? this.ringtoneUri,
      ringtoneTitle: ringtoneTitle ?? this.ringtoneTitle,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
      gradualVolume: gradualVolume ?? this.gradualVolume,
      gradualVolumeDurationSeconds:
          gradualVolumeDurationSeconds ?? this.gradualVolumeDurationSeconds,
    );
  }
}
