import 'package:cloud_firestore/cloud_firestore.dart';

class TicketVerification {
  final String id;
  final String userId;
  final String concertId;
  final String imageUrl;
  final bool isApproved;
  final String? status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final String userName; // Add this to show who submitted

  TicketVerification({
    required this.id,
    required this.userId,
    required this.concertId,
    required this.imageUrl,
    this.isApproved = false,
    this.status = 'pending',
    required this.submittedAt,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    required this.userName,
  });

  factory TicketVerification.fromMap(Map<String, dynamic> map, String id) {
    return TicketVerification(
      id: id,
      userId: map['userId'] ?? '',
      concertId: map['concertId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isApproved: map['isApproved'] ?? false,
      status: map['status'] ?? 'pending',
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      verifiedAt: map['verifiedAt'] != null 
          ? (map['verifiedAt'] as Timestamp).toDate() 
          : null,
      verifiedBy: map['verifiedBy'],
      rejectionReason: map['rejectionReason'],
      userName: map['userName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'concertId': concertId,
      'imageUrl': imageUrl,
      'isApproved': isApproved,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
      'rejectionReason': rejectionReason,
      'userName': userName,
    };
  }
}