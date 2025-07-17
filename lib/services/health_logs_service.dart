import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class HealthLogsScreen extends StatelessWidget {
  const HealthLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: () async {
              final logs = appState.healthLogs;
              if (logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No health logs to export.')),
                );
                return;
              }
              final pdf = pw.Document();
              pdf.addPage(
                pw.Page(
                  build: (pw.Context context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Health Logs',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      ...logs.asMap().entries.map(
                        (entry) => pw.Bullet(
                          text:
                              '${entry.value.text}  (${entry.value.timestamp.toLocal().toString().substring(0, 16)})',
                        ),
                      ),
                    ],
                  ),
                ),
              );
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/health_logs.pdf');
              await file.writeAsBytes(await pdf.save());
              await Share.shareXFiles([
                XFile(file.path),
              ], text: 'My Health Logs');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Add a health log',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) {
                      appState.addHealthLog(text);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: appState.healthLogs.isEmpty
                  ? const Center(child: Text('No health logs yet.'))
                  : ListView.builder(
                      itemCount: appState.healthLogs.length,
                      itemBuilder: (context, index) {
                        final log = appState.healthLogs[index];
                        return ListTile(
                          title: Text(log.text),
                          subtitle: Text(
                            log.timestamp.toLocal().toString().substring(0, 16),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => appState.removeHealthLog(index),
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
