// lib/widgets/post_detail/comment_input_widget.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'image_picker_widget.dart';

class CommentInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isAuthor;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback? onPickImage;
  final File? selectedImage;
  final VoidCallback? onRemoveImage;

  const CommentInputWidget({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.isAuthor,
    required this.hintText,
    required this.onSend,
    this.onPickImage,
    this.selectedImage,
    this.onRemoveImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFAFCBEA), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    suffixIcon: isAuthor && onPickImage != null
                        ? IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            onPressed: onPickImage,
                            tooltip: 'Add image',
                          )
                        : null,
                  ),
                  maxLines: null,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(width: 12),
              isLoading
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFAFCBEA),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFAFCBEA),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: onSend,
                        tooltip: 'Send comment',
                      ),
                    ),
            ],
          ),
          
          // Selected image preview
          if (selectedImage != null && onRemoveImage != null) ...[
            ImagePickerWidget(
              selectedImage: selectedImage,
              onRemove: onRemoveImage!,
            ),
          ],
        ],
      ),
    );
  }
}