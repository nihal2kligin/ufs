import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ufs/home/home.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  await GetStorage.init();
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Use dark theme
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Set background color to black
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark, // Use dark theme
        ),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}
