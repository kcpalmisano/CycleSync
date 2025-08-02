
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones(); // Required for timezone support
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

  Future<void> scheduleDailyReminder(String title, String body, DateTime dateTime) async {
    const androidDetails = AndroidNotificationDetails(
      'cycle_channel',
      'Cycle Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      Random().nextInt(100000),
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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
  final TextEditingController _reminderTimeController = TextEditingController();
  String _phase = '';
  String _advice = '';
  String _pregnancyRisk = '';
  int _currentDay = 0;
  DateTime? _nextPeriodDate;
  String _ovulationWindow = '';
  String _progressBar = '';
  bool _redAlert = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderTimeController.text = prefs.getString('reminderTime') ?? '08:00';
    setState(() {
      _redAlert = prefs.getBool('redAlert') ?? false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reminderTime', _reminderTimeController.text);
    await prefs.setBool('redAlert', _redAlert);
  }

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
      'Baby-shaped consequences possible!',
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
    'Ovulation': 'VERY High – Baby-shaped consequences possible!',
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

  void _scheduleReminders(int cycleLength) async {
    final reminderTime = _reminderTimeController.text;
    final parts = reminderTime.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    for (int i = 0; i < cycleLength; i++) {
      final date = _lastPeriodDate.add(Duration(days: i));
      final phase = _determinePhase(i + 1, cycleLength);
      final phrase = _adviceMap[phase]?[Random().nextInt(4)] ?? 'Be thoughtful.';
      final DateTime notificationTime = DateTime(date.year, date.month, date.day, hour, minute);
      await NotificationService().scheduleDailyReminder('Reminder: $phase phase', phrase, notificationTime);
    }
  }

  void _predictPhase() {
    final cycleLength = int.tryParse(_cycleLengthController.text) ?? 28;
    final today = DateTime.now();
    final daysSincePeriod = today.difference(_lastPeriodDate).inDays % cycleLength;
    final phase = _determinePhase(daysSincePeriod + 1, cycleLength);
    final ovulationPeak = 14;
    final ovulationWindowStart = _lastPeriodDate.add(Duration(days: ovulationPeak - 2));
    final ovulationWindowEnd = _lastPeriodDate.add(Duration(days: ovulationPeak + 2));
    final ovulationPeakDate = _lastPeriodDate.add(Duration(days: ovulationPeak));
    final nextPeriod = _lastPeriodDate.add(Duration(days: cycleLength));

    final filledLength = min(daysSincePeriod + 1, cycleLength);
    final barLength = min(cycleLength, 28);
    final filled = '▓' * min(filledLength, barLength);
    final unfilled = '░' * (barLength - min(filledLength, barLength));
    final bar = '$filled$unfilled';

    setState(() {
      _currentDay = daysSincePeriod + 1;
      _phase = phase;
      _advice = _adviceMap[phase]?[Random().nextInt(4)] ?? '';
      _pregnancyRisk = _riskMap[phase] ?? '';
      _nextPeriodDate = nextPeriod;
      _ovulationWindow =
          'Ovulation Window: ${DateFormat.MMMd().format(ovulationWindowStart)} – ${DateFormat.MMMd().format(ovulationWindowEnd)} (peak: ${DateFormat.MMMd().format(ovulationPeakDate)})';
      _progressBar = bar;
    });

    _scheduleReminders(cycleLength);
    _savePrefs();
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _reminderTimeController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(labelText: 'Reminder Time (HH:mm)'),
            ),
            SwitchListTile(
              title: const Text("Red Alert Mode"),
              value: _redAlert,
              onChanged: (val) {
                setState(() => _redAlert = val);
                _savePrefs();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(_phase),
      appBar: AppBar(
        title: const Text('CycleSync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsDialog,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Track Your Partner's Cycle",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
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
            ElevatedButton(onPressed: _predictPhase, child: const Text('Predict Phase')),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text("Current Phase: $_phase",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(_advice, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text("Pregnancy Risk: $_pregnancyRisk",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(_ovulationWindow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  if (_nextPeriodDate != null)
                    Text("Next Period: ${DateFormat.yMMMd().format(_nextPeriodDate!)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text(_progressBar,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Courier', fontSize: 16)),
                  const SizedBox(height: 4),
                  Text("(Day $_currentDay of ${_cycleLengthController.text})",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





