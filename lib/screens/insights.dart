import 'package:flutter/material.dart';
import '../models/task.dart';

class InsightsScreen extends StatelessWidget {
  final List<Task> tasks;

  const InsightsScreen({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    int totalTasks = tasks.length;

    int completedTasks = tasks.where((task) => task.isCompleted).length;

    int pendingTasks = tasks.where((task) => !task.isCompleted).length;

    double completionRate = totalTasks == 0
        ? 0
        : (completedTasks / totalTasks) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text('Total Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Text('$totalTasks'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Completed Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Text('$completedTasks'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Text('$pendingTasks'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Completion Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                trailing: Text('${completionRate.toStringAsFixed(1)}%'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size(0, 52),
                  backgroundColor: Colors.transparent,
                ),
                icon: const Icon(Icons.home, size: 20),
                label: const Text('Home', style: TextStyle(fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFFD8E2FF),
                foregroundColor: const Color(0xFF2A2F5A),
                elevation: 4,
                shadowColor: const Color(0x803F51B5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                minimumSize: const Size(56, 56),
              ),
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  minimumSize: const Size(0, 52),
                  backgroundColor: Colors.transparent,
                ),
                icon: const Icon(Icons.insights, size: 20),
                label: const Text('Insights', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
