import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../models/progress_task.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isMentor = authProvider.userProfile?.role == 'mentor';
    final userId = authProvider.user?.uid ?? '';
    final provider = Provider.of<MentorshipProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isMentor ? 'Student Progress' : 'My Progress'),
        actions: isMentor ? [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            onPressed: () => _showAssignTaskDialog(context, provider, userId),
          )
        ] : null,
      ),
      body: StreamBuilder<List<ProgressTask>>(
        stream: isMentor
            ? FirebaseFirestore.instance.collection('progress').where('mentorId', isEqualTo: userId).snapshots().map((s) => s.docs.map((d) => ProgressTask.fromMap(d.data(), d.id)).toList())
            : provider.getMenteeTasks(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    isMentor ? 'You haven\'t assigned any tasks.' : 'Your progress tracker is empty.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isCompleted = task.status == 'completed';

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? Colors.green.shade100 : customPrimarySwatch.shade100,
                    child: Icon(
                      isCompleted ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                      color: isCompleted ? Colors.green.shade700 : customPrimarySwatch.shade700,
                    ),
                  ),
                  title: Text(task.description, style: TextStyle(fontWeight: FontWeight.w600, decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none)),
                  subtitle: Text('Status: ${task.status.toUpperCase()}'),
                  onTap: !isMentor ? () {
                    if (!isCompleted) {
                      provider.updateTaskStatus(context, task.id, 'completed');
                    }
                  } : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAssignTaskDialog(BuildContext context, MentorshipProvider provider, String mentorId) {
    final descriptionController = TextEditingController();
    UserProfile? selectedMentee;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign New Task', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<UserProfile>>(
                    future: provider.getMatchedMenteesForMentor(mentorId).first,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      final mentees = snapshot.data ?? [];
                      if (mentees.isEmpty) return const Text("You have no mentees to assign tasks to.");

                      return DropdownButtonFormField<UserProfile>(
                        value: selectedMentee,
                        hint: const Text("Select a Mentee"),
                        items: mentees.map((mentee) => DropdownMenuItem(
                          value: mentee,
                          child: Text(mentee.name),
                        )).toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedMentee = value);
                        },
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Task Description'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (descriptionController.text.isNotEmpty && selectedMentee != null) {
                      await provider.assignTask(
                        selectedMentee!.uid,
                        mentorId,
                        descriptionController.text.trim(),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task Assigned!')),
                      );
                    }
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}