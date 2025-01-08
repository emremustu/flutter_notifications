import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  const androidChannel = AndroidNotificationChannel(
    'water_reminder_channel',
    'Water Reminder',
    description: 'Channel for water reminder notifications',
    importance: Importance.max,
    playSound: true,
    enableLights: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

  const initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initializationSettingsIOS = DarwinInitializationSettings();
  const initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      home: const WaterReminderPage(),
    );
  }
}

class WaterReminderPage extends StatefulWidget {
  const WaterReminderPage({super.key});

  @override
  State<WaterReminderPage> createState() => _WaterReminderPageState();
}

class _WaterReminderPageState extends State<WaterReminderPage> {
  int _reminderInterval = 30;
  Timer? _reminderTimer;
  String _timeUnit = 'minutes';
  bool isReminderActive = false;

  @override
  void initState() {
    super.initState();
  }

  Duration _getDuration() {
    switch (_timeUnit) {
      case 'seconds':
        return Duration(seconds: _reminderInterval);
      case 'hours':
        return Duration(hours: _reminderInterval);
      default:
        return Duration(minutes: _reminderInterval);
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  Future<void> _scheduleNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Water Reminder',
      channelDescription: 'Channel for water reminder notifications',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      playSound: true,
      enableLights: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Reminder',
      'Water Time',
      notificationDetails,
    );
  }

  void _startReminder() {
    if (_timeUnit == 'hours' && _reminderInterval > 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Interval for hours cannot exceed 24.')),
      );
      return;
    }

    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(
      _getDuration(),
      (_) => _scheduleNotification(),
    );

    setState(() {
      isReminderActive = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for every $_reminderInterval $_timeUnit')),
    );
  }

  void _stopReminder() {
    _reminderTimer?.cancel();
    setState(() {
      isReminderActive = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder stopped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<int> dropdownItems = List.generate(
      _timeUnit == 'hours' ? 24 : 120,
      (index) => index + 1,
    );

    if (!dropdownItems.contains(_reminderInterval)) {
      _reminderInterval = dropdownItems.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Reminder'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  ' Water Reminding Reminder',
                  style: TextStyle(fontSize: 20,),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                   
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _reminderInterval,
                      items: dropdownItems
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.toString()),
                              ))
                          .toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _reminderInterval = newValue;
                          });
                        }
                      },
                    ),
                    SizedBox(width: 100,),
                     DropdownButton<String>(
                      value: _timeUnit,
                      items: ['seconds', 'minutes', 'hours']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _timeUnit = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 100),
                
                SizedBox(
                  
                  child: Container(
                    margin: EdgeInsets.only(top:300),
                    child: ElevatedButton(
                      onPressed: isReminderActive ? _stopReminder : _startReminder,
                      child: Text(isReminderActive ? 'Stop Reminder' : 'Start Reminder'),
                    ),
                  ),
                ),
                if (isReminderActive)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Reminder active: Every $_reminderInterval $_timeUnit'),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
