import 'package:cloud_firestore/cloud_firestore.dart';

class CarpoolRating {
  final String id;
  final String carpoolId;
  final String driverId;
  final String raterId;
  final double rating;  // 1-5 with .5 steps
  final String? comment;
  final DateTime createdAt;

  CarpoolRating({
    required this.id,
    required this.carpoolId,
    required this.driverId,
    required this.raterId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory CarpoolRating.fromMap(Map<String, dynamic> map, String id) {
    return CarpoolRating(
      id: id,
      carpoolId: map['carpoolId'] ?? '',
      driverId: map['driverId'] ?? '',
      raterId: map['raterId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carpoolId': carpoolId,
      'driverId': driverId,
      'raterId': raterId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}