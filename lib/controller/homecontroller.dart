import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ufs/api/api.dart';
import 'package:ufs/model/alarmmodel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/services.dart';

class HomeController extends GetxController {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  List<AlarmModel> alarms = [];
  final box = GetStorage();
  static const platform = MethodChannel('com.example.ufs/permissions');
  List current_weather = [];
  List current_weather_units = [];
  bool weatherLoaded = false;

  @override
  void onInit() async {
    super.onInit();
    await _requestPermissions();
    tz.initializeTimeZones(); // Initialize timezone data
    initializeNotifications();
    loadAlarms();
    fetchWeather();
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

  void initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidInitializationSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const androidNotificationChannel = AndroidNotificationChannel(
      'alarm_channel_id',
      'Alarm Channel',
      description: 'This channel is used for alarm notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('swipe_sound.mp3'),
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  void loadAlarms() {
    List<dynamic> storedAlarms = box.read('alarms') ?? [];
    alarms = storedAlarms.map((alarm) => AlarmModel.fromMap(alarm)).toList();
    update();
  }

  Future<void> setAlarm(AlarmModel alarm) async {
    try {
      final alarmTime = _calculateAlarmTime(alarm);
      const androidDetails = AndroidNotificationDetails(
        'alarm_channel_id',
        'Alarm Channel',
        importance: Importance.max,
        priority: Priority.high,
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
}
