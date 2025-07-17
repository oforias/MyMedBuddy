import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for TimeOfDay

class Appointment {
  final String title;
  final DateTime dateTime;

  Appointment({required this.title, required this.dateTime});

  Map<String, dynamic> toJson() => {
    'title': title,
    'dateTime': dateTime.toIso8601String(),
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    title: json['title'],
    dateTime: DateTime.parse(json['dateTime']),
  );

  @override
  String toString() => '$title - ${dateTime.toLocal()}';
}

class Medication {
  final String name;
  final String dose;
  final List<String> times; // Store as HH:mm strings for easier serialization
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notes;

  Medication({
    required this.name,
    required this.dose,
    required this.times,
    this.startDate,
    this.endDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'dose': dose,
    'times': times,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'notes': notes,
  };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    name: json['name'],
    dose: json['dose'],
    times: List<String>.from(json['times'] ?? []),
    startDate: json['startDate'] != null
        ? DateTime.parse(json['startDate'])
        : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    notes: json['notes'],
  );

  @override
  String toString() => '$name ($dose) at ${times.join(', ')}';
}

class HealthLogEntry {
  final String text;
  final DateTime timestamp;
  HealthLogEntry({required this.text, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HealthLogEntry.fromJson(Map<String, dynamic> json) => HealthLogEntry(
    text: json['text'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class AppState extends ChangeNotifier {
  // User info
  String? name;
  String? age;
  String? condition;
  String? reminders;

  // Reminders toggle
  bool remindersEnabled = false;

  // Health logs
  List<HealthLogEntry> healthLogs = [];

  void setUser({
    required String name,
    required String age,
    required String condition,
    required String reminders,
  }) {
    this.name = name;
    this.age = age;
    this.condition = condition;
    this.reminders = reminders;
    notifyListeners();
  }

  Future<void> saveHealthLogsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsJson = healthLogs.map((e) => e.toJson()).toList();
    await prefs.setString('health_logs', jsonEncode(logsJson));
  }

  Future<void> loadHealthLogsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final logsString = prefs.getString('health_logs');
    if (logsString != null) {
      final decoded = jsonDecode(logsString);
      if (decoded is List) {
        healthLogs = decoded.map((e) => HealthLogEntry.fromJson(e)).toList();
      }
    } else {
      // Migration: check for old string list
      final oldLogs = prefs.getStringList('health_logs');
      if (oldLogs != null) {
        healthLogs = oldLogs
            .map((e) => HealthLogEntry(text: e, timestamp: DateTime.now()))
            .toList();
        await saveHealthLogsToPrefs();
      }
    }
    notifyListeners();
  }

  void addHealthLog(String log) {
    healthLogs.add(HealthLogEntry(text: log, timestamp: DateTime.now()));
    saveHealthLogsToPrefs();
    notifyListeners();
  }

  void removeHealthLog(int index) {
    healthLogs.removeAt(index);
    saveHealthLogsToPrefs();
    notifyListeners();
  }

  // Appointments
  List<Appointment> appointments = [];
  Future<void> saveAppointmentsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final apptJson = appointments.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('appointments', apptJson);
  }

  Future<void> loadAppointmentsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apptJson = prefs.getStringList('appointments');
      if (apptJson != null) {
        appointments = apptJson
            .map((str) => Appointment.fromJson(jsonDecode(str)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading appointments: $e');
      appointments = [];
      notifyListeners();
    }
  }

  void addAppointment(Appointment appt) {
    appointments.add(appt);
    saveAppointmentsToPrefs();
    notifyListeners();
  }

  void removeAppointment(int index) {
    appointments.removeAt(index);
    saveAppointmentsToPrefs();
    notifyListeners();
  }

  // Medications
  List<Medication> medications = [];
  Future<void> saveMedicationsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final medsJson = medications.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('medications', medsJson);
  }

  Future<void> loadMedicationsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medsJson = prefs.getStringList('medications');
      if (medsJson != null) {
        medications = medsJson
            .map((str) => Medication.fromJson(jsonDecode(str)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading medications: $e');
    }
  }

  void addMedication(Medication med) {
    medications.add(med);
    saveMedicationsToPrefs();
    notifyListeners();
  }

  void removeMedication(int index) {
    medications.removeAt(index);
    saveMedicationsToPrefs();
    notifyListeners();
  }

  /// Returns the next scheduled medication and its DateTime, or null if none.
  MapEntry<Medication, DateTime>? getNextMedication() {
    final now = DateTime.now();
    List<MapEntry<Medication, DateTime>> upcoming = [];
    for (final med in medications) {
      // Check if medication is active (start/end date)
      final isActive =
          (med.startDate == null || !now.isBefore(med.startDate!)) &&
          (med.endDate == null || !now.isAfter(med.endDate!));
      if (!isActive) continue;
      for (final t in med.times) {
        // Try to parse as HH:mm (24h)
        DateTime? medTime;
        final parts = t.split(":");
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(
            parts[1].replaceAll(RegExp(r'[^0-9]'), ''),
          );
          if (hour != null && minute != null) {
            medTime = DateTime(now.year, now.month, now.day, hour, minute);
            if (medTime.isBefore(now)) {
              medTime = medTime.add(const Duration(days: 1));
            }
            upcoming.add(MapEntry(med, medTime));
            continue;
          }
        }
        // Try to parse as locale time (e.g., 8:00 AM)
        final timeReg = RegExp(
          r'^(\d{1,2}):(\d{2}) ?([AP]M)?',
          caseSensitive: false,
        );
        final match = timeReg.firstMatch(t);
        if (match != null) {
          int hour = int.parse(match.group(1)!);
          int minute = int.parse(match.group(2)!);
          final ampm = match.group(3)?.toUpperCase();
          if (ampm == 'PM' && hour < 12) hour += 12;
          if (ampm == 'AM' && hour == 12) hour = 0;
          medTime = DateTime(now.year, now.month, now.day, hour, minute);
          if (medTime.isBefore(now)) {
            medTime = medTime.add(const Duration(days: 1));
          }
          upcoming.add(MapEntry(med, medTime));
        }
      }
    }
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.value.compareTo(b.value));
    return upcoming.first;
  }

  // Track taken doses: date string -> set of dose IDs (medName|time)
  Map<String, Set<String>> takenDoses = {};

  Future<void> loadTakenDosesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mapString = prefs.getString('taken_doses');
    if (mapString != null) {
      final decoded = jsonDecode(mapString) as Map<String, dynamic>;
      takenDoses = decoded.map((k, v) => MapEntry(k, Set<String>.from(v)));
    }
    notifyListeners();
  }

