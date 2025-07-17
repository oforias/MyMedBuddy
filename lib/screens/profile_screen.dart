import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile'),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Medication Reminders'),
              value: appState.remindersEnabled,
              onChanged: (val) async {
                appState.setRemindersEnabled(val);
                // Removed: scheduling/cancelling notifications
              },
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: appState.darkModeEnabled,
              onChanged: (val) {
                appState.setDarkModeEnabled(val);
              },
            ),
            SwitchListTile(
              title: const Text('Daily Health Log Reminder'),
              value: appState.dailyLogReminderEnabled,
              onChanged: (val) {
                appState.setDailyLogReminderEnabled(val);
              },
            ),
            ListTile(
              title: const Text('Reminder Time'),
              subtitle: Text(appState.dailyLogReminderTime.format(context)),
              enabled: appState.dailyLogReminderEnabled,
              onTap: appState.dailyLogReminderEnabled
                  ? () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: appState.dailyLogReminderTime,
                      );
                      if (picked != null) {
                        appState.setDailyLogReminderTime(picked);
                      }
                    }
                  : null,
              leading: const Icon(Icons.access_time),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await appState.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared! Restart the app.'),
                  ),
                );
              },
              child: const Text('Clear All App Data (Debug)'),
            ),
          ],
        ),
      ),
    );
  }
}
