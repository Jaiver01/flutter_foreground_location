import 'dart:io';

import 'package:background_location/background_location.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String latitude = 'waiting...';
  String longitude = 'waiting...';
  String altitude = 'waiting...';
  String accuracy = 'waiting...';
  String bearing = 'waiting...';
  String speed = 'waiting...';
  String time = 'waiting...';
  String data = 'waiting...';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Background Location Service'),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              locationData('Latitude: $latitude'),
              locationData('Longitude: $longitude'),
              locationData('Altitude: $altitude'),
              locationData('Accuracy: $accuracy'),
              locationData('Bearing: $bearing'),
              locationData('Speed: $speed'),
              locationData('Time: $time'),
              ElevatedButton(
                  onPressed: () async {
                    await _checkPermissions();

                    await BackgroundLocation.setAndroidNotification(
                      title: 'Background service is running',
                      message: 'Background location in progress',
                      icon: '@mipmap/ic_launcher',
                    );
                    //await BackgroundLocation.setAndroidConfiguration(1000);
                    await BackgroundLocation.startLocationService(
                      distanceFilter: 20,
                    );
                    BackgroundLocation.getLocationUpdates((location) async {
                      setState(() {
                        latitude = location.latitude.toString();
                        longitude = location.longitude.toString();
                        accuracy = location.accuracy.toString();
                        altitude = location.altitude.toString();
                        bearing = location.bearing.toString();
                        speed = location.speed.toString();
                        time = DateTime.fromMillisecondsSinceEpoch(
                                location.time!.toInt())
                            .toString();
                      });

                      await _writeData('''-------------------------------
Latitude:  $latitude
Longitude: $longitude
Altitude: $altitude
Accuracy: $accuracy
Bearing:  $bearing
Speed: $speed
Time: $time
-----------------------------------------------
\n\n
                      ''');

                      print('''\n
                        Latitude:  $latitude
                        Longitude: $longitude
                        Altitude: $altitude
                        Accuracy: $accuracy
                        Bearing:  $bearing
                        Speed: $speed
                        Time: $time
                      ''');
                    });
                  },
                  child: const Text('Start Location Service')),
              ElevatedButton(
                  onPressed: () {
                    BackgroundLocation.stopLocationService();
                  },
                  child: const Text('Stop Location Service')),
              ElevatedButton(
                  onPressed: () {
                    getCurrentLocation();
                  },
                  child: const Text('Get Current Location')),
              ElevatedButton(
                onPressed: () async => {
                  data = await _readData(),
                  setState(() {}),
                },
                child: const Text('Read Data'),
              ),
              Text(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget locationData(String data) {
    return Text(
      data,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  void getCurrentLocation() {
    BackgroundLocation().getCurrentLocation().then((location) {
      print('This is current Location ${location.toMap()}');
    });
  }

  _writeData(String text) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');

    String data = '...';
    if (await file.exists()) {
      data = await file.readAsString();
    }

    await file.writeAsString(data + text);
  }

  Future<String> _readData() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file.txt');

    if (await file.exists()) {
      return await file.readAsString();
    }

    return 'File not exists';
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      var status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        var status = await Permission.locationAlways.request();
        if (status.isGranted) {
          //Do some stuff
        } else {
          //Do another stuff
        }
      } else {
        //The user deny the permission
      }
      if (status.isPermanentlyDenied) {
        //When the user previously rejected the permission and select never ask again
        //Open the screen of settings
        bool res = await openAppSettings();
      }
    } else {
      //In use is available, check the always in use
      var status = await Permission.locationAlways.status;
      if (!status.isGranted) {
        var status = await Permission.locationAlways.request();
        if (status.isGranted) {
          //Do some stuff
        } else {
          //Do another stuff
        }
      } else {
        //previously available, do some stuff or nothing
      }
    }
  }

  @override
  void dispose() {
    BackgroundLocation.stopLocationService();
    super.dispose();
  }
}
