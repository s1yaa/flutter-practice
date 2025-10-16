import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../models/mentorship_request.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import 'search_screen.dart'; 

class MyMentorsScreen extends StatelessWidget {
  const MyMentorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentors'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mentorship_requests')
            .where('studentId', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No active mentors yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Use the Explore tab to find and connect!', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = MentorshipRequest.fromMap(
                snapshot.data!.docs[index].data() as Map<String, dynamic>,
                snapshot.data!.docs[index].id,
              );
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(request.mentorId).get(),
                builder: (context, mentorSnapshot) {
                  if (!mentorSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  final mentor = UserProfile.fromMap(
                    mentorSnapshot.data!.data() as Map<String, dynamic>,
                    request.mentorId,
                  );
                  return MentorCard(mentor: mentor);
                },
              );
            },
          );
        },
      ),
    );
  }
}