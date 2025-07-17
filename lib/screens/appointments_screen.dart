import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  void _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _addAppointment(AppState appState) {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null || _selectedTime == null) return;
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    appState.addAppointment(Appointment(title: title, dateTime: dt));
    _titleController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _editAppointmentDialog(AppState appState, int index) {
    final appt = appState.appointments[index];
    final titleController = TextEditingController(text: appt.title);
    DateTime selectedDate = appt.dateTime;
    TimeOfDay selectedTime = TimeOfDay(
      hour: appt.dateTime.hour,
      minute: appt.dateTime.minute,
    );

    void pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 5),
      );
      if (picked != null) {
        selectedDate = picked;
        (context as Element).markNeedsBuild();
      }
    }

    void pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null) {
        selectedTime = picked;
        (context as Element).markNeedsBuild();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        return AlertDialog(
          title: const Text('Edit Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: pickDate,
                      child: Text(dateFormat.format(selectedDate)),
                    ),
                    TextButton(
                      onPressed: pickTime,
                      child: Text(selectedTime.format(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                final dt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                appState.appointments[index] = Appointment(
                  title: title,
                  dateTime: dt,
                );
                appState.saveAppointmentsToPrefs();
                // appState.notifyListeners(); // This line was commented out in the original file
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final dateFormat = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addAppointment(appState),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'No date'
                        : dateFormat.format(_selectedDate!),
                  ),
                ),
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? 'No time'
                        : _selectedTime!.format(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appState.appointments.isEmpty
                  ? const Center(child: Text('No appointments yet.'))
                  : ListView.builder(
                      itemCount: appState.appointments.length,
                      itemBuilder: (context, index) {
                        final appt = appState.appointments[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.event,
                            color: Colors.blueAccent,
                          ),
                          title: Text(appt.title),
                          subtitle: Text(
                            '${dateFormat.format(appt.dateTime)} at ${DateFormat('HH:mm').format(appt.dateTime)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                onPressed: () =>
                                    _editAppointmentDialog(appState, index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    appState.removeAppointment(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
