import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:ufs/api/api.dart';
import 'package:ufs/model/alarmmodel.dart';

class HomeController extends GetxController {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<AlarmModel> alarms = [];
  final box = GetStorage();
  List current_weather = [];
  List current_weather_units = [];
  bool weatherLoaded = false;

  @override
  void onInit() async {
    super.onInit();
    await _requestPermissions();
    tz.initializeTimeZones(); // Initialize timezone data
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await initializeNotifications(); // Ensure notifications are initialized before use
    loadAlarms();
    fetchWeather();
    await schedulePeriodicChecks();
  }

  Future<void> _requestPermissions() async {
    await Permission.location.request();
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  void toggleAlarmStatus(int index) {
    final alarm = alarms[index];
    alarms[index] = AlarmModel(alarm.label, alarm.time, !alarm.isEnabled);
    update(); // Notify listeners
  }

  Future<void> fetchWeather() async {
    try {
      var position = await getCurrentLocation();
      var weather = await getWeather(position.latitude, position.longitude);
      current_weather = [weather['current_weather']];
      current_weather_units = [weather['current_weather_units']];
      weatherLoaded = true;
    } catch (e) {
      print('Error fetching weather: $e');
      weatherLoaded = false;
    } finally {
      update(); // Notify listeners to update the UI
    }
  }

  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        throw Exception('Location permissions are denied');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> initializeNotifications() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alarm_channel_id', // ID
      'Alarm Channel', // Name
      description: 'This channel is used for alarm notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('notification'), // Ensure you have a sound file named `notification` in `res/raw`
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap or other user interactions
        print('Notification tapped with payload: ${response.payload}');
      },
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> setAlarm(AlarmModel alarm) async {
    try {
      final alarmTime = _calculateAlarmTime(alarm);
      print('Setting alarm for: ${alarmTime.toLocal()}'); // Debug log

      const androidDetails = AndroidNotificationDetails(
        'alarm_channel_id',
        'Alarm Channel',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // Make notification persistent
        autoCancel: false, // Prevent automatic dismissal
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        alarms.length,
        'Alarm',
        alarm.label,
        alarmTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      alarms.add(alarm);
      _saveAlarms();
      update();
    } on PlatformException catch (e) {
      print('PlatformException: ${e.message}');
    }
  }

  tz.TZDateTime _calculateAlarmTime(AlarmModel alarm) {
    final now = tz.TZDateTime.now(tz.local);
    final alarmTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // Set alarm to the next day if it's already past the current time
    return alarmTime.isBefore(now) ? alarmTime.add(Duration(days: 1)) : alarmTime;
  }

  Future<void> editAlarm(int index, AlarmModel updatedAlarm) async {
    await flutterLocalNotificationsPlugin.cancel(index);

    alarms[index] = updatedAlarm;
    final alarmTime = _calculateAlarmTime(updatedAlarm);

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarm Channel',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Make notification persistent
      autoCancel: false, // Prevent automatic dismissal
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      index,
      'Alarm',
      updatedAlarm.label,
      alarmTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _saveAlarms();
    update();
  }

  Future<void> deleteAlarm(int index) async {
    await flutterLocalNotificationsPlugin.cancel(index);
    alarms.removeAt(index);
    _saveAlarms();
    update();
  }

  Future<void> checkExactAlarmPermission() async {
    await Permission.scheduleExactAlarm.request();
    if (Platform.isAndroid) {
      final status = await Permission.scheduleExactAlarm.status;
      if (!status.isGranted) {
        final requestResult = await Permission.scheduleExactAlarm.request();
        if (requestResult != PermissionStatus.granted) {
          // Handle permission denied scenario (e.g., show a message to user)
        }
      }
    }
  }

  void _navigateToExactAlarmSettings() {
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    intent.launch();
  }

  void _saveAlarms() {
    List<Map<String, dynamic>> storedAlarms = alarms.map((alarm) => alarm.toMap()).toList();
    box.write('alarms', storedAlarms);
  }

  void loadAlarms() {
    List<dynamic> storedAlarms = box.read('alarms') ?? [];
    alarms = storedAlarms.map((alarm) => AlarmModel.fromMap(alarm)).toList();
    update();
  }

  Future<void> alarmService() async {
    final now = tz.TZDateTime.now(tz.local);

    for (var alarm in alarms) {
      final alarmTime = _calculateAlarmTime(alarm);

      if (alarmTime.isBefore(now) || alarmTime.isAtSameMomentAs(now)) {
        const androidDetails = AndroidNotificationDetails(
          'alarm_channel_id',
          'Alarm Channel',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true, // Make notification persistent
          autoCancel: false, // Prevent automatic dismissal
        );

        const notificationDetails = NotificationDetails(android: androidDetails);

        await flutterLocalNotificationsPlugin.show(
          alarms.indexOf(alarm),
          'Alarm',
          alarm.label,
          notificationDetails,
          payload: 'item x',
        );
      }
    }
  }

  Future<void> schedulePeriodicChecks() async {
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 1),
      0, // Alarm ID
      alarmService,
    );
  }
}
