import 'package:capstone/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:capstone/core/services/firebase_service.dart';
import 'package:capstone/core/components/image_picker_utils.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddConcertScreen extends StatefulWidget {
  const AddConcertScreen({super.key});

  @override
  AddConcertScreenState createState() => AddConcertScreenState();
}

class AddConcertScreenState extends State<AddConcertScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  
  File? _selectedImage;
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _concertNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _artistDetailsController = TextEditingController();
  
  DateTime? _selectedDate;
  final List<String> _dates = [];
  final List<String> _description = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
  final File? image = await ImagePickerUtil.pickAndCropImage(context);
  if (image != null) {
    setState(() {
      _selectedImage = image;
    });
  }
}

  Future<String> _uploadImage() async {
    if (_selectedImage == null) throw Exception('No image selected');
    
    final ref = FirebaseStorage.instance
        .ref()
        .child('concert_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  void _addDate() {
    if (_selectedDate != null) {
      setState(() {
        _dates.add(_selectedDate!.toString().split(' ')[0]);
        _selectedDate = null;
      });
    }
  }

  void _addDescription() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF2F1552),
          title: Text('Add Description Paragraph', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter paragraph',
              hintStyle: TextStyle(color: Colors.white60),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _description.add(controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      setState(() => _error = 'Please select an image');
      return;
    }
    if (_dates.isEmpty) {
      setState(() => _error = 'Please add at least one date');
      return;
    }
    if (_description.isEmpty) {
      setState(() => _error = 'Please add at least one description paragraph');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final imageUrl = await _uploadImage();
      
      await _firebaseService.createConcert(
        imageUrl: imageUrl,
        artistName: _artistNameController.text,
        concertName: _concertNameController.text,
        description: _description,
        dates: _dates,
        location: _locationController.text,
        artistDetails: _artistDetailsController.text,
      );
      if (mounted) {
      Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF180B2D),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: const Text(
                    'Add New Concert',
                    style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
              ),
                SizedBox(height: 16),
                const Text(
                    'Choose Concert Banner:',
                    style: TextStyle(
                        color: AppColors.textWhite
                        ),
                  ),
                  SizedBox(height: 8),
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Color(0xFF2F1552),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Center(
                          child: Icon(Icons.add_photo_alternate,
                              color: Colors.white, size: 50)),
                ),
              ),
              SizedBox(height: 16),

              // Text fields
              _buildTextField(_artistNameController, 'Artist Name'),
              _buildTextField(_concertNameController, 'Concert Name'),
              _buildTextField(_locationController, 'Location'),
              _buildTextField(_artistDetailsController, 'Artist Details',
                  maxLines: 3),

              // Dates section
              SizedBox(height: 16),
              Text('Concert Dates', style: TextStyle(color: Colors.white)),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate?.toString().split(' ')[0] ??
                        'No date selected', style: TextStyle(color: AppColors.textWhite54),),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: Text('Pick Date'),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addDate,
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _dates
                    .map((date) => Chip(
                          label: Text(date),
                          onDeleted: () {
                            setState(() => _dates.remove(date));
                          },
                        ))
                    .toList(),
              ),

              // Description section
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Description Paragraphs',
                      style: TextStyle(color: Colors.white)),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addDescription,
                  ),
                ],
              ),
              ..._description.map((para) => Card(
                    child: ListTile(
                      title: Text(para),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          setState(() => _description.remove(para));
                        },
                      ),
                    ),
                  )),

              if (_error != null)
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center),
                ),

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color(0xFF6A00F4),
                ),
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Create Concert', style: TextStyle(color: AppColors.textWhite)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          fillColor: Color(0xFF2F1552),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}