import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String authorId;
  final String targetId;
  final String targetType;
  final double rating;
  final String title;
  final String content;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.authorId,
    required this.targetId,
    required this.targetType,
    required this.rating,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      authorId: map['authorId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: map['targetType'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'targetId': targetId,
      'targetType': targetType,
      'rating': rating,
      'title': title,
      'content': content,
      'createdAt': createdAt,
    };
  }
}