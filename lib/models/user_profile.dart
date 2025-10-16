import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? university;
  final String? major;
  final int? graduationyear;
  final String? currentcompany;
  final List<String> interests;
  final List<String> skills;
  final String? location;
  final bool isVerified;
  final DateTime createdAt;
  final int tasksCompleted;
  final int goalsPercentage;
  final int mentorScore;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.createdAt,
    this.university,
    this.major,
    this.graduationyear,
    this.currentcompany,
    this.interests = const [],
    this.skills = const [],
    this.location,
    this.isVerified = false,
    this.tasksCompleted = 0,
    this.goalsPercentage = 0,
    this.mentorScore = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    DateTime safeCreatedAt;
    try {
      safeCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } catch (_) {
      safeCreatedAt = DateTime.now();
    }

    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      university: map['university'],
      major: map['major'],
      graduationyear: map['graduationYear'] is int ? map['graduationYear'] : null,
      currentcompany: map['currentCompany'] is String ? map['currentCompany'] : null,
      interests: List<String>.from(map['interests'] ?? []),
      skills: List<String>.from(map['skills'] ?? []),
      location: map['location'] is String ? map['location'] : null,
      isVerified: map['isVerified'] ?? false,
      createdAt: safeCreatedAt,
      tasksCompleted: map['tasksCompleted'] ?? 0,
      goalsPercentage: map['goalsPercentage'] ?? 0,
      mentorScore: map['mentorScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'university': university,
      'major': major,
      'graduationYear': graduationyear,
      'currentCompany': currentcompany,
      'interests': interests,
      'skills': skills,
      'location': location,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'tasksCompleted': tasksCompleted,
      'goalsPercentage': goalsPercentage,
      'mentorScore': mentorScore,
    };
  }
@override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}