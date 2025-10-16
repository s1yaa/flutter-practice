import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../app_router.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/mentorship_provider.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final mentorshipProvider = Provider.of<MentorshipProvider>(context);
    final currentUserId = authProvider.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: mentorshipProvider.getChatsForUser(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No chats yet.', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  Text('Start a conversation with a mentor!', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = snapshot.data!.docs[index];
              final members = List<String>.from(chatDoc['members']);
              final recipientId = members.firstWhere((id) => id != currentUserId, orElse: () => '');
              final lastMessage = chatDoc['lastMessage'] ?? '';

              if (recipientId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<UserProfile?>(
                future: authProvider.getUserProfile(recipientId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading chat..."));
                  }
                  final recipient = userSnapshot.data;
                  if (recipient == null) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Text(
                        recipient.name.isNotEmpty ? recipient.name[0].toUpperCase() : '?',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(recipient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.chat, arguments: {
                        'recipientId': recipient.uid,
                        'recipientName': recipient.name,
                        'chatId': chatDoc.id
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}