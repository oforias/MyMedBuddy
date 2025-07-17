import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:intl/intl.dart';

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key});
  @override
  State<MedicationScheduleScreen> createState() =>
      _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();
  List<TimeOfDay> _times = [];
  DateTime? _startDate;
  DateTime? _endDate;

  void _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _times.add(picked));
  }

  void _pickStartDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  void _pickEndDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _addMedication(AppState appState) {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();
    if (name.isEmpty || dose.isEmpty || _times.isEmpty) return;
    // Store times as 'HH:mm' 24-hour format
    final timesStr = _times
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        )
        .toList();
    appState.addMedication(
      Medication(
        name: name,
        dose: dose,
        times: timesStr,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
    _nameController.clear();
    _doseController.clear();
    _notesController.clear();
    setState(() {
      _times = [];
      _startDate = null;
      _endDate = null;
    });
  }

  void _editMedicationDialog(AppState appState, int index) {
    final med = appState.medications[index];
    final nameController = TextEditingController(text: med.name);
    final doseController = TextEditingController(text: med.dose);
    final notesController = TextEditingController(text: med.notes ?? '');
    List<TimeOfDay> times = med.times.map((t) {
      final parts = t.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
    DateTime? startDate = med.startDate;
    DateTime? endDate = med.endDate;

    void pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked != null) {
        times.add(picked);
        (context as Element).markNeedsBuild();
      }
    }

    void pickStartDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: startDate ?? now,
        firstDate: now,
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        startDate = picked;
        (context as Element).markNeedsBuild();
      }
    }

    void pickEndDate() async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: endDate ?? now,
        firstDate: now,
        lastDate: DateTime(now.year + 5),
      );
      if (picked != null) {
        endDate = picked;
        (context as Element).markNeedsBuild();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        final dateFormat = DateFormat('yyyy-MM-dd');
        return AlertDialog(
          title: const Text('Edit Medication'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                  ),
                ),
                TextField(
                  controller: doseController,
                  decoration: const InputDecoration(labelText: 'Dose'),
                ),
                Wrap(
                  spacing: 8,
                  children: times
                      .asMap()
                      .entries
                      .map(
                        (entry) => Chip(
                          label: Text(entry.value.format(context)),
                          onDeleted: () {
                            times.removeAt(entry.key);
                            (context as Element).markNeedsBuild();
                          },
                        ),
                      )
                      .toList(),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: pickTime,
                      child: const Text('Add Time'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: pickStartDate,
                        child: Text(
                          startDate == null
                              ? 'Start Date'
                              : dateFormat.format(startDate!),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: pickEndDate,
                        child: Text(
                          endDate == null
                              ? 'End Date'
                              : dateFormat.format(endDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
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
                final name = nameController.text.trim();
                final dose = doseController.text.trim();
                if (name.isEmpty || dose.isEmpty || times.isEmpty) return;
                final timesStr = times
                    .map(
                      (t) =>
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                    )
                    .toList();
                appState.medications[index] = Medication(
                  name: name,
                  dose: dose,
                  times: timesStr,
                  startDate: startDate,
                  endDate: endDate,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                appState.saveMedicationsToPrefs();
                // appState.notifyListeners(); // Comment out or remove invalid notifyListeners usage at line 239
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
      appBar: AppBar(title: const Text('Medication Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _doseController,
                    decoration: const InputDecoration(labelText: 'Dose'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addMedication(appState),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: _times
                        .asMap()
                        .entries
                        .map(
                          (entry) => Chip(
                            label: Text(entry.value.format(context)),
                            onDeleted: () =>
                                setState(() => _times.removeAt(entry.key)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickStartDate(context),
                    child: Text(
                      _startDate == null
                          ? 'Start Date'
                          : dateFormat.format(_startDate!),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () => _pickEndDate(context),
                    child: Text(
                      _endDate == null
                          ? 'End Date'
                          : dateFormat.format(_endDate!),
                    ),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appState.medications.isEmpty
                  ? const Center(child: Text('No medications yet.'))
                  : ListView.builder(
                      itemCount: appState.medications.length,
                      itemBuilder: (context, index) {
                        final med = appState.medications[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.medication,
                            color: Colors.blue,
                          ),
                          title: Text('${med.name} (${med.dose})'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Times: ${med.times.join(', ')}'),
                              if (med.startDate != null)
                                Text(
                                  'Start: ${dateFormat.format(med.startDate!)}',
                                ),
                              if (med.endDate != null)
                                Text('End: ${dateFormat.format(med.endDate!)}'),
                              if (med.notes != null && med.notes!.isNotEmpty)
                                Text('Notes: ${med.notes}'),
                              const SizedBox(height: 8),
                              // Mark as taken checkboxes for today
                              ...med.times.map((t) {
                                final now = DateTime.now();
                                final today = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                );
                                final taken = appState.isDoseTaken(
                                  med.name,
                                  t,
                                  today,
                                );
                                return Row(
                                  children: [
                                    Checkbox(
                                      value: taken,
                                      onChanged: (val) {
                                        if (val == true) {
                                          appState.markDoseTaken(
                                            med.name,
                                            t,
                                            today,
                                          );
                                        } else {
                                          appState.unmarkDoseTaken(
                                            med.name,
                                            t,
                                            today,
                                          );
                                        }
                                      },
                                    ),
                                    Text('Today at $t'),
                                  ],
                                );
                              }),
                            ],
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
                                    _editMedicationDialog(appState, index),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    appState.removeMedication(index),
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