  Future<void> saveTakenDosesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(takenDoses);
    await prefs.setString('taken_doses', json);
  }

  bool isDoseTaken(String medName, String time, DateTime date) {
    final doseId = '$medName|$time';
    return takenDoses[dateString(date)]?.contains(doseId) ?? false;
  }

  String dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Returns a map of date string (yyyy-MM-dd) to list of missed doses (medName, time) for the past 7 days.
  Map<String, List<Map<String, String>>> getMissedDosesPastWeek() {
    final now = DateTime.now();
    Map<String, List<Map<String, String>>> missed = {};
    for (int i = 1; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = dateString(date);
      List<Map<String, String>> missedForDay = [];
      for (final med in medications) {
        // Check if medication is active on this date
        final isActive =
            (med.startDate == null || !date.isBefore(med.startDate!)) &&
            (med.endDate == null || !date.isAfter(med.endDate!));
        if (!isActive) continue;
        for (final t in med.times) {
          if (!isDoseTaken(med.name, t, date)) {
            missedForDay.add({
              'medName': med.name,
              'dose': med.dose,
              'time': t,
            });
          }
        }
      }
      if (missedForDay.isNotEmpty) {
        missed[dateStr] = missedForDay;
      }
    }
    return missed;
  }

  /// Returns a list of missed doses (medName, dose, time) for a specific date.
  List<Map<String, String>> getMissedDosesForDay(DateTime date) {
    final dateStr = dateString(date);
    List<Map<String, String>> missedForDay = [];
    for (final med in medications) {
      final isActive =
          (med.startDate == null || !date.isBefore(med.startDate!)) &&
          (med.endDate == null || !date.isAfter(med.endDate!));
      if (!isActive) continue;
      for (final t in med.times) {
        if (!isDoseTaken(med.name, t, date)) {
          missedForDay.add({'medName': med.name, 'dose': med.dose, 'time': t});
        }
      }
    }
    return missedForDay;
  }

  // Dark mode toggle
  bool darkModeEnabled = false;

  Future<void> loadDarkModeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    notifyListeners();
  }

  Future<void> saveDarkModeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', darkModeEnabled);
  }

  void setDarkModeEnabled(bool value) {
    darkModeEnabled = value;
    saveDarkModeToPrefs();
    notifyListeners();
  }

  // Cached compliance streaks
  int? _currentComplianceStreak;
  int? _bestComplianceStreak;
  bool _streaksCalculating = false;
  bool get streaksCalculating => _streaksCalculating;

  int get currentComplianceStreak => _currentComplianceStreak ?? 0;
  int get bestComplianceStreak => _bestComplianceStreak ?? 0;

  /// Recalculate and cache compliance streaks
  Future<void> recalculateComplianceStreaks() async {
    _streaksCalculating = true;
    notifyListeners();
    try {
      final streaks =
          await compute(_calculateStreaksInIsolate, {
            'medications': medications.map((m) => m.toJson()).toList(),
            'takenDoses': takenDoses.map((k, v) => MapEntry(k, v.toList())),
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return {'current': 0, 'best': 0};
            },
          );
      _currentComplianceStreak = streaks['current'];
      _bestComplianceStreak = streaks['best'];
    } catch (e, st) {
      print('Error in compliance streak isolate: $e\n$st');
      _currentComplianceStreak = 0;
      _bestComplianceStreak = 0;
    }
    _streaksCalculating = false;
    notifyListeners();
  }

  // Helper for compute
  static Map<String, int> _calculateStreaksInIsolate(Map args) {
    final meds = (args['medications'] as List)
        .map((m) => Medication.fromJson(m as Map<String, dynamic>))
        .toList();
    final taken = (args['takenDoses'] as Map).map(
      (k, v) => MapEntry(k as String, Set<String>.from(v as List)),
    );
    int current = 0;
    int best = 0;
    int streak = 0;
    final now = DateTime.now();
    // Current streak
    for (int i = 0; i < 400; i++) {
      // safety break after 400 days
      final date = now.subtract(Duration(days: i));
      bool allTaken = true;
      bool activeMedFound = false;
      for (final med in meds) {
        final isActive =
            (med.startDate == null || !date.isBefore(med.startDate!)) &&
            (med.endDate == null || !date.isAfter(med.endDate!));
        if (!isActive) continue;
        activeMedFound = true;
        for (final t in med.times) {
          final doseId = '${med.name}|$t';
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final takenThisDose = (taken[dateStr]?.contains(doseId) ?? false);
          if (!takenThisDose) {
            allTaken = false;
            break;
          }
        }
        if (!allTaken) break;
      }
      if (!activeMedFound) {
        break;
      }
      if (!allTaken) {
        break;
      }
      streak++;
    }
    current = streak;
    // Best streak
    best = 0;
    streak = 0;
    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      bool allTaken = true;
      bool activeMedFound = false;
      for (final med in meds) {
        final isActive =
            (med.startDate == null || !date.isBefore(med.startDate!)) &&
            (med.endDate == null || !date.isAfter(med.endDate!));
        if (!isActive) continue;
        activeMedFound = true;
        for (final t in med.times) {
          final doseId = '${med.name}|$t';
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final takenThisDose = (taken[dateStr]?.contains(doseId) ?? false);
          if (!takenThisDose) {
            allTaken = false;
            break;
          }
        }
        if (!allTaken) break;
      }
      if (!activeMedFound || !allTaken) {
        streak = 0;
      } else {
        streak++;
        if (streak > best) best = streak;
      }
    }
    return {'current': current, 'best': best};
  }

  // Update streaks when marking/unmarking doses
  void markDoseTaken(String medName, String time, DateTime date) {
    final dateStr = dateString(date);
    final doseId = '$medName|$time';
    takenDoses.putIfAbsent(dateStr, () => <String>{});
    takenDoses[dateStr]!.add(doseId);
    saveTakenDosesToPrefs();
    recalculateComplianceStreaks();
    notifyListeners();
  }

  void unmarkDoseTaken(String medName, String time, DateTime date) {
    final dateStr = dateString(date);
    final doseId = '$medName|$time';
    if (takenDoses[dateStr]?.remove(doseId) ?? false) {
      saveTakenDosesToPrefs();
      recalculateComplianceStreaks();
      notifyListeners();
    }
  }

  // Daily log reminder settings
  bool dailyLogReminderEnabled = false;
  TimeOfDay dailyLogReminderTime = const TimeOfDay(
    hour: 20,
    minute: 0,
  ); // Default 8:00 PM

  Future<void> loadDailyLogReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    dailyLogReminderEnabled =
        prefs.getBool('daily_log_reminder_enabled') ?? false;
    final hour = prefs.getInt('daily_log_reminder_hour');
    final minute = prefs.getInt('daily_log_reminder_minute');
    if (hour != null && minute != null) {
      dailyLogReminderTime = TimeOfDay(hour: hour, minute: minute);
    }
    notifyListeners();
  }

  Future<void> saveDailyLogReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_log_reminder_enabled', dailyLogReminderEnabled);
    await prefs.setInt('daily_log_reminder_hour', dailyLogReminderTime.hour);
    await prefs.setInt(
      'daily_log_reminder_minute',
      dailyLogReminderTime.minute,
    );
  }

  void setDailyLogReminderEnabled(bool value) {
    dailyLogReminderEnabled = value;
    saveDailyLogReminderSettings();
    notifyListeners();
  }

  void setDailyLogReminderTime(TimeOfDay time) {
    dailyLogReminderTime = time;
    saveDailyLogReminderSettings();
    notifyListeners();
  }

  // Call this after loading data
  Future<void> loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name');
      final age = prefs.getString('user_age');
      final condition = prefs.getString('user_condition');
      final reminders = prefs.getString('user_reminders');
      if (name != null &&
          age != null &&
          condition != null &&
          reminders != null) {
        setUser(
          name: name,
          age: age,
          condition: condition,
          reminders: reminders,
        );
      }
      await loadHealthLogsFromPrefs();
      await loadAppointmentsFromPrefs();
      await loadMedicationsFromPrefs();
      await loadRemindersEnabledFromPrefs();
      await loadTakenDosesFromPrefs();
      await loadDarkModeFromPrefs();
      await recalculateComplianceStreaks();
      await loadDailyLogReminderSettings(); // Load daily log reminder settings
    } catch (e) {
      print('Error loading user from prefs: $e');
    }
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    name = null;
    age = null;
    condition = null;
    reminders = null;
    healthLogs = [];
    appointments = [];
    medications = [];
    remindersEnabled = false;
    takenDoses = {};
    notifyListeners();
  }

  Future<void> loadRemindersEnabledFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
    notifyListeners();
  }

  Future<void> saveRemindersEnabledToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', remindersEnabled);
  }

  void setRemindersEnabled(bool value) {
    remindersEnabled = value;
    saveRemindersEnabledToPrefs();
    notifyListeners();
  }
}

class ScheduledDose {
  final Medication med;
  final String time;
  final DateTime date;
  ScheduledDose({required this.med, required this.time, required this.date});
}

extension AppStateNextDose on AppState {
  ScheduledDose? getNextScheduledDose() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Only check today
    final date = today;
    for (final med in medications) {
      final isActive =
          (med.startDate == null || !date.isBefore(med.startDate!)) &&
          (med.endDate == null || !date.isAfter(med.endDate!));
      if (!isActive) continue;
      for (final t in med.times) {
        if (!isDoseTaken(med.name, t, date)) {
          return ScheduledDose(med: med, time: t, date: date);
        }
      }
    }
    return null; // All doses taken for today
  }
}
