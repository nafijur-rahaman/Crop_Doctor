import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/result_screen.dart';

class ImagePickerWidget extends StatefulWidget {
  const ImagePickerWidget({super.key});

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _image;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      
      setState(() {
        _image = File(pickedFile.path);
      });

      // Navigate to result screen (placeholder for now)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageBytes: bytes),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.image),
          label: const Text('Pick Crop Image'),
          onPressed: pickImage,
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Image.file(_image!, height: 200),
          ),
      ],
    );
  }
}
