import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';

class MenteesScreen extends StatelessWidget {
  const MenteesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mentorId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentees'),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: Provider.of<MentorshipProvider>(context).getMatchedMenteesForMentor(mentorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong fetching mentees."));
          }
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No mentees yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      'Accept requests from the Requests tab to see them here.',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _MenteeListCard(student: student, mentorId: mentorId);
            },
          );
        },
      ),
    );
  }
}

class _MenteeListCard extends StatelessWidget {
  final UserProfile student;
  final String mentorId;

  const _MenteeListCard({Key? key, required this.student, required this.mentorId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: customPrimarySwatch.shade100,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 22, color: customPrimarySwatch.shade700, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text(student.major ?? 'No major specified', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Start Chat'),
                  onPressed: () {
                    final provider = Provider.of<MentorshipProvider>(context, listen: false);
                    final chatId = provider.getChatId(mentorId, student.uid);
                    Navigator.pushNamed(context, AppRouter.chat, arguments: {
                      'recipientId': student.uid,
                      'recipientName': student.name,
                      'chatId': chatId,
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}