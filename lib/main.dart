import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fl_location/fl_location.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class FirstTaskHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _streamSubscription =
        FlLocation.getLocationStream().listen((location) async {
      FlutterForegroundTask.updateService(
        notificationTitle: 'My Location',
        notificationText: '${location.latitude}, ${location.longitude}',
      );

      await _writeData('-> ${location.toString()} <-\n');

      // Send data to the main isolate.
      sendPort?.send(location.toString());
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _streamSubscription?.cancel();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String data = '';

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<bool> _checkAndRequestPermission({bool? background}) async {
    if (!await FlLocation.isLocationServicesEnabled) {
      // Location services are disabled.
      return false;
    }

    var locationPermission = await FlLocation.checkLocationPermission();
    if (locationPermission == LocationPermission.deniedForever) {
      // Cannot request runtime permission because location permission is denied forever.
      return false;
    } else if (locationPermission == LocationPermission.denied) {
      // Ask the user for location permission.
      locationPermission = await FlLocation.requestLocationPermission();
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) return false;
    }

    // Location permission must always be allowed (LocationPermission.always)
    // to collect location data in the background.
    if (background == true &&
        locationPermission == LocationPermission.whileInUse) return false;

    // Location services has been enabled and permission have been granted.
    return true;
  }

  Future<void> _onData(dynamic data) async {
    if (data is int) {
      print('eventCount ->: $data');
    }
    // else if (data is Location) {
    //   print('location ->: ${data.toString()}');
    //   final date = DateTime.now().toString();
    //   await _writeData('${data.toString()}, $date\n');
    // }
    else if (data is String) {
      if (data == 'onNotificationPressed') {
        Navigator.of(context).pushNamed('/resume-route');
      } else {
        print('location ->: ${data}');
        final date = DateTime.now().toString();
        await _writeData('$data, $date\n');
      }
    } else if (data is DateTime) {
      print('timestamp: ${data.toString()}');
    }

    // Location location = Location.fromJson(data);

    // print('location ->: ${location}');
    // final date = DateTime.now().toString();
    // await _writeData('${location.toString()}, $date\n');
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionForAndroid();
    _checkAndRequestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // A widget that can start the foreground service when the app is minimized or closed.
      // This widget must be declared above the [Scaffold] widget.
      home: WillStartForegroundTask(
        onWillStart: () async {
          // Return whether to start the foreground service.
          return true;
        },
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'foreground_service',
          channelName: 'Foreground Service Notification',
          channelDescription:
              'This notification appears when the foreground service is running.',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          isSticky: false, // important
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
          buttons: [
            const NotificationButton(id: 'sendButton', text: 'Send'),
            const NotificationButton(id: 'testButton', text: 'Test'),
          ],
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: true,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          isOnceEvent: false,
          allowWakeLock: false,
          allowWifiLock: false,
        ),
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
        onData: _onData,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Foreground Task'),
            centerTitle: true,
          ),
          body: _buildContentView(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    buttonBuilder(String text, {VoidCallback? onPressed}) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttonBuilder('Read Data', onPressed: () async {
            data = await _readData();
            setState(() {});
          }),
          SizedBox(
            height: 500,
            child: SingleChildScrollView(
              child: Text(data),
            ),
          )
        ],
      ),
    );
  }

  Future<String> _readData() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/my_file_location.txt');

    if (await file.exists()) {
      return await file.readAsString();
    }

    return 'File not exists';
  }
}

Future<void> _writeData(String text) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final File file = File('${directory.path}/my_file_location.txt');

  String data = '...';
  if (await file.exists()) {
    data = await file.readAsString();
  }

  await file.writeAsString(data + text);
}
