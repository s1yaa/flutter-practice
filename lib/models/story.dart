import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
  });

  factory Story.fromMap(Map<String, dynamic> map, String id) {
    return Story(
      id: id,
      authorId: map['authorId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'title': title,
      'content': content,
      'tags': tags,
      'createdAt': createdAt,
    };
  }
}