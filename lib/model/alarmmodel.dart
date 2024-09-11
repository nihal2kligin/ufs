import 'package:flutter/material.dart';

class AlarmModel {
  String label;
  TimeOfDay time;
  bool isEnabled;

  AlarmModel(this.label, this.time, this.isEnabled);

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'hour': time.hour,
      'minute': time.minute,
      'isEnabled': isEnabled, // Include isEnabled in the map
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      map['label'],
      TimeOfDay(hour: map['hour'], minute: map['minute']),
      map['isEnabled'] ?? true, // Default to true if isEnabled is not present
    );
  }
}
