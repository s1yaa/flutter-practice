import 'package:cloud_firestore/cloud_firestore.dart';

class MentorshipRequest {
  final String id;
  final String studentId;
  final String mentorId;
  final String status;
  final String message;
  final DateTime createdAt;

  MentorshipRequest({
    required this.id,
    required this.studentId,
    required this.mentorId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  factory MentorshipRequest.fromMap(Map<String, dynamic> map, String id) {
    return MentorshipRequest(
      id: id,
      studentId: map['studentId'] ?? '',
      mentorId: map['mentorId'] ?? '',
      status: map['status'] ?? 'pending',
      message: map['message'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'mentorId': mentorId,
      'status': status,
      'message': message,
      'createdAt': createdAt,
    };
  }
}