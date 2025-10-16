import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/achievement.dart';

class GamificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> onTaskCompleted(UserProfile studentProfile) async {
    final newCount = studentProfile.tasksCompleted + 1;

    await _firestore.collection('users').doc(studentProfile.uid).update({
      'tasksCompleted': newCount,
      'goalsPercentage': Random().nextInt(41) + 60,
    });

    if (newCount == 1) {
      _awardBadge(
        userId: studentProfile.uid,
        badgeName: 'Goal Getter',
        badgeIcon: '0xe859',
        description: 'You completed your first task!',
      );
    } else if (newCount == 5) {
      _awardBadge(
        userId: studentProfile.uid,
        badgeName: 'Active Learner',
        badgeIcon: '0xf05d',
        description: 'You\'ve completed 5 tasks!',
      );
    }
  }

  Future<void> onMenteeAccepted(UserProfile mentorProfile) async {
    final acceptedMentees = await _firestore
        .collection('mentorship_requests')
        .where('mentorId', isEqualTo: mentorProfile.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (acceptedMentees.docs.length == 1) {
      _awardBadge(
        userId: mentorProfile.uid,
        badgeName: 'Helpful Guide',
        badgeIcon: '0xf03d',
        description: 'You accepted your first mentee!',
      );
    }
    await _firestore.collection('users').doc(mentorProfile.uid).update({
      'mentorScore': Random().nextInt(21) + 20,
    });
  }

  Future<void> onStoryPosted(UserProfile mentorProfile) async {
    final stories = await _firestore
        .collection('stories')
        .where('authorId', isEqualTo: mentorProfile.uid)
        .get();

    if (stories.docs.length == 1) {
      _awardBadge(
        userId: mentorProfile.uid,
        badgeName: 'Thought Leader',
        badgeIcon: '0xe3f3',
        description: 'You shared your first story!',
      );
    }
    await _firestore.collection('users').doc(mentorProfile.uid).update({
      'mentorScore': Random().nextInt(21) + 40,
    });
  }

  Future<void> _awardBadge({
    required String userId,
    required String badgeName,
    required String badgeIcon,
    required String description,
  }) async {
    final existingBadge = await _firestore
        .collection('achievements')
        .where('userId', isEqualTo: userId)
        .where('badgeName', isEqualTo: badgeName)
        .limit(1)
        .get();

    if (existingBadge.docs.isEmpty) {
      await _firestore.collection('achievements').add({
        'userId': userId,
        'badgeName': badgeName,
        'badgeIcon': badgeIcon,
        'description': description,
        'earnedAt': FieldValue.serverTimestamp(),
      });
      print("Awarded badge: $badgeName to user $userId");
    }
  }

  Stream<List<Achievement>> getAchievementsForUser(String userId) {
    return _firestore
        .collection('achievements')
        .where('userId', isEqualTo: userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Achievement.fromMap(doc.data(), doc.id))
            .toList());
  }
}