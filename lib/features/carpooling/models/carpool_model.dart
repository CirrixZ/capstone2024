import 'package:cloud_firestore/cloud_firestore.dart';

enum CarpoolStatus { active, completed, rated, expired }

class Carpool {
  final String id;
  final String carpoolTitle;
  final String slot;
  final String fee;
  final String imageUrl;
  final String chatRoomId;
  final String driverId;
  final List<String> passengers;
  final int availableSlots;
  final CarpoolStatus status;
  final DateTime? completedAt;
  final List<String> confirmedCompletion;
  final List<String> ratedBy;
  final String meetupLocation;
  final DateTime? meetupTime;
  final Map<String, String> rsvpStatus;

  Carpool({
    required this.id,
    required this.carpoolTitle,
    required this.slot,
    required this.fee,
    required this.imageUrl,
    required this.chatRoomId,
    required this.driverId,
    this.passengers = const [],
    required this.availableSlots,
    this.status = CarpoolStatus.active,
    this.completedAt,
    this.confirmedCompletion = const [],
    this.ratedBy = const [],
    this.meetupLocation = 'Not set yet',
    this.meetupTime,
    this.rsvpStatus = const {},
  });

  factory Carpool.fromMap(Map<String, dynamic> map, String id) {
    return Carpool(
      id: id,
      carpoolTitle: map['carpoolTitle'] ?? '',
      slot: map['slot'] ?? '',
      fee: map['fee'] ?? '',
      imageUrl: map['imagePath'] ??
          '', // Still reading from 'imagePath' for backward compatibility
      chatRoomId: map['chatRoomId'] ?? '',
      driverId: map['driverId'] ?? '',
      passengers: List<String>.from(map['passengers'] ?? []),
      availableSlots: map['availableSlots'] ?? 0,
      status: CarpoolStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => CarpoolStatus.active,
      ),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      confirmedCompletion: List<String>.from(map['confirmedCompletion'] ?? []),
      ratedBy: List<String>.from(map['ratedBy'] ?? []),
      meetupLocation: map['meetupLocation'] ?? 'Not set yet',
      meetupTime: map['meetupTime'] != null
          ? (map['meetupTime'] as Timestamp).toDate()
          : null,
      rsvpStatus: Map<String, String>.from(map['rsvpStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carpoolTitle': carpoolTitle,
      'slot': slot,
      'fee': fee,
      'imagePath':
          imageUrl, // Still writing to 'imagePath' for backward compatibility
      'chatRoomId': chatRoomId,
      'driverId': driverId,
      'passengers': passengers,
      'availableSlots': availableSlots,
      'status': status.toString(),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'confirmedCompletion': confirmedCompletion,
      'ratedBy': ratedBy,
      'meetupLocation': meetupLocation,
      'meetupTime': meetupTime != null ? Timestamp.fromDate(meetupTime!) : null,
      'rsvpStatus': rsvpStatus,
    };
  }
}
