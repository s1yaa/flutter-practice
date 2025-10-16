import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';

import '../models/user_profile.dart';
import '../models/mentorship_request.dart';
import '../models/review.dart';
import '../models/chat_message.dart';
import '../models/story.dart';
import '../models/progress_task.dart';
import 'auth_provider.dart';
import 'gamification_provider.dart';

class MentorshipProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserProfile>> searchMentors({UserProfile? studentProfile}) async {
    final query = _firestore.collection('users').where('role', isEqualTo: 'mentor');

    final snapshot = await query.limit(50).get();
    final mentors = snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
        .toList();

    if (studentProfile == null || studentProfile.interests.isEmpty) {
      return mentors;
    }

    mentors.sort((a, b) {
      final scoreA = _calculateMatchScore(a, studentProfile);
      final scoreB = _calculateMatchScore(b, studentProfile);
      return scoreB.compareTo(scoreA);
    });

    return mentors;
  }

  int _calculateMatchScore(UserProfile mentor, UserProfile student) {
    int score = 0;
    final studentInterests = student.interests.toSet();

    for (String skill in mentor.skills) {
      if (studentInterests.contains(skill)) {
        score += 2;
      }
    }
    for (String interest in mentor.interests) {
      if (studentInterests.contains(interest)) {
        score += 1;
      }
    }
    return score;
  }

  Future<void> sendMentorshipRequest(String mentorId, String message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User is not signed in.");
      return;
    }

    final request = MentorshipRequest(
      id: '',
      studentId: user.uid,
      mentorId: mentorId,
      status: 'pending',
      createdAt: DateTime.now(),
      message: message,
    );
    try {
      await _firestore.collection('mentorship_requests').add(request.toMap());
      print("Mentorship request sent successfully!");
    } catch (e) {
      print("Error sending mentorship request: $e");
    }
  }

  Future<void> respondToRequest(BuildContext context, String requestId, bool accept) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);

  try {
    await _firestore.collection('mentorship_requests').doc(requestId).update({
      'status': accept ? 'accepted' : 'rejected',
    });

    print("✅ SUCCESS: Request status updated in Firestore.");

    if (accept && authProvider.userProfile != null) {
      gamificationProvider.onMenteeAccepted(authProvider.userProfile!);
    }
  } catch (e) {
    print("---!!! UPDATE FAILED !!!---");
    print("ERROR DETAILS: $e");
    print("--------------------------");
  }

  notifyListeners();
}

  Stream<List<MentorshipRequest>> getPendingRequests(String userId) {
    return _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MentorshipRequest.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> submitReview(Review review) async {
    await _firestore.collection('reviews').add(review.toMap());
    notifyListeners();
  }

  Stream<List<Review>> getReviews(String targetId) {
    return _firestore
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Review.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> postStory(BuildContext context, Story story) async {
    await _firestore.collection('stories').add(story.toMap());

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);
    if (authProvider.userProfile != null && authProvider.userProfile!.role == 'mentor') {
      gamificationProvider.onStoryPosted(authProvider.userProfile!);
    }

    notifyListeners();
  }

  Stream<List<Story>> getStories({List<String>? tags}) {
    Query query = _firestore.collection('stories').orderBy('createdAt', descending: true);

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    return query.limit(20).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Stream<List<Story>> getStoriesForMentor(String authorId) {
    return _firestore
        .collection('stories')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Story.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<UserProfile>> getMatchedMenteesForMentor(String mentorId) {
    return _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((requestSnapshot) async {
      if (requestSnapshot.docs.isEmpty) {
        return <UserProfile>[];
      }

      final studentIds = requestSnapshot.docs
          .map((doc) => doc.data()['studentId'] as String)
          .toList();

      if (studentIds.isEmpty) {
        return <UserProfile>[];
      }

      final studentDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: studentIds)
          .get();

      return studentDocs.docs
          .map((doc) => UserProfile.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  String getChatId(String user1, String user2) {
    return user1.compareTo(user2) < 0 ? '${user1}_$user2' : '${user2}_$user1';
  }

Future<void> sendMessage(String chatId, String senderId, String recipientId, String text) async {
  final message = ChatMessage(
    id: '',
    senderId: senderId,
    text: text,
    timestamp: DateTime.now(),
  );
  
  try {

    await _firestore.collection('chats').doc(chatId).set({
      'members': [senderId, recipientId],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());

  } catch (e) {
    print("Error sending message: $e");
  }
}

  Stream<QuerySnapshot> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('members', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> assignTask(
      String studentId, String mentorId, String description) async {
    final task = ProgressTask(
      id: '',
      studentId: studentId,
      mentorId: mentorId,
      description: description,
      status: 'pending',
      assignedAt: DateTime.now(),
    );
    await _firestore.collection('progress').add(task.toMap());
    notifyListeners();
  }

  Stream<List<ProgressTask>> getMenteeTasks(String menteeId) {
    return _firestore
        .collection('progress')
        .where('studentId', isEqualTo: menteeId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressTask.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateTaskStatus(BuildContext context, String taskId, String status) async {
    await _firestore.collection('progress').doc(taskId).update({'status': status});

    if (status == 'completed') {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);

      if (authProvider.userProfile != null) {
        gamificationProvider.onTaskCompleted(authProvider.userProfile!);
      }
    }

    notifyListeners();
  }
}