import 'dart:io';
import 'package:capstone/features/carpooling/models/carpool_model.dart';
import 'package:capstone/features/chat/models/chat_room_model.dart';
import 'package:capstone/features/chat/models/message_model.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/concerts/screens/concert_details.dart';
import 'package:capstone/features/group_list/models/group_model.dart';
import 'package:capstone/features/messages/models/chat_preview_model.dart';
import 'package:capstone/features/messages/screens/messages_page.dart';
import 'package:capstone/features/notifications/models/notification_model.dart';
import 'package:capstone/features/ticket_market/models/ticket_model.dart';
import 'package:capstone/features/ticket_market/screens/ticket_market.dart';
import 'package:capstone/features/users/models/user_model.dart';
import 'package:capstone/features/verification/models/ticket_verification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _concerts => _firestore.collection('concerts');
  CollectionReference get _chatRooms => _firestore.collection('chatRooms');

  User? get currentUser => _auth.currentUser;

  // Error handler for signing in
  Exception _handleFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Incorrect password');
        case 'email-already-in-use':
          return Exception('An account already exists with this email');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'user-disabled':
          return Exception('This account has been disabled');
        case 'user-banned':
          return Exception(e.message ?? 'Your account has been suspended');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later');
        case 'operation-not-allowed':
          return Exception('Operation not allowed');
        case 'network-request-failed':
          return Exception('Network error. Please check your connection');
        default:
          return Exception(e.message ?? 'An unexpected error occurred');
      }
    }
    return Exception('An unexpected error occurred: ${e.toString()}');
  }

  // ***AUTHENTICATION METHODS***
  // Sign up method
  Future<UserCredential> signUp(String email, String password) async {
    // Create the auth user first
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    // Notes to self, don't try to update the document, as it will be created in the RegisterPage

    return credential;
  }

  // Sign-in method with ban check
  Future<UserCredential> signIn(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(credential.user!.uid).get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;

      if (userData['isAdmin'] == true || userData['isSuperAdmin'] == true) {
        await _auth.signOut();
        return credential;
      }

      final isBanned = userData['isBanned'] ?? false;
      final currentBanEnd = userData['currentBanEnd'] as Timestamp?;

      if (isBanned) {
        if (currentBanEnd != null) {
          if (currentBanEnd.toDate().isAfter(DateTime.now())) {
            throw FirebaseAuthException(
              code: 'user-banned',
              message:
                  'Account suspended until ${DateFormat('MMM d, y h:mm a').format(currentBanEnd.toDate())}',
            );
          } else {
            await unbanUser(credential.user!.uid);
          }
        } else {
          throw FirebaseAuthException(
            code: 'user-banned',
            message: 'Account permanently suspended',
          );
        }
      }

      await _users.doc(credential.user!.uid).update({
        'emailVerified': credential.user!.emailVerified,
      });
    }

    return credential;
  }

  // Admin Sign In: Special login for admin users
  Future<UserCredential> signInAdmin(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(credential.user!.uid).get();

    if (!userDoc.exists) {
      await _auth.signOut();
      return credential;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final isAdmin = userData['isAdmin'] == true;
    final isSuperAdmin = userData['isSuperAdmin'] == true;

    if (!isAdmin && !isSuperAdmin) {
      await _auth.signOut();
    }

    return credential;
  }

  // Signs out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Checks if user is admin
  Future<bool> isUserAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists && userDoc.get('isAdmin') == true;
    }
    return false;
  }

  // Check if user is super admin
  Future<bool> isUserSuperAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists && userDoc.get('isSuperAdmin') == true;
    }
    return false;
  }

  // Stream for super admin status
  Stream<bool> userSuperAdminStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isSuperAdmin'] == true);
  }

  // Stream for admin status
  Stream<bool> userAdminStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['isAdmin'] == true);
  }

  // Deletes user account
  Future<void> deleteUserAccount(String password) async {
    User? user = currentUser;
    if (user == null) throw Exception('No user found');

    try {
      // Re-authenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // If re-authentication successful, delete account
      await _users.doc(user.uid).delete();
      await user.delete();
      await signOut();
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // ***CONCERT METHODS***
  // Gets all concert stream
  Stream<List<Concert>> getConcerts() {
    return _firestore.collection('concerts').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Concert.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Gets details of specific concert
  Stream<Concert> getConcertDetails(String concertId) {
    return _firestore
        .collection('concerts')
        .doc(concertId)
        .snapshots()
        .map((doc) {
      return Concert.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // Creates new concert with all needed details
  Future<void> createConcert({
    required String imageUrl,
    required String artistName,
    required String concertName,
    required List<String> description,
    required List<String> dates,
    required String location,
    required String artistDetails,
  }) async {
    try {
      DocumentReference concertRef =
          await _firestore.collection('concerts').add({
        'imageUrl': imageUrl,
        'artistName': artistName,
        'concertName': concertName,
        'description': description,
        'dates': dates,
        'location': location,
        'artistDetails': artistDetails,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create subcollections
      await concertRef.collection('groups').add({});
      await concertRef.collection('carpools').add({});

      // Delete the empty documents after creating the collections
      await concertRef.collection('groups').get().then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
      await concertRef.collection('carpools').get().then((snapshot) {
        for (DocumentSnapshot doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    } catch (e) {
      throw Exception('Failed to create concert: $e');
    }
  }

  // Updates specific concert details
  Future<void> updateConcertDetails(
    String concertId, {
    // Made concertId a required parameter
    String? imageUrl,
    String? artistName,
    String? concertName,
    List<String>? description,
    String? artistDetails,
    DateTime? mainDate,
    List<String>? dates,
    String? location,
  }) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    try {
      Map<String, dynamic> updates = {};
      if (imageUrl != null) updates['imageUrl'] = imageUrl;
      if (artistName != null) updates['artistName'] = artistName;
      if (concertName != null) updates['concertName'] = concertName;
      if (description != null) updates['description'] = description;
      if (artistDetails != null) updates['artistDetails'] = artistDetails;
      if (mainDate != null) updates['date'] = Timestamp.fromDate(mainDate);
      if (dates != null) updates['dates'] = dates;
      if (location != null) updates['location'] = location;

      if (updates.isEmpty) return;

      await _concerts.doc(concertId).update(updates);

      // Get all subscribed users and send notifications
      final recipients =
          await _getUpdatesSubscribers(type: NotificationType.CONCERT_UPDATE);

      if (recipients.isNotEmpty) {
        await sendBatchNotifications(
          recipients: recipients,
          type: NotificationType.CONCERT_UPDATE,
          message: 'Concert details have been updated',
          concertId: concertId,
        );
      }
    } catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  // Deletes concert
  Future<void> deleteConcert(String concertId) async {
    // Only super admins can delete concerts
    if (!await isUserSuperAdmin()) {
      throw Exception('Unauthorized: Super Admin access required');
    }
    await _firestore.collection('concerts').doc(concertId).delete();
  }

  // Deletes concert and all related data
  Future<void> deleteConcertAndData(String concertId) async {
    if (!await isUserSuperAdmin()) {
      throw Exception('Unauthorized: Super Admin access required');
    }

    // Get all chat rooms associated with this concert's groups and carpools
    final groupsSnapshot = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('groups')
        .get();

    final carpoolsSnapshot = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .get();

    // Delete all chat rooms
    for (var doc in groupsSnapshot.docs) {
      final chatRoomId = doc.data()['chatRoomId'] as String?;
      if (chatRoomId?.isNotEmpty ?? false) {
        await _firestore.collection('chatRooms').doc(chatRoomId).delete();
      }
    }

    for (var doc in carpoolsSnapshot.docs) {
      final chatRoomId = doc.data()['chatRoomId'] as String?;
      if (chatRoomId?.isNotEmpty ?? false) {
        await _firestore.collection('chatRooms').doc(chatRoomId).delete();
      }
    }

    // Delete all subcollections
    await _deleteCollection(
        _firestore.collection('concerts').doc(concertId).collection('groups'));
    await _deleteCollection(_firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools'));
    await _deleteCollection(
        _firestore.collection('concerts').doc(concertId).collection('tickets'));

    // Finally delete the concert document
    await _firestore.collection('concerts').doc(concertId).delete();
  }

// Helper method to delete a collection
  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Gets analytics for a specific concert
  Future<Map<String, dynamic>> getConcertAnalytics(String concertId) async {
    try {
      var concertDoc =
          await _firestore.collection('concerts').doc(concertId).get();

      if (!concertDoc.exists) {
        return {'error': 'Concert not found'};
      }

      var groupsSnapshot = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .get();

      var carpoolsSnapshot = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .get();

      return {
        'totalUsers': concertDoc.data()?['totalUsers'] ?? 0,
        'totalGroups': groupsSnapshot.docs.length,
        'totalCarpools': carpoolsSnapshot.docs.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  //***CHAT METHODS***
  // Gets all messages in a chat room
  Stream<List<Message>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Sends text message to chats
  Future<void> sendMessage(String chatRoomId, String text) async {
    final message = Message(
      id: '',
      senderId: currentUser!.uid,
      text: text,
      timestamp: Timestamp.now(),
    );

    // Get chat room details
    DocumentSnapshot chatRoom =
        await _firestore.collection('chatRooms').doc(chatRoomId).get();

    Map<String, dynamic> chatData = chatRoom.data() as Map<String, dynamic>;
    List<String> participants =
        List<String>.from(chatData['participants'] ?? []);
    String chatType = chatData['type'];
    String chatName = chatData['name'];

    // Send message
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    // Update chat preview
    await updateChatPreviewForNewMessage(chatRoomId, text);

    // Create notifications for other participants
    List<String> recipients = participants..remove(currentUser!.uid);
    if (recipients.isNotEmpty) {
      String senderName = (await getUserProfile())['username'] ?? 'Someone';

      // Customize notification text based on chat type
      String notificationText;
      if (chatType == 'group') {
        notificationText = "$senderName sent a message in $chatName";
      } else if (chatType == 'carpool') {
        notificationText = "$senderName sent a message in $chatName's carpool";
      } else {
        notificationText = "$senderName sent a message in $chatName";
      }

      await createNotification(
        type: chatType == 'group'
            ? NotificationType.GROUP_MESSAGE
            : NotificationType.CARPOOL_MESSAGE,
        message: notificationText,
        chatRoomId: chatRoomId,
        senderId: currentUser!.uid,
        recipients: recipients,
      );
    }
  }

  // Sends image to chats
  Future<void> sendImage(String chatRoomId, String imagePath) async {
    final ref = _storage
        .ref()
        .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(File(imagePath));
    final url = await ref.getDownloadURL();

    final message = Message(
      id: '',
      senderId: currentUser!.uid,
      text: '',
      imageUrl: url,
      timestamp: Timestamp.now(),
    );

    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());

    await updateChatPreviewForNewMessage(chatRoomId, 'Image');
  }

  // Unsends/Deletes a message
  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    final user = currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Get user data for unsent message text
    final userData = await getUserData(user.uid);
    final username = userData['username'] ?? 'User';

    // Update the message instead of deleting it
    DocumentReference messageRef = _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    batch.update(messageRef, {
      'text': '$username unsent a message',
      'imageUrl': null, // Clear image if any
      'isDeleted': true,
    });

    await batch.commit();
  }

  // Gets the list of chat rooms user is in
  Stream<List<ChatRoom>> getChatRooms(String userId) {
    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Creates new chat room
  Future<void> createChatRoom(ChatRoom chatRoom) async {
    await _firestore.collection('chatRooms').add(chatRoom.toMap());
  }

  // Gets chat previews, filtered by type (group/carpool)
  Stream<List<ChatPreview>> getChatPreviews(String userId, String type) {
    return _firestore
        .collection('chatRooms')
        .where('type', isEqualTo: type)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data();
              bool hasUnread = data['hasUnread']?[userId] ?? false;

              // For carpool chats, use carpoolTitle as subtitle
              String subtitle = type == 'carpool'
                  ? data['carpoolTitle'] ?? ''
                  : data['concertName'] ?? '';

              return ChatPreview.fromMap(
                data,
                doc.id,
                hasUnread,
                subtitle, // Add this parameter to ChatPreview model
              );
            }).toList());
  }

  // Updates chat preview when new message sent
  Future<void> updateChatPreviewForNewMessage(
      String chatRoomId, String lastMessage) async {
    DocumentSnapshot chatRoomDoc =
        await _firestore.collection('chatRooms').doc(chatRoomId).get();

    if (!chatRoomDoc.exists) {
      return;
    }

    Map<String, dynamic> data = chatRoomDoc.data() as Map<String, dynamic>;
    List<String> participants = List<String>.from(data['participants'] ?? []);

    Map<String, dynamic> updates = {
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };

    for (String participantId in participants) {
      updates['hasUnread.$participantId'] = participantId != currentUser!.uid;
    }

    await _firestore.collection('chatRooms').doc(chatRoomId).update(updates);
  }

  // Checks if any of the chat rooms has unread messages for the user, if they are a participant though
  Stream<bool> hasUnreadMessages() {
    User? user = currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('chatRooms')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        Map<String, dynamic>? hasUnread =
            data['hasUnread'] as Map<String, dynamic>?;
        if (hasUnread?[user.uid] == true) {
          return true;
        }
      }
      return false;
    });
  }

  // Marks the chat room as read for user provided they enter the chat room
  Future<void> markChatAsRead(String chatRoomId) async {
    if (currentUser == null) return;

    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'hasUnread.${currentUser!.uid}': false,
    });
  }

  // Gets members in a chat room. Used in both group and carpool
  Stream<List<UserModel>> getChatRoomMembers(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).snapshots().asyncMap((doc) async {
      List<String> participants =
          List<String>.from(doc.get('participants') ?? []);
      List<UserModel> members = [];

      for (String userId in participants) {
        DocumentSnapshot userDoc = await _users.doc(userId).get();
        if (userDoc.exists) {
          members.add(UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            userDoc.id,
          ));
        }
      }

      return members;
    });
  }

  // Gets details of group chat room
  Stream<DocumentSnapshot> getGroupDetails(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .handleError((error) {
      return null;
    });
  }

  // Gets details of carpool chat room
  Stream<DocumentSnapshot> getCarpoolDetails(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).snapshots().handleError((error) {
      throw Exception('Failed to load carpool details');
    });
  }

  // Gets username by user ID
  Future<String> getUserName(String userId) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      return userData['username'] ?? '';
    }
    return '';
  }

  // Sends chat notifs
  Future<void> checkAndSendChatNotification({
    required String chatRoomId,
    required String message,
    required List<String> recipients,
    required bool isGroupChat,
  }) async {
    // Get recipient notification settings
    QuerySnapshot recipientDocs = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: recipients)
        .get();

    final batch = _firestore.batch();

    for (var recipientDoc in recipientDocs.docs) {
      Map<String, dynamic> settings =
          recipientDoc.get('notificationSettings') ?? {};

      bool shouldNotify = isGroupChat
          ? settings['groupMessages'] ?? true
          : settings['carpoolMessages'] ?? true;

      if (shouldNotify) {
        DocumentReference notifRef = _firestore
            .collection('users')
            .doc(recipientDoc.id)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'type': isGroupChat
              ? NotificationType.GROUP_MESSAGE.toString().split('.').last
              : NotificationType.CARPOOL_MESSAGE.toString().split('.').last,
          'message': message,
          'chatRoomId': chatRoomId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }

    await batch.commit();
  }

  // ***CARPOOL METHODS***
  // Gets list of carpools of a concert
  Stream<List<Carpool>> getCarpools(String concertId) {
    final userId = currentUser?.uid;

    return _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Carpool.fromMap(doc.data(), doc.id))
          .where((carpool) =>
                  carpool.availableSlots > 0 || // Has slots OR
                  carpool.driverId == userId || // Is owner OR
                  carpool.passengers.contains(userId) // Is member
              )
          .toList();
    });
  }

  // Creates new carpool
  Future<void> createCarpool({
    required String concertId,
    required int fee,
    required int slots,
    required String imageUrl,
  }) async {
    User? user = currentUser;
    if (user == null) throw Exception('User not signed in');

    // Check if user is a member in any carpool
    if (await isUserInAnyCarpool(concertId)) {
      throw Exception('You are already a member of another carpool');
    }

    // Check if user already has an active carpool
    final existingCarpools = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('driverId', isEqualTo: user.uid)
        .where('status', isEqualTo: CarpoolStatus.active.toString())
        .get();

    if (existingCarpools.docs.isNotEmpty) {
      throw Exception('You already have an active carpool');
    }

    try {
      final userDoc = await _users.doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = '${userData['firstName']} ${userData['lastName']}';

      // Create chat room
      DocumentReference chatRoomRef = await _chatRooms.add({
        'type': 'carpool',
        'name': userName,
        'participants': [user.uid],
        'lastMessage': 'Carpool chat created',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnread': {},
      });

      // Create carpool with all necessary fields
      await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .add({
        'carpoolTitle': '$userName\'s Carpool Ride',
        'driverName': userName,
        'location': 'Not set yet',
        'fee': fee.toString(),
        'slot': slots.toString(),
        'availableSlots': slots,
        'imagePath': imageUrl,
        'chatRoomId': chatRoomRef.id,
        'driverId': user.uid,
        'passengers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'meetupLocation': 'Not set yet',
        'meetupTime': null,
        'rsvpStatus': {},
        'status': CarpoolStatus.active.toString(),
        'ratedBy': [],
        'driverRating': 0.0,
        'totalRatings': 0,
      });
    } catch (e) {
      throw Exception('Failed to create carpool');
    }
  }

  // Checks if user is in any carpool
  Future<bool> isUserInAnyCarpool(String concertId) async {
    User? user = currentUser;
    if (user == null) return false;

    final carpools = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('passengers', arrayContains: user.uid)
        .get();

    return carpools.docs.isNotEmpty;
  }

  // Joins an existing carpool
  Future<void> joinCarpool(String chatRoomId, String concertId) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    // Check if user is already in any carpool
    if (await isUserInAnyCarpool(concertId)) {
      throw Exception(
          ''); // Message will be overriden by the catch (e) of carpool_card
    }

    return _firestore.runTransaction((transaction) async {
      // Find carpool using chatRoomId
      final carpoolQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (carpoolQuery.docs.isEmpty) {
        throw Exception('Carpool not found');
      }

      final carpoolRef = carpoolQuery.docs.first.reference;
      final carpoolDoc = await transaction.get(carpoolRef);

      // Check availability
      int availableSlots = carpoolDoc.get('availableSlots');
      List<String> passengers =
          List<String>.from(carpoolDoc.get('passengers') ?? []);

      if (availableSlots <= 0) {
        throw Exception('Carpool is full');
      }

      if (passengers.contains(user.uid)) {
        throw Exception('Already joined this carpool');
      }

      // Update carpool
      transaction.update(carpoolRef, {
        'availableSlots': availableSlots - 1,
        'passengers': [...passengers, user.uid],
        'rsvpStatus.${user.uid}': 'pending',
      });

      // Update chat room
      transaction.update(_chatRooms.doc(chatRoomId), {
        'participants': FieldValue.arrayUnion([user.uid])
      });

      // Get user info for notification
      final userDoc = await _users.doc(user.uid).get();
      final username = userDoc.get('username');

      // Create notification for driver
      final driverId = carpoolDoc.get('driverId');
      if (driverId != user.uid) {
        transaction.set(
          _users.doc(driverId).collection('notifications').doc(),
          {
            'type': NotificationType.CARPOOL_MESSAGE.toString().split('.').last,
            'message': '$username has joined your carpool',
            'chatRoomId': chatRoomId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          },
        );
      }
    });
  }

  // Leaves a carpool
  Future<void> leaveCarpool(String chatRoomId, String concertId) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final carpoolQuery = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .limit(1)
        .get();

    if (carpoolQuery.docs.isEmpty) {
      throw Exception('Carpool not found');
    }

    final batch = _firestore.batch();
    final carpoolDoc = carpoolQuery.docs.first;

    // Get necessary info for notifications
    final userData = await getUserProfile();
    final username = userData['username'];
    final driverId = carpoolDoc.get('driverId');
    final passengers = List<String>.from(carpoolDoc.get('passengers') ?? []);

    // Update carpool document
    batch.update(carpoolDoc.reference, {
      'availableSlots': FieldValue.increment(1),
      'passengers': FieldValue.arrayRemove([user.uid]),
      'rsvpStatus.${user.uid}': FieldValue.delete(),
    });

    // Remove from chat room
    batch.update(_chatRooms.doc(chatRoomId), {
      'participants': FieldValue.arrayRemove([user.uid]),
    });

    // Create notifications for remaining members
    final remainingMembers = [...passengers, driverId];
    remainingMembers.remove(user.uid);

    for (String memberId in remainingMembers) {
      batch.set(
        _users.doc(memberId).collection('notifications').doc(),
        {
          'type': NotificationType.CARPOOL_MESSAGE.toString().split('.').last,
          'message': '$username has left the carpool',
          'chatRoomId': chatRoomId,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        },
      );
    }

    await batch.commit();
  }

  // Gets carpool details/info
  Stream<Map<String, dynamic>> getCarpoolInfo(
      String chatRoomId, String concertId) {
    return _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return {};
      var doc = snapshot.docs.first;
      var data = doc.data();
      // Add the document ID to the data
      data['id'] = doc.id;
      return data;
    });
  }

  // Used to update carpool meetup details
  Future<void> updateCarpoolMeetup(
    String chatRoomId,
    String concertId,
    String location,
    DateTime time,
  ) async {
    try {
      final carpoolQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (carpoolQuery.docs.isEmpty) {
        throw Exception('Carpool not found');
      }

      await carpoolQuery.docs.first.reference.update({
        'meetupLocation': location,
        'meetupTime': Timestamp.fromDate(time),
        'location': location, // Add this line to update main location too
      });
    } catch (e) {
      throw Exception('Failed to update meetup details');
    }
  }

  // Used to update carpool member's RSVP status
  Future<void> updateCarpoolRsvp(
    String chatRoomId,
    String status,
    String concertId,
  ) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    try {
      // Find carpool using chatRoomId
      final carpoolQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (carpoolQuery.docs.isEmpty) throw Exception('Carpool not found');

      final carpoolDoc = carpoolQuery.docs.first;
      final batch = _firestore.batch();

      // Update RSVP status
      batch.update(carpoolDoc.reference, {
        'rsvpStatus.${user.uid}': status,
      });

      // Get driver info for notification
      final driverId = carpoolDoc.get('driverId');
      if (driverId != user.uid) {
        final userDoc = await _users.doc(user.uid).get();
        final username = userDoc.get('username');

        batch.set(
          _users.doc(driverId).collection('notifications').doc(),
          {
            'type': 'CARPOOL_MESSAGE',
            'message': '$username is "$status" in the carpool meetup',
            'chatRoomId': chatRoomId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          },
        );
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update RSVP status: ${e.toString()}');
    }
  }

  // Kicks member from carpool
  Future<void> kickFromCarpool(
      String chatRoomId, String userId, String concertId) async {
    try {
      // Find carpool using chatRoomId
      final carpoolQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (carpoolQuery.docs.isEmpty) {
        throw Exception('Carpool not found');
      }

      final carpoolDoc = carpoolQuery.docs.first;
      final batch = _firestore.batch();

      // Update carpool document
      batch.update(carpoolDoc.reference, {
        'availableSlots': FieldValue.increment(1),
        'passengers': FieldValue.arrayRemove([userId]),
        'kickedMembers': FieldValue.arrayUnion([userId]),
        'rsvpStatus.$userId': FieldValue.delete(),
      });

      // Remove from chat room
      batch.update(_chatRooms.doc(chatRoomId), {
        'participants': FieldValue.arrayRemove([userId]),
      });

      // Create notification
      batch.set(
        _users.doc(userId).collection('notifications').doc(),
        {
          'type': 'CARPOOL_MESSAGE',
          'message': 'You have been removed from the carpool',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        },
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove member from carpool');
    }
  }

  // Checks if user can join carpool
  Future<bool> canJoinCarpool(String chatRoomId, String concertId) async {
    try {
      final carpoolQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('carpools')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .limit(1)
          .get();

      if (carpoolQuery.docs.isEmpty) return false;

      final carpoolDoc = carpoolQuery.docs.first;
      final availableSlots = carpoolDoc.get('availableSlots') ?? 0;
      final status = carpoolDoc.get('status') ?? 'CarpoolStatus.active';

      return availableSlots > 0 && status == 'CarpoolStatus.active';
    } catch (e) {
      return false;
    }
  }

  // Deletes own carpool (driver)
  Future<void> deleteOwnCarpool(String chatRoomId, String concertId) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    // Find carpool
    final carpoolQuery = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .limit(1)
        .get();

    if (carpoolQuery.docs.isEmpty) {
      throw Exception('Carpool not found');
    }

    final carpoolDoc = carpoolQuery.docs.first;

    // Check if user is the owner
    if (carpoolDoc.get('driverId') != user.uid) {
      throw Exception('Only the carpool owner can delete it');
    }

    // Delete carpool and chat room
    final batch = _firestore.batch();
    batch.delete(carpoolDoc.reference);
    batch.delete(_chatRooms.doc(chatRoomId));

    await batch.commit();
  }

  // Deletes any carpool (admin)
  Future<void> deleteCarpool(
      String concertId, String carpoolId, String chatRoomId) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    // Delete the chat room and all its messages
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();

    // Delete the carpool
    await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .doc(carpoolId)
        .delete();
  }

  // Marks carpool as complete, users will be able to rate next
  Future<void> markCarpoolComplete(String chatRoomId) async {
    try {
      final carpoolQuery = await _firestore.collection('concerts').get().then(
          (snapshot) => snapshot.docs
              .map((doc) => doc.reference
                  .collection('carpools')
                  .where('chatRoomId', isEqualTo: chatRoomId)
                  .limit(1)
                  .get())
              .first);

      if (carpoolQuery.docs.isEmpty) {
        throw Exception('Carpool not found');
      }

      final carpoolDoc = carpoolQuery.docs.first;
      final batch = _firestore.batch();

      // Update status
      batch.update(carpoolDoc.reference, {
        'status': CarpoolStatus.completed.toString(),
        'completedAt': FieldValue.serverTimestamp(),
        'ratedBy': [],
      });

      // Get list of passengers (excluding driver)
      final passengers = List<String>.from(carpoolDoc.get('passengers') ?? []);
      final driverId = carpoolDoc.get('driverId');

      // Create notifications only for passengers
      for (String userId in passengers) {
        if (userId != driverId) {
          // Skip if it's the driver
          batch.set(
            _users.doc(userId).collection('notifications').doc(),
            {
              'type':
                  NotificationType.CARPOOL_MESSAGE.toString().split('.').last,
              'message':
                  'Carpool has been marked as complete. Please rate your experience.',
              'chatRoomId': chatRoomId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            },
          );
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark carpool as complete');
    }
  }

  // Rating Methods, this is for submiting rating
  Future<void> submitRating(String concertId, String chatRoomId, double rating,
      {String? comment}) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    if (comment != null && comment.length > 50) {
      throw Exception('Comment cannot exceed 50 characters');
    }

    // Find carpool doc
    final carpoolQuery = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .limit(1)
        .get();

    if (carpoolQuery.docs.isEmpty) {
      throw Exception('Carpool not found');
    }

    final carpoolDoc = carpoolQuery.docs.first;
    final driverId = carpoolDoc.get('driverId');
    final ratedBy = List<String>.from(carpoolDoc.get('ratedBy') ?? []);
    final userData = await getUserProfile();
    final username = userData['username'];

    // Check if already rated
    if (ratedBy.contains(user.uid)) {
      throw Exception('You have already rated this carpool');
    }

    final batch = _firestore.batch();

    // Update carpool ratedBy
    batch.update(carpoolDoc.reference, {
      'ratedBy': FieldValue.arrayUnion([user.uid]),
    });

    // Update driver's ratings in their user document
    final driverRef = _users.doc(driverId);
    batch.update(driverRef, {
      'carpoolRatings': FieldValue.increment(rating),
      'totalCarpoolRatings': FieldValue.increment(1),
    });

    // Create notification for driver
    batch.set(
      _users.doc(driverId).collection('notifications').doc(),
      {
        'type': NotificationType.CARPOOL_MESSAGE.toString().split('.').last,
        'message':
            '$username rated your carpool ${rating.toStringAsFixed(1)} stars${comment != null ? '\nComment: $comment' : ''}',
        'chatRoomId': chatRoomId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      },
    );

    await batch.commit();
  }

  // Used to get driver's rating, displayed in carpool info and carpool card
  Stream<double> getDriverRating(String driverId) {
    return _firestore
        .collection('ratings')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      double total = 0;
      int count = 0;
      for (var doc in snapshot.docs) {
        double? rating = doc.get('rating');
        if (rating != null) {
          total += rating;
          count++;
        }
      }
      return count > 0 ? total / count : 0.0;
    });
  }

  // ***GROUP METHODS***
  // Gets all groups in a concert
  Stream<List<Group>> getGroups(String concertId) {
    return _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('groups')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Group.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Creates new group (only admin can but this restriction is only shown in group list)
  Future<void> createGroup({
    required String concertId,
    required String groupName,
    required String imageUrl,
  }) async {
    User? user = currentUser;
    if (user == null) throw Exception('User not signed in');

    try {
      // Get concert data
      DocumentSnapshot concertDoc =
          await _firestore.collection('concerts').doc(concertId).get();

      if (!concertDoc.exists) {
        throw Exception('Concert not found');
      }

      Map<String, dynamic> concertData =
          concertDoc.data() as Map<String, dynamic>;
      String concertName = concertData['artistName'] ??
          'Unknown Concert'; // Use artistName from concert

      // Create chat room first
      DocumentReference chatRoomRef =
          await _firestore.collection('chatRooms').add({
        'type': 'group',
        'name': groupName,
        'concertName':
            concertName, // Use the concert name from concert document
        'participants': [user.uid],
        'lastMessage': 'Group chat created',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnread': {user.uid: false},
        'concertId': concertId,
      });

      // Create group with chat room reference
      await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .add({
        'groupName': groupName,
        'imageUrl': imageUrl,
        'membersCount': 1,
        'chatRoomId': chatRoomRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'members': [user.uid],
      });
    } catch (e) {
      throw Exception('Error creating group: $e');
    }
  }

  // Joins an existing group
  Future<void> joinGroup(String concertId, String groupId) async {
    User? user = currentUser;
    if (user == null) throw Exception('User not signed in');

    return _firestore.runTransaction((transaction) async {
      // First get the group document
      DocumentReference groupRef = _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .doc(groupId);

      DocumentSnapshot groupDoc = await transaction.get(groupRef);

      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;

      // Check if user is creator
      final isCreator = groupData['createdBy'] == user.uid;

      // Check for kicked/left members if not creator
      if (!isCreator) {
        // Safely get lists with null checks
        final kickedMembers =
            List<String>.from(groupData['kickedMembers'] ?? []);
        final leftMembers = List<String>.from(groupData['leftMembers'] ?? []);

        if (kickedMembers.contains(user.uid) ||
            leftMembers.contains(user.uid)) {
          throw Exception('You cannot join this group');
        }
      }

      // Get members list and check if already a member
      List<String> members = List<String>.from(groupData['members'] ?? []);
      if (members.contains(user.uid)) {
        return; // Already a member, just return
      }

      // Get chat room reference
      String chatRoomId = groupData['chatRoomId'];
      DocumentReference chatRoomRef =
          _firestore.collection('chatRooms').doc(chatRoomId);
      DocumentSnapshot chatRoomDoc = await transaction.get(chatRoomRef);

      if (!chatRoomDoc.exists) {
        throw Exception('Chat room not found');
      }

      Map<String, dynamic> chatData =
          chatRoomDoc.data() as Map<String, dynamic>;

      // Get current participants
      List<String> participants =
          List<String>.from(chatData['participants'] ?? []);

      // Prepare unread status
      Map<String, dynamic> hasUnread =
          Map<String, dynamic>.from(chatData['hasUnread'] ?? {});
      for (String participantId in participants) {
        hasUnread[participantId] = participantId != user.uid;
      }
      hasUnread[user.uid] = false;

      // Update group document
      transaction.update(groupRef, {
        'membersCount': members.length + 1,
        'members': FieldValue.arrayUnion([user.uid]),
      });

      // Update chat room
      transaction.update(chatRoomRef, {
        'participants': FieldValue.arrayUnion([user.uid]),
        'lastMessage': 'New member joined the group',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'hasUnread': hasUnread,
      });

      // Get user info for notification
      final userDoc = await _users.doc(user.uid).get();
      final username = userDoc.get('username');

      // Get current participants to notify them
      List<String> currentParticipants =
          List<String>.from(chatData['participants'] ?? []);
      currentParticipants.remove(user.uid); // Don't notify the joiner

      // Create notifications for existing members
      for (String memberId in currentParticipants) {
        transaction.set(
          _users.doc(memberId).collection('notifications').doc(),
          {
            'type': NotificationType.GROUP_MESSAGE.toString().split('.').last,
            'message': '$username has joined the group',
            'chatRoomId': chatRoomId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          },
        );
      }
    });
  }

  // Check if user can join group
  Future<bool> canJoinGroup(
      String chatRoomId, String userId, String concertId) async {
    try {
      // First get the group document using chatRoomId
      QuerySnapshot groupQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      if (groupQuery.docs.isEmpty) {
        return false;
      }

      DocumentSnapshot groupDoc = groupQuery.docs.first;
      final data = groupDoc.data() as Map<String, dynamic>;

      // Always allow group creator to join
      if (data['createdBy'] == userId) {
        return true;
      }

      // Check for kicked or left members
      final kickedMembers = List<String>.from(data['kickedMembers'] ?? []);
      final leftMembers = List<String>.from(data['leftMembers'] ?? []);

      return !kickedMembers.contains(userId) && !leftMembers.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Leaves a group
  Future<void> leaveGroup(String chatRoomId, String concertId) async {
    User? user = currentUser;
    if (user == null) throw Exception('Not signed in');

    final batch = _firestore.batch();

    try {
      // First get the group document using chatRoomId
      QuerySnapshot groupQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Group not found');
      }

      DocumentSnapshot groupDoc = groupQuery.docs.first;

      // Update group document
      batch.update(groupDoc.reference, {
        'membersCount': FieldValue.increment(-1),
        'members': FieldValue.arrayRemove([user.uid]),
        'leftMembers': FieldValue.arrayUnion([user.uid]), // Track who left
      });

      // Remove from chat room participants
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      batch.update(chatRoomRef, {
        'participants': FieldValue.arrayRemove([user.uid]),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to leave group: ${e.toString()}');
    }
  }

  // Kicks member from group
  Future<void> kickFromGroup(
      String chatRoomId, String userId, String concertId) async {
    final batch = _firestore.batch();

    try {
      // First find the group document using chatRoomId
      QuerySnapshot groupQuery = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('groups')
          .where('chatRoomId', isEqualTo: chatRoomId)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Group not found');
      }

      DocumentSnapshot groupDoc = groupQuery.docs.first;

      // Update members count and list in group
      batch.update(groupDoc.reference, {
        'membersCount': FieldValue.increment(-1),
        'members': FieldValue.arrayRemove([userId]),
        'kickedMembers':
            FieldValue.arrayUnion([userId]), // Keep track of kicked members
      });

      // Remove from chat room participants
      final chatRoomRef = _firestore.collection('chatRooms').doc(chatRoomId);
      batch.update(chatRoomRef, {
        'participants': FieldValue.arrayRemove([userId]),
      });

      // Add notification for kicked user
      final notifRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'type': 'GROUP_MESSAGE',
        'message': 'You have been removed from the group',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to kick member: ${e.toString()}');
    }
  }

  // Deletes group (admin only)
  Future<void> deleteGroup(
      String concertId, String groupId, String chatRoomId) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    // Delete the chat room and all its messages
    await _firestore.collection('chatRooms').doc(chatRoomId).delete();

    // Delete the group
    await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('groups')
        .doc(groupId)
        .delete();
  }

  // ***TICKET AND VERIFICATION METHODS***
  // Gets list of tickets of a concert
  Stream<List<Ticket>> getTickets(String concertId) {
    return _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('tickets')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Ticket.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Creates a new ticket link
  Future<void> createTicket({
    required String concertId,
    required String ticketName,
    required String url,
  }) async {
    try {
      // Get concert details for the notification
      DocumentSnapshot concertDoc =
          await _firestore.collection('concerts').doc(concertId).get();
      String concertName = concertDoc.get('artistName') ?? 'Unknown Concert';

      // Create the ticket
      DocumentReference ticketRef = await _firestore
          .collection('concerts')
          .doc(concertId)
          .collection('tickets')
          .add({
        'ticketName': ticketName,
        'url': url,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get all users who have notifications enabled for ticket updates
      QuerySnapshot usersSnapshot = await _firestore
          .collection('users')
          .where('notificationSettings.ticketUpdates', isEqualTo: true)
          .get();

      // Create notifications for these users
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        if (userDoc.id != currentUser?.uid) {
          // Don't notify the admin who created it
          DocumentReference notifRef = _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('notifications')
              .doc();

          batch.set(notifRef, {
            'type': 'TICKET_UPDATE',
            'message': 'New ticket available for $concertName: $ticketName',
            'concertId': concertId,
            'ticketId': ticketRef.id,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  // Deletes ticket (admin only)
  Future<void> deleteTicket(String concertId, String ticketId) async {
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    // Get ticket and concert details before deletion
    DocumentSnapshot ticketDoc = await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('tickets')
        .doc(ticketId)
        .get();

    DocumentSnapshot concertDoc =
        await _firestore.collection('concerts').doc(concertId).get();

    String ticketName = ticketDoc.get('ticketName') ?? 'Unknown Ticket';
    String concertName = concertDoc.get('artistName') ?? 'Unknown Concert';

    // Delete the ticket
    await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('tickets')
        .doc(ticketId)
        .delete();

    // Notify users
    QuerySnapshot usersSnapshot = await _firestore
        .collection('users')
        .where('notificationSettings.ticketUpdates', isEqualTo: true)
        .get();

    final batch = _firestore.batch();
    for (var userDoc in usersSnapshot.docs) {
      DocumentReference notifRef = _firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'type': 'TICKET_UPDATE',
        'message': 'Ticket no longer available for $concertName: $ticketName',
        'concertId': concertId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }
    await batch.commit();
  }

  // Submits ticket for verification
  Future<void> submitTicketVerification(String concertId, File image) async {
    User? user = currentUser;
    if (user == null) throw Exception('User not signed in');

    try {
      // First, delete any existing pending verifications for this user and concert
      QuerySnapshot existingVerifications = await _firestore
          .collection('ticket_verifications')
          .where('userId', isEqualTo: user.uid)
          .where('concertId', isEqualTo: concertId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Delete found documents in a batch
      final batch = _firestore.batch();
      for (var doc in existingVerifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Upload new image to Firebase Storage
      final ref = _storage.ref().child(
          'ticket_verifications/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(image);
      final imageUrl = await ref.getDownloadURL();

      // Get user data
      DocumentSnapshot userDoc = await _users.doc(user.uid).get();
      String userName =
          '${userDoc.get('firstName')} ${userDoc.get('lastName')}';

      // Create new verification document
      await _firestore.collection('ticket_verifications').add({
        'userId': user.uid,
        'concertId': concertId,
        'imageUrl': imageUrl,
        'isApproved': false,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'userName': userName,
      });
    } catch (e) {
      throw Exception('Failed to submit ticket verification: $e');
    }
  }

  // Gets list of pending ticket verifications shown in ticket approvals page
  Stream<List<TicketVerification>> getPendingVerifications() {
    return _firestore
        .collection('ticket_verifications')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true) // Get newest first
        .snapshots()
        .map((snapshot) {
      final verifications = snapshot.docs
          .map((doc) => TicketVerification.fromMap(doc.data(), doc.id))
          .toList();

      // Keep only the latest submission per user/concert combination
      final Map<String, TicketVerification> latestVerifications = {};
      for (var verification in verifications) {
        final key = '${verification.userId}_${verification.concertId}';
        if (!latestVerifications.containsKey(key)) {
          latestVerifications[key] = verification;
        }
      }

      return latestVerifications.values.toList();
    });
  }

  // Checks ticket verification status
  Stream<bool> checkVerificationStatus(String concertId) {
    User? user = currentUser;
    if (user == null) return Stream.value(false);

    // For admins and super admins
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .asyncMap((userDoc) async {
      // Check admin status
      final isAdmin = userDoc.data()?['isAdmin'] ?? false;
      final isSuperAdmin = userDoc.data()?['isSuperAdmin'] ?? false;
      if (isAdmin || isSuperAdmin) return true;

      // For regular users, check verification status
      QuerySnapshot verifications = await _firestore
          .collection('ticket_verifications')
          .where('userId', isEqualTo: user.uid)
          .where('concertId', isEqualTo: concertId)
          .where('isApproved', isEqualTo: true)
          .get();

      return verifications.docs.isNotEmpty;
    });
  }

  // Approves ticket verification (admin only)
  Future<void> approveVerification(String verificationId) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized action');

    User? admin = currentUser;
    if (admin == null) throw Exception('Admin not signed in');

    // Get the verification document
    DocumentSnapshot verificationDoc = await _firestore
        .collection('ticket_verifications')
        .doc(verificationId)
        .get();

    final data = verificationDoc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final concertId = data['concertId'];

    // Get concert details for the message
    DocumentSnapshot concertDoc =
        await _firestore.collection('concerts').doc(concertId).get();
    final concertData = concertDoc.data() as Map<String, dynamic>;
    final artistName = concertData['artistName'];

    // Update verification status
    await _firestore
        .collection('ticket_verifications')
        .doc(verificationId)
        .update({
      'isApproved': true,
      'status': 'approved',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': admin.uid,
    });

    // Create notification for user
    await createNotification(
      type: NotificationType.USER_STATUS,
      message:
          'Welcome to the $artistName concert! Your ticket has been verified successfully.',
      concertId: concertId,
      recipients: [userId],
    );
  }

  // Rejects a ticket verification (admin only)
  Future<void> rejectVerification(String verificationId, String reason) async {
    if (!await isUserAdmin()) throw Exception('Unauthorized action');

    User? admin = currentUser;
    if (admin == null) throw Exception('Admin not signed in');

    // Get the verification document
    DocumentSnapshot verificationDoc = await _firestore
        .collection('ticket_verifications')
        .doc(verificationId)
        .get();

    final data = verificationDoc.data() as Map<String, dynamic>;
    final userId = data['userId'];
    final concertId = data['concertId'];

    // Get concert details for the message
    DocumentSnapshot concertDoc =
        await _firestore.collection('concerts').doc(concertId).get();
    final concertData = concertDoc.data() as Map<String, dynamic>;
    final artistName = concertData['artistName'];

    await _firestore
        .collection('ticket_verifications')
        .doc(verificationId)
        .update({
      'isApproved': false,
      'status': 'rejected',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': admin.uid,
      'rejectionReason': reason,
    });

    // Create notification with specific concert name
    await createNotification(
      type: NotificationType.USER_STATUS,
      message:
          'Unfortunately, your ticket verification for $artistName concert was rejected. Reason: $reason',
      concertId: concertId,
      recipients: [userId],
    );
  }

  // ***NOTIFICATION METHODS***
  // Creates notif for specific users
  Future<void> createNotification({
    required NotificationType type,
    required String message,
    String? concertId,
    String? chatRoomId,
    String? senderId,
    required List<String> recipients,
  }) async {
    final batch = _firestore.batch();

    for (String userId in recipients) {
      // Check if user should receive this type of notification
      if (!await shouldSendNotification(userId, type)) continue;

      DocumentReference notifRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

      batch.set(notifRef, {
        'type': type.toString().split('.').last,
        'message': message,
        'concertId': concertId,
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();
  }

  // Basically sends notifs to multiple users in batch
  Future<void> sendBatchNotifications({
    required List<String> recipients,
    required NotificationType type,
    required String message,
    String? concertId,
    String? chatRoomId,
    String? ticketId,
    String? senderId,
  }) async {
    final batch = _firestore.batch();

    for (String userId in recipients) {
      if (!await shouldSendNotification(userId, type)) continue;

      DocumentReference notifRef =
          _users.doc(userId).collection('notifications').doc();

      batch.set(notifRef, {
        'type': type.toString().split('.').last,
        'message': message,
        'concertId': concertId,
        'chatRoomId': chatRoomId,
        'ticketId': ticketId,
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    }

    await batch.commit();
  }

  // Gets user's notif stream
  Stream<List<NotificationModel>> getUserNotifications() {
    User? user = currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Gets user's notification settings
  Stream<Map<String, dynamic>> getUserNotificationSettings() {
    User? user = currentUser;
    if (user == null) return Stream.value({});

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return _getDefaultSettings();
      Map<String, dynamic>? data = doc.data();
      return data?['notificationSettings'] ?? _getDefaultSettings();
    });
  }

  // Initializes default settings for new users
  Future<void> initializeNotificationSettings() async {
    User? user = currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists ||
        !(userDoc.data() as Map<String, dynamic>)
            .containsKey('notificationSettings')) {
      await _firestore.collection('users').doc(user.uid).set({
        'notificationSettings': _getDefaultSettings(),
      }, SetOptions(merge: true));
    }
  }

// Updates a specific notif setting
  Future<void> updateNotificationSetting(String setting, bool value) async {
    User? user = currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'notificationSettings.$setting': value,
    });
  }

  // Marks a single notif as read
  Future<void> markNotificationAsRead(String notificationId) async {
    User? user = currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Marks all user's notifications as read
  Future<void> markAllNotificationsAsRead() async {
    User? user = currentUser;
    if (user == null) return;

    // Get all unread notifications
    QuerySnapshot unreadNotifications = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    // Create a batch write
    WriteBatch batch = _firestore.batch();

    // Mark each notification as read
    for (var doc in unreadNotifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Commit the batch
    await batch.commit();
  }

  // Deletes a single notif
  Future<void> deleteNotification(String notificationId) async {
    User? user = currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Clears all notifs
  Future<void> clearAllNotifications() async {
    User? user = currentUser;
    if (user == null) return;

    try {
      // Get all user's notifications
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      // Create a batch write
      final batch = _firestore.batch();

      // Add delete operations to batch
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear notifications: $e');
    }
  }

  // Notification Helper Methods
  // Method for getting users subscribed to updates
  Future<List<String>> _getUpdatesSubscribers({NotificationType? type}) async {
    String settingKey;
    switch (type) {
      case NotificationType.CONCERT_UPDATE:
        settingKey = 'concertUpdates';
        break;
      case NotificationType.TICKET_UPDATE:
        settingKey = 'ticketUpdates';
        break;
      case NotificationType.GROUP_MESSAGE:
        settingKey = 'groupMessages';
        break;
      case NotificationType.CARPOOL_MESSAGE:
        settingKey = 'carpoolMessages';
        break;
      default:
        settingKey = 'concertUpdates';
    }

    QuerySnapshot snapshot = await _users
        .where('notificationSettings.$settingKey', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Helper method to check if notification should be sent based on settings
  Future<bool> shouldSendNotification(
      String userId, NotificationType type) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) return false;

    Map<String, dynamic>? settings =
        (userDoc.data() as Map<String, dynamic>)['notificationSettings'];
    if (settings == null) return true;

    switch (type) {
      case NotificationType.CONCERT_UPDATE:
        return settings['concertUpdates'] ?? true;
      case NotificationType.GROUP_MESSAGE:
        return settings['groupMessages'] ?? true;
      case NotificationType.CARPOOL_MESSAGE:
        return settings['carpoolMessages'] ?? true;
      case NotificationType.TICKET_UPDATE:
        return settings['ticketUpdates'] ?? true;
      case NotificationType.USER_STATUS:
        return true;
    }
  }

  // Helper method for default settings, all enabled by default, can be changed by user
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'ticketUpdates': true,
      'groupMessages': true,
      'carpoolMessages': true,
      'concertUpdates': true,
      'soundEnabled': true,
      'vibrationEnabled': true,
    };
  }

  // Navigation handler for notif clicks, as in going to different pages depending on notif
  void handleNotificationNavigation(
      BuildContext context, NotificationModel notification) async {
    bool isAdmin = await isUserAdmin();

    switch (notification.type) {
      case NotificationType.GROUP_MESSAGE:
      case NotificationType.CARPOOL_MESSAGE:
        Navigator.push(
          // Changed to push instead of pushAndRemoveUntil
          context,
          MaterialPageRoute(
            builder: (context) => const MessagesPage(),
          ),
        );
        break;

      case NotificationType.CONCERT_UPDATE:
        if (notification.concertId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConcertDetailsPage(
                concertId: notification.concertId!,
                isAdmin: isAdmin, // Pass isAdmin here
              ),
            ),
          );
        }
        break;

      case NotificationType.TICKET_UPDATE:
        if (notification.concertId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketMarketPage(
                concertId: notification.concertId!,
              ),
            ),
          );
        }
        break;

      case NotificationType.USER_STATUS:
        Navigator.pop(context);
        break;
    }
  }

  // ***USER MANAGEMENT METHODS***
  // **Basic User Methods**
  // Fetch user data(for concert list and chat atm)
  Future<Map<String, dynamic>> getUserData(String uid) async {
    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();
    return userDoc.data() as Map<String, dynamic>;
  }

  // In Profile page
  Future<Map<String, dynamic>> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      return doc.data() as Map<String, dynamic>;
    }
    throw Exception('User not found');
  }

  // Gets all users and shown in Users Page
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // **Profile Management**
  // Updates user profile info
  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? newPassword,
    required String currentPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('User not found');

    // Re-authenticate user
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update Firestore document
    Map<String, dynamic> updates = {};
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;

    // Only check username availability if username is being updated
    if (username != null) {
      // Check if the new username is different from current username
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      String currentUsername = doc.get('username') ?? '';

      if (username != currentUsername) {
        bool isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) throw Exception('Username is already taken');

        Timestamp? lastUsernameChange =
            doc.get('lastUsernameChange') as Timestamp?;
        if (lastUsernameChange != null) {
          Duration difference =
              Timestamp.now().toDate().difference(lastUsernameChange.toDate());
          if (difference.inDays < 30) {
            throw Exception(
                'You can only change your username once every 30 days');
          }
        }

        updates['username'] = username;
        updates['lastUsernameChange'] = Timestamp.now();
      }
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(updates);
    }

    // Update email if changed
    if (email != null && email != user.email) {
      try {
        await user.verifyBeforeUpdateEmail(email);
      } catch (e) {
        throw Exception('Failed to update email: ${e.toString()}');
      }
    }

    // Update password if provided
    if (newPassword != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Updating of profile pictures
  Future<void> updateProfilePicture(String imagePath) async {
    User? user = currentUser;
    if (user == null) throw Exception('User not found');

    try {
      // Upload image to Firebase Storage
      final ref = _storage.ref().child('profile_pictures/${user.uid}.jpg');
      await ref.putFile(File(imagePath));
      final imageUrl = await ref.getDownloadURL();

      // Update user document with new image URL
      await _firestore.collection('users').doc(user.uid).update({
        'profilePicture': imageUrl,
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  // Check if username is available, also limits length from 3 to 20
  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3 || username.length > 20) {
      return false;
    }
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  // **Admin Role Methods**
  // Promote to admin
  Future<void> promoteUser(String userId) async {
    // Only super admins can promote users to admin
    if (!await isUserSuperAdmin()) {
      throw Exception('Unauthorized: Super Admin access required');
    }

    final batch = _firestore.batch();

    // Update user document
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {'isAdmin': true});

    // Create notification for the user
    final notifRef = userRef.collection('notifications').doc();
    batch.set(notifRef, {
      'type': 'USER_STATUS',
      'message': 'You have been promoted to admin',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await batch.commit();
  }

  // Demote admin
  Future<void> demoteAdmin(String userId) async {
    try {
      // Only super admins can demote admins
      if (!await isUserSuperAdmin()) {
        throw Exception('Unauthorized: Super Admin access required');
      }

      // Get the target user document
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      // Check if target user is a super admin
      if (userData['isSuperAdmin'] == true) {
        throw Exception('Cannot demote a Super Admin');
      }

      // Update user document directly without batch
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isAdmin': false});

      // Create notification separately
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'USER_STATUS',
        'message': 'You have been demoted from admin role',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      throw Exception('Failed to demote admin: ${e.toString()}');
    }
  }

  // **Ban Management**
  Future<void> banUser(
    String userId, {
    required String reason,
    Duration? duration,
  }) async {
    // Check if the current user is an admin
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    // Get target user data
    DocumentSnapshot targetUserDoc = await _users.doc(userId).get();
    Map<String, dynamic> targetUserData =
        targetUserDoc.data() as Map<String, dynamic>;

    // Prevent banning super admins
    if (targetUserData['isSuperAdmin'] == true) {
      throw Exception('Cannot ban a Super Admin');
    }

    // If target is an admin, only super admin can ban them
    if (targetUserData['isAdmin'] == true && !(await isUserSuperAdmin())) {
      throw Exception('Only Super Admins can ban other admins');
    }

    final currentAdmin = _auth.currentUser;
    if (currentAdmin == null) {
      throw Exception('Admin not authenticated');
    }

    final batch = _firestore.batch();
    final now = DateTime.now();
    final endDate = duration != null ? now.add(duration) : null;

    try {
      // Create new ban record
      final banRecord = BanRecord(
        adminId: currentAdmin.uid,
        reason: reason.trim().isNotEmpty ? reason : 'No reason provided',
        startDate: now,
        endDate: endDate,
        isActive: true,
      );

      final userRef = _firestore.collection('users').doc(userId);

      // If banning an admin, remove their admin status
      if (targetUserData['isAdmin'] == true) {
        batch.update(userRef, {'isAdmin': false});
      }

      // Update user document
      batch.update(userRef, {
        'isBanned': true,
        'currentBanEnd': endDate != null ? Timestamp.fromDate(endDate) : null,
        'banHistory': FieldValue.arrayUnion([banRecord.toMap()]),
      });

      // Create notification
      final notifRef = userRef.collection('notifications').doc();
      final banMessage = endDate != null
          ? ' until ${DateFormat('MMM d, y h:mm a').format(endDate)}'
          : ' permanently';

      batch.set(notifRef, {
        'type': 'USER_STATUS',
        'message':
            'Your account has been banned$banMessage\nReason: ${banRecord.reason}',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to ban user: ${e.toString()}');
    }
  }

  // Method to unban user
  Future<void> unbanUser(String userId) async {
    // Check if the current user is an admin
    if (!await isUserAdmin()) {
      throw Exception('Unauthorized: Admin access required');
    }

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);

    try {
      // Get current user data
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final banHistory =
          List<Map<String, dynamic>>.from(userData['banHistory'] ?? []);

      // Mark the latest ban as inactive if it exists
      if (banHistory.isNotEmpty) {
        banHistory.last['isActive'] = false;
      }

      // Update user document
      batch.update(userRef, {
        'isBanned': false,
        'currentBanEnd': null,
        'banHistory': banHistory,
      });

      // Create notification
      final notifRef = userRef.collection('notifications').doc();
      batch.set(notifRef, {
        'type': 'USER_STATUS',
        'message': 'Your account has been unbanned',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unban user: ${e.toString()}');
    }
  }

  // Check ban status of user
  Future<void> enforceUserStatus() async {
    User? user = currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) return;

    final userData = userDoc.data() as Map<String, dynamic>;
    final isBanned = userData['isBanned'] ?? false;
    final currentBanEnd = userData['currentBanEnd'] as Timestamp?;

    if (isBanned) {
      // Check if it's a temporary ban that has expired
      if (currentBanEnd != null &&
          currentBanEnd.toDate().isBefore(DateTime.now())) {
        // Ban has expired, automatically unban the user
        await unbanUser(user.uid);
      } else {
        // User is still banned (either permanent or temporary ban still active)
        await signOut();
        // Error message for banned user
        final banMessage = currentBanEnd != null
            ? 'Account suspended until ${currentBanEnd.toDate().toLocal()}'
            : 'Account permanently suspended';
        throw Exception(banMessage);
      }
    }
  }

  // Checks if user is banned
  Stream<bool> isUserBanned() {
    User? user = currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.data()?['isBanned'] ?? false);
  }

  Future<void> updateConcert(String concertId, Concert concert) async {
    await _firestore
        .collection('concerts')
        .doc(concertId)
        .update(concert.toMap());
  }

  Future<void> addCarpool(String concertId, Carpool carpool) async {
    await _firestore
        .collection('concerts')
        .doc(concertId)
        .collection('carpools')
        .add(carpool.toMap());
  }

  // **Email Verification**
  // Used to update email verification status for faster checking (if changes happen)
  Future<void> updateEmailVerificationStatus(String userId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user?.uid == userId) {
      await user?.reload(); // Refresh the user's status
      await _users.doc(userId).update({
        'isEmailVerified': user?.emailVerified ?? false,
      });
    }
  }

  // Another method to update email verification asap
  Future<void> checkAndUpdateEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Force refresh the user object
      await _users.doc(user.uid).update({
        'emailVerified': user.emailVerified,
      });
    }
  }

  // Called after doing email verification, to send email to user
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      await checkAndUpdateEmailVerification();
      await _users.doc(user.uid).update({
        'emailVerified': false,
      });
    }
  }

  // Updates user email with verification
  Future<void> updateEmail(String newEmail, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not found');

      // Re-authenticate user before email change
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Send verification to new email
      await user.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      throw Exception('Failed to update email: ${e.toString()}');
    }
  }

  // Sends email to user for password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Listener if email changes, updates email displayed in app
  void listenToEmailChanges(Function(String) onEmailChanged) {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        onEmailChanged(user.email ?? '');
      }
    });
  }
}
