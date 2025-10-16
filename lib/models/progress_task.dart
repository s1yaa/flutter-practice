import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressTask {
  final String id;
  final String studentId;
  final String mentorId;
  final String description;
  final String status;
  final DateTime assignedAt;

  ProgressTask({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.description,
    required this.status,
    required this.assignedAt,
  });

  factory ProgressTask.fromMap(Map<String, dynamic> map, String id) {
    return ProgressTask(
      id: id,
      studentId: map['studentId'] ?? '',
      mentorId: map['mentorId'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      assignedAt: (map['assignedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mentorId': mentorId,
      'description': description,
      'status': status,
      'assignedAt': assignedAt,
    };
  }
}