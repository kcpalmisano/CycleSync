

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

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
    await _notifications.show(Random().nextInt(100000), title, body, notificationDetails);
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
  int _daysUntilOvulation = 0;
  DateTime? _nextPeriodDate;

  final Map<String, List<String>> _adviceMap = {
    'Menstrual': [
      'Encourage rest and comfort.',
      'Keep the snacks coming and the heating pad warm.',
      'Extra cuddles go a long way this week.',
      'Be extra kind — it’s red alert in more ways than one.',
    ],
    'Follicular': [
      'Support her energy boost — plan something fun!',
      'Time to do things together — she’s back!',
      'Help her ride the productivity wave.',
      'The springtime of the cycle. Bring flowers?',
    ],
    'Ovulation': [
      '🚨 Baby-shaped consequences possible!',
      'Peak charm, peak fertility. Be wise.',
      'She’s glowing — don’t mess this up.',
      'Flirt like it’s the first date again.',
    ],
    'Luteal': [
      'Be patient — moods incoming.',
      'Time to be her rock, not a pebble.',
      'Avoid unnecessary debates. Seriously.',
      'Give space. Bring snacks.',
    ],
    'Pre-Menstrual': [
      'Storm’s a-brewin’. Stock up on empathy.',
      'Approach gently. Like a deer in the woods.',
      'It’s not you. It’s hormones.',
      'Chocolate may solve most issues right now.',
    ],
    'Post-Ovulation': [
      'Fertility window closing. You survived.',
      'Hormones recalibrating. Proceed carefully.',
      'Ride the slow wave down. Be chill.',
      'She’s easing down. Meet her there.',
    ],
  };

  final Map<String, String> _riskMap = {
    'Menstrual': 'Very Low – Just snacks and snuggles.',
    'Follicular': 'Medium – Might be safe... might not be.',
    'Ovulation': 'VERY High – 🚼 Baby-shaped consequences possible!',
    'Luteal': 'Low – Still time to name the goldfish instead.',
    'Pre-Menstrual': 'Very Low – The floodgates approach.',
    'Post-Ovulation': 'Medium – Sliding out of danger zone.',
  };

  Color _getBackgroundColor(String phase) {
    switch (phase) {
      case 'Menstrual':
        return Colors.red.shade300;
      case 'Follicular':
        return Colors.blueGrey.shade300;
      case 'Ovulation':
        return Colors.orange.shade400;
      case 'Luteal':
        return Colors.brown.shade300;
      case 'Pre-Menstrual':
        return Colors.red.shade100;
      case 'Post-Ovulation':
        return Colors.amber.shade200;
      default:
        return Colors.blueGrey.shade100;
    }
  }

  String _determinePhase(int day, int cycleLength) {
    if (day <= 5) return 'Menstrual';
    if (day <= 12) return 'Follicular';
    if (day <= 17) return 'Ovulation';
    if (day <= cycleLength - 3) return 'Luteal';
    if (day <= cycleLength - 1) return 'Pre-Menstrual';
    return 'Menstrual';
  }

  void _scheduleReminders(int cycleLength) {
    for (int i = 0; i < cycleLength; i++) {
      final reminderDate = _lastPeriodDate.add(Duration(days: i - 1));
      final phase = _determinePhase(i + 1, cycleLength);
      final phrase = _adviceMap[phase]?[Random().nextInt(4)] ?? 'Be thoughtful.';
      NotificationService().showNotification('Reminder: $phase phase tomorrow', phrase);
    }
  }

  void _predictPhase() {
    final cycleLength = int.tryParse(_cycleLengthController.text) ?? 28;
    final today = DateTime.now();
    final daysSincePeriod = today.difference(_lastPeriodDate).inDays % cycleLength;
    final week = (daysSincePeriod ~/ 7) + 1;

    final phase = _determinePhase(daysSincePeriod + 1, cycleLength);
    final ovulationStart = 13;
    final ovulationEnd = 17;
    final daysUntilOvulation = (daysSincePeriod < ovulationStart)
        ? (ovulationStart - daysSincePeriod)
        : (cycleLength - daysSincePeriod + ovulationStart);

    final nextPeriod = _lastPeriodDate.add(Duration(days: cycleLength));

    setState(() {
      _currentDay = daysSincePeriod + 1;
      _currentWeek = week;
      _phase = phase;
      _advice = _adviceMap[phase]?[Random().nextInt(4)] ?? '';
      _pregnancyRisk = _riskMap[phase] ?? '';
      _daysUntilOvulation = daysUntilOvulation;
      _nextPeriodDate = nextPeriod;
    });

    _scheduleReminders(cycleLength);
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
            const SizedBox(height: 12),
            Text("Days until Ovulation: $_daysUntilOvulation",
                style: const TextStyle(fontSize: 16)),
            if (_nextPeriodDate != null)
              Text("Next Period: ${DateFormat.yMMMd().format(_nextPeriodDate!)}",
                  style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}





