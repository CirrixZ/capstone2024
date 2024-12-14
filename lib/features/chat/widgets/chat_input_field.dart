import 'dart:io';
import 'package:capstone/core/components/image_picker_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputField extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String) onSendImage;
  final int maxCharacters;

  const ChatInputField({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    this.maxCharacters = 1000,
  });

  @override
  ChatInputFieldState createState() => ChatInputFieldState();
}

class ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _messageController = TextEditingController();
  int _currentCharCount = 0;

  @override
  void initState() {
    super.initState();
    // Add listener to update character count in real-time
    _messageController.addListener(_updateCharCount);
  }

  void _updateCharCount() {
    setState(() {
      _currentCharCount = _messageController.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () => _sendImage(ImageSource.camera),
              ),
              IconButton(
                icon: Icon(Icons.image, color: Colors.white),
                onPressed: () => _sendImage(ImageSource.gallery),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 120, // Limit max height to 4-5 lines
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Colors.white),
                    maxLength: widget.maxCharacters,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    maxLines: null, // Allow multiple lines
                    keyboardType:
                        TextInputType.multiline, // Enable multiline keyboard
                    textInputAction: TextInputAction
                        .newline, // Change input action to newline
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle: TextStyle(color: Colors.grey),
                      counterText: '', // Hide default counter
                      filled: true,
                      fillColor: Color(0xFF2E2E4D),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) {
                      // This allows adding a new line when enter is pressed
                      _messageController.text += '\n';
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ],
          ),
          // Character count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$_currentCharCount/${widget.maxCharacters}',
                  style: TextStyle(
                      color: _currentCharCount > widget.maxCharacters
                          ? Colors.red
                          : Colors.grey,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && message.length <= widget.maxCharacters) {
      widget.onSendMessage(message);
      _messageController.clear();
    }
  }

  void _sendImage(ImageSource source) async {
    final File? image = await ImagePickerUtil.pickAndCropChatImage(context);
    if (image != null) {
      widget.onSendImage(image.path);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_updateCharCount);
    _messageController.dispose();
    super.dispose();
  }
}
