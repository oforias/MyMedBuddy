import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onOnboardingComplete;
  const OnboardingScreen({super.key, required this.onOnboardingComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _age = '';
  String _condition = '';
  String _reminders = '';

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _name);
    await prefs.setString('user_age', _age);
    await prefs.setString('user_condition', _condition);
    await prefs.setString('user_reminders', _reminders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (val) => _name = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your name' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _age = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your age' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Condition'),
                onSaved: (val) => _condition = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your condition' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Medication Reminders',
                ),
                onSaved: (val) => _reminders = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter reminders' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                child: const Text('Continue'),
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    await _saveUserData();
                    // Update Provider's AppState
                    final appState = context.read<AppState>();
                    appState.setUser(
                      name: _name,
                      age: _age,
                      condition: _condition,
                      reminders: _reminders,
                    );
                    widget.onOnboardingComplete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
