// lib/widgets/post_detail/image_picker_widget.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ImagePickerWidget extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onRemove;

  const ImagePickerWidget({
    Key? key,
    this.selectedImage,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedImage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Stack(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}