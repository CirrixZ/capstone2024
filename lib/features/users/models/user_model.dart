import 'package:cloud_firestore/cloud_firestore.dart';

class BanRecord {
  final String? id; // Make id optional
  final String adminId;
  final String reason;
  final DateTime startDate;
  final DateTime? endDate; // Make endDate optional
  final bool isActive;

  BanRecord({
    this.id, // Optional now
    required this.adminId,
    required this.reason,
    required this.startDate,
    this.endDate, // Optional now
    this.isActive = true,
  });

  factory BanRecord.fromMap(Map<String, dynamic> map, String? id) {
    return BanRecord(
      id: id ?? map['id'], // Handle potential null id
      adminId: map['adminId'] ?? '',
      reason: map['reason'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'reason': reason,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }
}

class UserModel {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool isBanned;
  final String? profilePicture;
  final List<BanRecord> banHistory;
  final DateTime? currentBanEnd;
  final bool emailVerified;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.isBanned = false,
    this.profilePicture,
    this.banHistory = const [],
    this.currentBanEnd,
    this.emailVerified = false,
  });

  bool get isTemporarilyBanned =>
      isBanned &&
      currentBanEnd != null &&
      currentBanEnd!.isAfter(DateTime.now());

  bool get isPermanentlyBanned => isBanned && currentBanEnd == null;

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    List<BanRecord> banHistory = [];
    if (map['banHistory'] != null) {
      banHistory = (map['banHistory'] as List)
          .map((ban) =>
              BanRecord.fromMap(ban as Map<String, dynamic>, ban['id']))
          .toList();
    }

    return UserModel(
      id: id,
      username: map['username'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      isBanned: map['isBanned'] ?? false,
      profilePicture: map['profilePicture'],
      banHistory: banHistory,
      currentBanEnd: map['currentBanEnd'] != null
          ? (map['currentBanEnd'] as Timestamp).toDate()
          : null,
      emailVerified: map['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'isAdmin': isAdmin,
      'isSuperAdmin': isSuperAdmin,
      'isBanned': isBanned,
      'profilePicture': profilePicture,
      'banHistory': banHistory.map((ban) => ban.toMap()).toList(),
      'currentBanEnd':
          currentBanEnd != null ? Timestamp.fromDate(currentBanEnd!) : null,
      'emailVerified': emailVerified,
    };
  }
}
