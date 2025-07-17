import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'medication_schedule_screen.dart';
import '../services/health_logs_service.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart' as prov;
import '../providers/app_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rpd;
import '../providers/health_tip_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMedBuddy',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LaunchDecider(),
      routes: {'/profile': (context) => const ProfileScreen()},
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return prov.Consumer<AppState>(
      builder: (context, appState, _) {
        // Dynamic: Use real data for medications and appointments
        final weeklyAppointments = appState.appointments;
        return Scaffold(
          appBar: AppBar(title: const Text('MyMedBuddy Home')),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MyMedBuddy',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      if (appState.name != null && appState.name!.isNotEmpty)
                        Text(
                          'Hello, ${appState.name}!',
                          style: const TextStyle(color: Colors.white),
                        ),
                      if (appState.condition != null &&
                          appState.condition!.isNotEmpty)
                        Text(
                          'Condition: ${appState.condition}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text('Medication Schedule'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicationScheduleScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.health_and_safety),
                  title: const Text('Health Logs'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HealthLogsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Appointments'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      // Health Tips Card (Riverpod)
                      rpd.Consumer(
                        builder: (context, ref, _) {
                          final tipAsync = ref.watch(healthTipProvider);
                          return Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: tipAsync.when(
                                data: (tip) {
                                  // Parse the tip string into fields
                                  final lines = tip.split('\n');
                                  String drug = '',
                                      purpose = '',
                                      usage = '',
                                      warning = '';
                                  for (final line in lines) {
                                    if (line.startsWith('Drug:')) {
                                      drug = line
                                          .replaceFirst('Drug:', '')
                                          .trim();
                                    }
                                    if (line.startsWith('Purpose:')) {
                                      purpose = line
                                          .replaceFirst('Purpose:', '')
                                          .trim();
                                    }
                                    if (line.startsWith('Usage:')) {
                                      usage = line
                                          .replaceFirst('Usage:', '')
                                          .trim();
                                    }
                                    if (line.startsWith('Warning:')) {
                                      warning = line
                                          .replaceFirst('Warning:', '')
                                          .trim();
                                    }
                                  }
                                  // Compose a summary with only the first sentence of each field
                                  String firstSentence(String text) {
                                    final idx = text.indexOf('.') + 1;
                                    if (idx > 0) {
                                      return text.substring(0, idx).trim();
                                    }
                                    return text.trim();
                                  }

                                  String summary = '';
                                  if (purpose.isNotEmpty) {
                                    summary +=
                                        'Purpose:     ${firstSentence(purpose)}\n';
                                  }
                                  if (usage.isNotEmpty) {
                                    summary +=
                                        'Usage:     ${firstSentence(usage)}\n';
                                  }
                                  if (warning.isNotEmpty) {
                                    summary +=
                                        'Warning:     ${firstSentence(warning)}';
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.medication,
                                            color: Colors.blue,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              drug.isNotEmpty
                                                  ? drug[0].toUpperCase() +
                                                        drug.substring(1)
                                                  : '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        summary.trim(),
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                      const SizedBox(height: 12),
                                      // More Info button removed
                                    ],
                                  );
                                },
                                loading: () => const Row(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(width: 12),
                                    Text('Loading drug fact...'),
                                  ],
                                ),
                                error: (e, _) => Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Failed to load drug fact.'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // User Info Card
                      if (appState.name != null && appState.name!.isNotEmpty)
                        Card(
                          elevation: 4,
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.blue,
                            ),
                            title: Text('Welcome, ${appState.name}!'),
                            subtitle: Text(
                              'Age: ${appState.age ?? '-'} | Condition: ${appState.condition ?? '-'}',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Next Medication Card
                      Card(
                        elevation: 4,
                        child: Builder(
                          builder: (context) {
                            final nextDose = appState.getNextScheduledDose();
                            if (nextDose == null) {
                              return const ListTile(
                                leading: Icon(
                                  Icons.medication,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                title: Text('All doses completed!'),
                              );
                            }
                            return ListTile(
                              leading: const Icon(
                                Icons.medication,
                                size: 40,
                                color: Colors.blue,
                              ),
                              title: Text(
                                'Next Medication: ${nextDose.med.name}',
                              ),
                              subtitle: Text(
                                '${nextDose.med.dose} at ${nextDose.time} on '
                                '${nextDose.date.year}-${nextDose.date.month.toString().padLeft(2, '0')}-${nextDose.date.day.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Missed Doses Card
                      Builder(
                        builder: (context) {
                          final today = DateTime.now();
                          final missed = appState.getMissedDosesForDay(today);
                          if (missed.isEmpty) {
                            return Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 12),
                                    Text('No missed doses today!'),
                                  ],
                                ),
                              ),
                            );
                          }
                          return Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.warning, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'Missed Doses (Today)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...missed.map(
                                    (dose) => Padding(
                                      padding: const EdgeInsets.only(
                                        left: 12.0,
                                        bottom: 2.0,
                                      ),
                                      child: Text(
                                        '${dose['medName']} (${dose['dose']}) at ${dose['time']}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Medication Compliance Streaks Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Medication Compliance Streaks',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    appState.streaksCalculating
                                        ? const Text(
                                            'Calculating streaks...',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : Text(
                                            'Current streak:  ${appState.currentComplianceStreak} days',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                    appState.streaksCalculating
                                        ? const SizedBox.shrink()
                                        : Text(
                                            'Best streak:  ${appState.bestComplianceStreak} days',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Weekly Appointments Card with GridView
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appointments',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              weeklyAppointments.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('No appointments scheduled.'),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: weeklyAppointments.length,
                                      itemBuilder: (context, index) {
                                        final appt = weeklyAppointments[index];
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.event,
                                            color: Colors.blueAccent,
                                          ),
                                          title: Text(appt.title),
                                          subtitle: Text(
                                            '${appt.dateTime.year}-${appt.dateTime.month.toString().padLeft(2, '0')}-${appt.dateTime.day.toString().padLeft(2, '0')} at '
                                            '${appt.dateTime.hour.toString().padLeft(2, '0')}:${appt.dateTime.minute.toString().padLeft(2, '0')}',
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class LaunchDecider extends StatefulWidget {
  const LaunchDecider({super.key});
  @override
  State<LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  bool? _onboarded;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkOnboarded();
  }

  Future<void> _checkOnboarded() async {
    final appState = prov.Provider.of<AppState>(context, listen: false);
    await appState.loadUserFromPrefs();
    final onboarded = appState.name != null && appState.name!.isNotEmpty;
    setState(() {
      _onboarded = onboarded;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _onboarded!
        ? const HomeScreen()
        : OnboardingScreen(
            onOnboardingComplete: () {
              setState(() => _onboarded = true);
            },
          );
  }
}
