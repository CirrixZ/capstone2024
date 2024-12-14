import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';

class ImagePickerUtil {
  static Future<File?> pickAndCropImage(BuildContext context) async {
    try {
      // Show modal bottom sheet for image source selection
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: const Color(0xFF2F1552),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Image Source',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceButton(
                      context,
                      Icons.camera_alt,
                      'Camera',
                      ImageSource.camera,
                    ),
                    _buildSourceButton(
                      context,
                      Icons.photo_library,
                      'Gallery',
                      ImageSource.gallery,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return null;

      // Pick image
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile == null) return null;

      // Crop image
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        compressQuality: 70,
        maxWidth: 1920,
        maxHeight: 1080,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: const Color(0xFF2F1552),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF180B2D),
            activeControlsWidgetColor: const Color(0xFF6A00F4),
            hideBottomControls: true,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      return null;
    }
  }

  // For profile pictures
  static Future<File?> pickAndCropProfileImage(BuildContext context) async {
    try {
      // Show modal bottom sheet for image source selection
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: const Color(0xFF2F1552),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Picture',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSourceButton(
                      context,
                      Icons.camera_alt,
                      'Camera',
                      ImageSource.camera,
                    ),
                    _buildSourceButton(
                      context,
                      Icons.photo_library,
                      'Gallery',
                      ImageSource.gallery,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return null;

      // Pick image
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (pickedFile == null) return null;

      // Crop image with circular crop area
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 70,
        maxWidth: 1000,
        maxHeight: 1000,
        aspectRatio: const CropAspectRatio(
            ratioX: 1, ratioY: 1), // Locking 1:1 ratio for circular crop
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF2F1552),
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF180B2D),
            activeControlsWidgetColor: const Color(0xFF6A00F4),
            hideBottomControls: true,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            cancelButtonTitle: 'Cancel',
            doneButtonTitle: 'Done',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            rotateButtonsHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return null;
      return File(croppedFile.path);
    } catch (e) {
      return null;
    }
  }

  // For chats
  static Future<File?> pickAndCropChatImage(BuildContext context) async {
  try {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF2F1552),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    context,
                    Icons.camera_alt,
                    'Camera',
                    ImageSource.camera,
                  ),
                  _buildSourceButton(
                    context,
                    Icons.photo_library,
                    'Gallery',
                    ImageSource.gallery,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (pickedFile == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
      // Remove aspect ratio constraint to allow free cropping
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: const Color(0xFF2F1552),
          toolbarWidgetColor: Colors.white,
          backgroundColor: const Color(0xFF180B2D),
          activeControlsWidgetColor: const Color(0xFF6A00F4),
          hideBottomControls: true,
          lockAspectRatio: false,  // Allow free aspect ratio
        ),
        IOSUiSettings(
          title: 'Crop Image',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          aspectRatioLockEnabled: false,  // Allow free aspect ratio
          resetAspectRatioEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return null;
    return File(croppedFile.path);
  } catch (e) {
    return null;
  }
}

  static Widget _buildSourceButton(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, source);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6A00F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
