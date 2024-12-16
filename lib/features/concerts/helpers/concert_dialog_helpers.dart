// lib/features/concerts/helpers/concert_dialog_helpers.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:capstone/core/constants/colors.dart';
import 'package:capstone/core/components/image_picker_utils.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/features/concerts/models/concert_model.dart';
import 'package:capstone/features/concerts/widgets/dialog_components.dart';
import 'package:intl/intl.dart';

// This is where concert details gets the speedDial to edit concert details
class ConcertDialogHelpers {
  final FirebaseService _firebaseService;
  final dateFormat = DateFormat('MMMM d, yyyy');
  final labelMap = {
    'artistName': 'Artist Name',
    'concertName': 'Concert Name',
    'artistDetails': 'Artist Details',
  };

  ConcertDialogHelpers(this._firebaseService);

  Future<void> _showBaseDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required Future<void> Function() onConfirm,
  }) async {
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardColor,
          title:
              Text(title, style: const TextStyle(color: AppColors.textWhite)),
          content: SingleChildScrollView(child: content),
          actions: [
            DialogActionButtons(
              onCancel: () => Navigator.pop(context),
              onConfirm: () async {
                setState(() => isLoading = true); // Simplified this line
                try {
                  await onConfirm();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => isLoading = false); // Just reset loading state
                }
              },
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showImageEditDialog(
      BuildContext context, String concertId) async {
    File? selectedImage;

    await _showBaseDialog(
      context: context,
      title: 'Change Concert Image',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedImage != null)
              Image.file(selectedImage!, height: 200, fit: BoxFit.cover)
            else
              Container(
                height: 200,
                color: AppColors.primaryDark,
                child: const Icon(
                  Icons.add_photo_alternate,
                  color: AppColors.textWhite,
                  size: 50,
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
              ),
              onPressed: () async {
                final image = await ImagePickerUtil.pickAndCropImage(context);
                if (image != null) setState(() => selectedImage = image);
              },
              child: const Text(
                'Select Image',
                style: TextStyle(color: AppColors.textWhite),
              ),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        if (selectedImage == null) throw Exception('Please select an image');
        final fileName =
            'concert_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(selectedImage!);
        final imageUrl = await ref.getDownloadURL();
        await _firebaseService.updateConcertDetails(concertId,
            imageUrl: imageUrl);
      },
    );
  }

  Future<void> showDetailsEditDialog(
    BuildContext context,
    String concertId,
    Concert concert,
  ) async {
    final controllers = {
      'artistName': TextEditingController(text: concert.artistName),
      'concertName': TextEditingController(text: concert.concertName),
      'artistDetails': TextEditingController(text: concert.artistDetails),
    };

    final descriptionControllers = ValueNotifier<List<TextEditingController>>(
        concert.description.isEmpty
            ? [TextEditingController()]
            : concert.description
                .map((desc) => TextEditingController(text: desc))
                .toList());

    await _showBaseDialog(
      context: context,
      title: 'Edit Concert Details',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...controllers.entries.map((e) => DialogTextField(
                  controller: e.value,
                  label: labelMap[e.key] ?? e.key.capitalize(),
                  maxLines: e.key == 'artistDetails' ? 3 : 1,
                )),
            const SizedBox(height: 16),
            const Text(
              'Description Paragraphs',
              style: TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
            ValueListenableBuilder<List<TextEditingController>>(
              valueListenable: descriptionControllers,
              builder: (context, controllers, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...controllers.map((controller) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: DialogTextField(
                          controller: controller,
                          label: 'Description Paragraph',
                          maxLines: 3,
                        ),
                      )),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final currentList = List<TextEditingController>.from(
                    descriptionControllers.value);
                currentList.add(TextEditingController());
                descriptionControllers.value = currentList;
              },
              icon: const Icon(Icons.add, color: AppColors.textWhite),
              label: const Text('Add Paragraph',
                  style: TextStyle(color: AppColors.textWhite)),
            ),
          ],
        ),
      ),
      onConfirm: () async {
        // Get all non-empty description texts
        final descriptions = descriptionControllers.value
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        await _firebaseService.updateConcertDetails(
          concertId,
          artistName: controllers['artistName']!.text.trim(),
          concertName: controllers['concertName']!.text.trim(),
          artistDetails: controllers['artistDetails']!.text.trim(),
          description: descriptions,
        );
      },
    );
  }

  Future<void> showDatesEditDialog(
    BuildContext context,
    String concertId,
    Concert concert,
  ) async {
    final selectedDates = [
      ...concert.dates.map((dateStr) {
        try {
          return DateTime.parse(dateStr);
        } catch (_) {
          return DateTime.now();
        }
      })
    ];

    Future<DateTime?> pickDate(DateTime initialDate) async {
      return showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
    }

    Widget buildDateTile(DateTime date, Function(void Function()) setState) {
      return ListTile(
        title: Text(
          dateFormat.format(date),
          style: const TextStyle(color: AppColors.textWhite),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon:
                  const Icon(Icons.calendar_today, color: AppColors.textWhite),
              onPressed: () async {
                final newDate = await pickDate(date);
                if (newDate != null) {
                  setState(() =>
                      selectedDates[selectedDates.indexOf(date)] = newDate);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => setState(() => selectedDates.remove(date)),
            ),
          ],
        ),
      );
    }

    await _showBaseDialog(
      context: context,
      title: 'Concert Dates',
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...selectedDates.map((date) => buildDateTile(date, setState)),
            TextButton.icon(
              onPressed: () async {
                final date = await pickDate(DateTime.now());
                if (date != null) setState(() => selectedDates.add(date));
              },
              icon: const Icon(Icons.add, color: AppColors.textWhite),
              label: const Text('Add Date',
                  style: TextStyle(color: AppColors.textWhite)),
            ),
          ],
        ),
      ),
      onConfirm: () => _firebaseService.updateConcertDetails(
        concertId,
        dates:
            selectedDates.map((date) => date.toString().split(' ')[0]).toList(),
      ),
    );
  }

  Future<void> showLocationEditDialog(
    BuildContext context,
    String concertId,
    Concert concert,
  ) async {
    final locationController = TextEditingController(text: concert.location);

    await _showBaseDialog(
      context: context,
      title: 'Edit Concert Location',
      content: DialogTextField(
        controller: locationController,
        label: 'Location',
        hint: 'Enter the concert venue and address',
        maxLines: 2,
      ),
      onConfirm: () {
        final location = locationController.text.trim();
        if (location.isEmpty) throw Exception('Location cannot be empty');
        return _firebaseService.updateConcertDetails(
          concertId,
          location: locationController.text.trim(),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}
