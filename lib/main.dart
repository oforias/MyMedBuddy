import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_state.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart' as prov;
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: prov.ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = prov.Provider.of<AppState>(context);
    return MaterialApp(
      title: 'MyMedBuddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: appState.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
      home: const LaunchDecider(),
      routes: {'/profile': (context) => const ProfileScreen()},
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

  @override
  void initState() {
    super.initState();
    _checkOnboarded();
  }

  Future<void> _checkOnboarded() async {
    final appState = prov.Provider.of<AppState>(context, listen: false);
    await appState.loadUserFromPrefs();
    // If user data is loaded, consider onboarding complete
    final onboarded = appState.name != null && appState.name!.isNotEmpty;
    setState(() => _onboarded = onboarded);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) {
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
