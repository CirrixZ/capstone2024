import 'package:cached_network_image/cached_network_image.dart';
import 'package:capstone/core/helpers/custom_page_transitions.dart';
import 'package:capstone/features/group_list/screens/group_info_page.dart';
import 'package:capstone/features/shared/widgets/message_details_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:capstone/features/chat/models/message_model.dart';
import 'package:capstone/features/chat/widgets/chat_message_bubble.dart';
import 'package:capstone/features/chat/widgets/chat_input_field.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/chat/widgets/timestamp_display.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String concertId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.concertId,
  });

  @override
  GroupChatScreenState createState() => GroupChatScreenState();
}

class GroupChatScreenState extends State<GroupChatScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _firebaseService.markChatAsRead(widget.groupId);
    _initializeGroupChat();
  }

  Future<void> _initializeGroupChat() async {
    try {
      // Get group document first to get the correct group ID
      QuerySnapshot groupQuery = await FirebaseFirestore.instance
          .collection('concerts')
          .doc(widget.concertId)
          .collection('groups')
          .where('chatRoomId', isEqualTo: widget.groupId)
          .get();

      if (groupQuery.docs.isEmpty) {
        throw Exception('Group not found');
      }

      String groupDocId = groupQuery.docs.first.id;

      // Now join with the correct group document ID
      await _firebaseService.joinGroup(widget.concertId, groupDocId);
      await _firebaseService.markChatAsRead(widget.groupId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error accessing group chat: ${e.toString()}')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showImage(
      BuildContext context, String imageUrl, Message message, bool isMe) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onLongPress: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (context) => MessageDetailsDialog(
                message: message,
                chatRoomId: widget.groupId, // or widget.groupId
                isMe: isMe,
              ),
            );
          },
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (context, url) => Container(
                color: const Color(0xFF2F1552),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firebaseService.getGroupDetails(widget.groupId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              var data = snapshot.data!.data() as Map<String, dynamic>?;
              return Text(
                data?['name'] ?? 'Group Chat',
                style: TextStyle(color: Colors.white),
              );
            }
            return Text('Group Chat', style: TextStyle(color: Colors.white));
          },
        ),
        backgroundColor: Color(0xFF180B2D),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              AppPageRoute(
                page: GroupInfoPage(
                  groupId: widget.groupId,
                  concertId: widget.concertId,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _firebaseService.getMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                List<Message> messages = snapshot.data!;
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.95,
                  child: ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final showTimestamp = index == messages.length - 1 ||
                          !message.isSameDay(messages[index + 1]) ||
                          message
                              .isSignificantTimeDifference(messages[index + 1]);
                      final isMe =
                          message.senderId == _firebaseService.currentUser?.uid;

                      return Column(
                        children: [
                          if (showTimestamp)
                            TimestampDisplay(
                                timestamp: message.timestamp.toDate()),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  FutureBuilder<Map<String, dynamic>>(
                                    future: _firebaseService
                                        .getUserData(message.senderId),
                                    builder: (context, snapshot) {
                                      return CircleAvatar(
                                        radius: 16,
                                        backgroundImage: snapshot.hasData &&
                                                snapshot.data?[
                                                        'profilePicture'] !=
                                                    null
                                            ? CachedNetworkImageProvider(
                                                snapshot
                                                    .data!['profilePicture'])
                                            : null,
                                        backgroundColor: Colors.grey[300],
                                        child: (!snapshot.hasData ||
                                                snapshot.data?[
                                                        'profilePicture'] ==
                                                    null)
                                            ? Icon(Icons.person,
                                                size: 20,
                                                color: Colors.grey[600])
                                            : null,
                                      );
                                    },
                                  ),
                                  SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMe)
                                        FutureBuilder<String>(
                                          future: _firebaseService
                                              .getUserName(message.senderId),
                                          builder: (context, snapshot) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 4.0, bottom: 2.0),
                                              child: Text(
                                                snapshot.data ?? '',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      message.imageUrl != null
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: GestureDetector(
                                                onTap: () => _showImage(
                                                    context,
                                                    message.imageUrl!,
                                                    message,
                                                    isMe),
                                                onLongPress: () => showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      MessageDetailsDialog(
                                                    message: message,
                                                    chatRoomId: widget.groupId,
                                                    isMe: isMe,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: CachedNetworkImage(
                                                    imageUrl: message.imageUrl!,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (context, url) =>
                                                            Container(
                                                      color: const Color(
                                                          0xFF2F1552),
                                                      child: const Center(
                                                          child:
                                                              CircularProgressIndicator()),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        const Icon(Icons.error),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ChatMessageBubble(
                                              message: message,
                                              isMe: isMe,
                                              chatRoomId: widget.groupId,
                                            ),
                                    ],
                                  ),
                                ),
                                if (isMe) SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ChatInputField(
            onSendMessage: (text) =>
                _firebaseService.sendMessage(widget.groupId, text),
            onSendImage: (imagePath) =>
                _firebaseService.sendImage(widget.groupId, imagePath),
          ),
        ],
      ),
    );
  }
}
