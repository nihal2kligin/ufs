import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ufs/controller/homecontroller.dart';
import 'package:ufs/model/alarmmodel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final HomeController controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alarm Clock'),
            backgroundColor: Colors.black,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 4), // changes position of shadow
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Weather icon
                      Icon(
                        controller.weatherLoaded
                            ? (controller.current_weather[0]['is_day'] == 1
                            ? Icons.wb_sunny
                            : Icons.nightlight_round)
                            : Icons.error,
                        color: controller.weatherLoaded ?controller.current_weather[0]['is_day'] == 1 ?Colors.yellow:Colors.white : Colors.red,
                        size: 40.0,
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Temperature text
                            Text(
                              controller.weatherLoaded
                                  ? 'Temperature: ${controller.current_weather[0]['temperature']} ${controller.current_weather_units[0]['temperature']}'
                                  : 'Weather data not available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            // Windspeed text
                            if (controller.weatherLoaded)
                              Text(
                                'Windspeed: ${controller.current_weather[0]['windspeed']} ${controller.current_weather_units[0]['windspeed']}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = controller.alarms[index];
                      return GestureDetector(
                        onTap: (){
                          _editAlarmDialog(context, index, alarm);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if(alarm.label.isNotEmpty)
                                  Text(
                                    '${alarm.label}',
                                    style: const TextStyle(fontSize: 16.0),
                                ),
                                Text(
                                  '${alarm.time.format(context)}',
                                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    alarm.isEnabled ? Icons.toggle_on : Icons.toggle_off,
                                    color: alarm.isEnabled ? Colors.green : Colors.grey,
                                    size: 40,
                                  ),
                                  onPressed: () => controller.toggleAlarmStatus(index),
                                ),
                                // IconButton(
                                //   icon: const Icon(Icons.edit),
                                //   onPressed: () => _editAlarmDialog(context, index, alarm),
                                //   color: Colors.blue,
                                // ),
                                //
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addAlarmDialog(context),
            // onPressed: () => controller.initializeNotifications(),
            child: const Icon(Icons.add),
            backgroundColor: Colors.blueGrey[800],
          ),
        );
      },
    );
  }

  void _addAlarmDialog(BuildContext context) {
    String label = '';
    TimeOfDay time = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set Alarm',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Alarm Label',
                    hintStyle: TextStyle(color: Colors.white70), // Light color for hint text
                    prefixIcon: Icon(Icons.label, color: Colors.white), // Icon inside the text field
                    filled: true,
                    // fillColor: Colors.black.withOpacity(0.5), // Semi-transparent black background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding inside the text field
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16.0), // Text style
                  onChanged: (value) => label = value,
                ),

                const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () async {
                  TimeOfDay? selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    time = selectedTime;
                  }
                },
                icon: Icon(Icons.access_time, color: Colors.white), // Custom icon color
                label: const Text(
                  'Select Time',
                  style: TextStyle(
                    color: Colors.white, // Text color
                    fontSize: 16.0, // Text size
                    fontWeight: FontWeight.bold, // Text weight
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.5), // Transparent background to use gradient
                  // padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0), // Button padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  ),
                  elevation: 5.0, // Shadow effect
                ) // Custom gradient background extension
              ),




              const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (time!=null) {
                          controller.setAlarm(AlarmModel(label, time, true));
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Set',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _editAlarmDialog(BuildContext context, int index, AlarmModel alarm) {
    String label = alarm.label;
    TimeOfDay time = alarm.time;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Edit Alarm',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Enter Alarm Label',
                    hintStyle: TextStyle(color: Colors.white70), // Light color for hint text
                    prefixIcon: Icon(Icons.label, color: Colors.white), // Icon inside the text field
                    filled: true,
                    // fillColor: Colors.black.withOpacity(0.5), // Semi-transparent black background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.white, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: Colors.white54, width: 1.5),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding inside the text field
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16.0), // Text style
                  onChanged: (value) => label = value,
                ),

                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                    onPressed: () async {
                      TimeOfDay? selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        time = selectedTime;
                      }
                    },
                    icon: Icon(Icons.access_time, color: Colors.white), // Custom icon color
                    label: const Text(
                      'Select Time',
                      style: TextStyle(
                        color: Colors.white, // Text color
                        fontSize: 16.0, // Text size
                        fontWeight: FontWeight.bold, // Text weight
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.5), // Transparent background to use gradient
                      // padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0), // Button padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0), // Rounded corners
                      ),
                      elevation: 5.0, // Shadow effect
                    ) // Custom gradient background extension
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.deleteAlarm(index);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (time!=null) {
                          controller.editAlarm(index, AlarmModel(label, time, true));
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Update',style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}
