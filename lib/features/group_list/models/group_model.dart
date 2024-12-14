class Group {
  final String id;
  final String imageUrl;
  final String groupName;
  final int membersCount;
  final String chatRoomId;  // New field

  Group({
    required this.id,
    required this.imageUrl,
    required this.groupName,
    required this.membersCount,
    required this.chatRoomId,  // New field
  });

  factory Group.fromMap(Map<String, dynamic> map, String id) {
    return Group(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      groupName: map['groupName'] ?? '',
      membersCount: _parseMembersCount(map['membersCount']),
      chatRoomId: map['chatRoomId'] ?? '',  // New field
    );
  }

  static int _parseMembersCount(dynamic value) {
    if (value is int) {
      return value;
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'groupName': groupName,
      'membersCount': membersCount,
      'chatRoomId': chatRoomId,  // New field
    };
  }
}