

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const CycleSyncApp());
}

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'cycle_channel',
      'Cycle Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notifications.show(0, title, body, notificationDetails);
  }
}

class CycleSyncApp extends StatelessWidget {
  const CycleSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CycleSync',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const CycleTracker(),
    );
  }
}

class CycleTracker extends StatefulWidget {
  const CycleTracker({super.key});

  @override
  State<CycleTracker> createState() => _CycleTrackerState();
}

class _CycleTrackerState extends State<CycleTracker> {
  DateTime _lastPeriodDate = DateTime.now().subtract(const Duration(days: 10));
  final TextEditingController _cycleLengthController = TextEditingController(text: '28');
  String _phase = '';
  String _advice = '';
  String _pregnancyRisk = '';
  int _currentDay = 0;
  int _currentWeek = 0;

  final Map<int, String> _phaseMap = {
    1: 'Menstrual',
    2: 'Follicular',
    3: 'Ovulation',
    4: 'Luteal',
  };

  final Map<String, String> _adviceMap = {
    'Menstrual': 'Encourage rest and comfort. Be extra caring.',
    'Follicular': 'Support her energy! Plan activities or goals together.',
    'Ovulation': "Remind her she's gorgeous. Plan a spicy date!",
    'Luteal': 'Be patient and understanding. Lower pressure, more support.',
  };

  final Map<String, String> _riskMap = {
    'Menstrual': '🟢 Very Low – Just snacks and snuggles.',
    'Follicular': '🟡 Medium – Might be safe... might not be.',
    'Ovulation': '🔴 VERY High – 🚼 Baby-shaped consequences possible!',
    'Luteal': '🟡 Low – Still time to name the goldfish instead.',
  };

  Color _getBackgroundColor(String phase) {
    switch (phase) {
      case 'Menstrual':
        return Colors.red.shade200;
      case 'Follicular':
        return Colors.teal.shade200;
      case 'Ovulation':
        return Colors.indigo.shade300;
      case 'Luteal':
        return Colors.amber.shade200;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  void _predictPhase() {
    final cycleLength = int.tryParse(_cycleLengthController.text) ?? 28;
    final today = DateTime.now();
    final daysSincePeriod = today.difference(_lastPeriodDate).inDays % cycleLength;
    final week = (daysSincePeriod ~/ 7) + 1;

    setState(() {
      _currentDay = daysSincePeriod + 1;
      _currentWeek = week;
      _phase = _phaseMap[week] ?? 'Unknown';
      _advice = _adviceMap[_phase] ?? '';
      _pregnancyRisk = _riskMap[_phase] ?? '';
    });
  }

  void _sendReminder() {
    NotificationService().showNotification(
      'Cycle Reminder: $_phase',
      _advice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(_phase),
      appBar: AppBar(title: const Text('CycleSync')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Track Your Partner's Cycle",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Last period: ${DateFormat.yMMMd().format(_lastPeriodDate)}"),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _lastPeriodDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _lastPeriodDate = picked);
                    }
                  },
                  child: const Text('Pick Date'),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cycleLengthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cycle Length (days)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _predictPhase,
              child: const Text('Predict Phase'),
            ),
            const SizedBox(height: 24),
            Text("Current Phase: $_phase",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("Day: $_currentDay",
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_advice, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text("Pregnancy Risk: $_pregnancyRisk",
                style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendReminder,
              child: const Text("Send Today's Reminder"),
            ),
          ],
        ),
      ),
    );
  }
}





