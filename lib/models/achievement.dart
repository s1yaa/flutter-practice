import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String userId;
  final String badgeName;
  final String badgeIcon;
  final String description;
  final DateTime earnedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.badgeName,
    required this.badgeIcon,
    required this.description,
    required this.earnedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map, String id) {
    return Achievement(
      id: id,
      userId: map['userId'] ?? '',
      badgeName: map['badgeName'] ?? '',
      badgeIcon: map['badgeIcon'] ?? '0xe3f3',
      description: map['description'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp).toDate(),
    );
  }
}