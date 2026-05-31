// lib/features/reminders/domain/models/alarm_profile_model.dart

class AlarmProfile {
  final String id;
  final String alarmType; // 'notification' or 'full_alarm'
  final String ringtoneUri;
  final bool vibrationEnabled;
  final int snoozeMinutes;
  final int autoDismissMinutes;

  const AlarmProfile({
    required this.id,
    this.alarmType = 'full_alarm',
    this.ringtoneUri = 'default',
    this.vibrationEnabled = true,
    this.snoozeMinutes = 5,
    this.autoDismissMinutes = 15,
  });

  factory AlarmProfile.fromJson(Map<String, dynamic> json) {
    return AlarmProfile(
      id: json['id'] as String,
      alarmType: json['alarmType'] as String? ?? 'full_alarm',
      ringtoneUri: json['ringtoneUri'] as String? ?? 'default',
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 5,
      autoDismissMinutes: json['autoDismissMinutes'] as int? ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alarmType': alarmType,
      'ringtoneUri': ringtoneUri,
      'vibrationEnabled': vibrationEnabled,
      'snoozeMinutes': snoozeMinutes,
      'autoDismissMinutes': autoDismissMinutes,
    };
  }

  AlarmProfile copyWith({
    String? id,
    String? alarmType,
    String? ringtoneUri,
    bool? vibrationEnabled,
    int? snoozeMinutes,
    int? autoDismissMinutes,
  }) {
    return AlarmProfile(
      id: id ?? this.id,
      alarmType: alarmType ?? this.alarmType,
      ringtoneUri: ringtoneUri ?? this.ringtoneUri,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      autoDismissMinutes: autoDismissMinutes ?? this.autoDismissMinutes,
    );
  }
}
