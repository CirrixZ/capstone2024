import 'package:flutter/material.dart';
import 'package:capstone/core/components/image_picker_utils.dart';
import 'dart:io';

class CustomDialogField {
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextEditingController controller;

  CustomDialogField({
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    required this.controller,
  });
}

class CustomDialog extends StatefulWidget {
  final String title;
  final List<CustomDialogField> fields;
  final bool requiresImage;
  final Future<void> Function(Map<String, String> values, File? image) onSubmit;
  final String submitButtonText;
  final String? imageHint;
  final Widget? customWidget;

  const CustomDialog({
    super.key,
    required this.title,
    required this.fields,
    this.requiresImage = false,
    required this.onSubmit,
    this.submitButtonText = 'Create',
    this.imageHint,
    this.customWidget,
  });

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2F1552),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.requiresImage) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF180B2D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6A00F4),
                          width: 2,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.white,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.imageHint ?? 'Add Image',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
                ...widget.fields.map((field) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        controller: field.controller,
                        keyboardType: field.keyboardType,
                        style: const TextStyle(color: Colors.white),
                        validator: field.validator,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hint,
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintStyle: const TextStyle(color: Colors.white60),
                          fillColor: const Color(0xFF180B2D),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF6A00F4)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF9C47FF)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    )),
                if (widget.customWidget != null) ...[
                  const SizedBox(height: 16),
                  widget.customWidget!,
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A00F4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.submitButtonText,
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final File? image = await ImagePickerUtil.pickAndCropImage(context);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.requiresImage && _selectedImage == null) {
      setState(() => _error = 'Please select an image');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final values = {
        for (var field in widget.fields)
          field.label: field.controller.text,
      };

      await widget.onSubmit(values, _selectedImage);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
}