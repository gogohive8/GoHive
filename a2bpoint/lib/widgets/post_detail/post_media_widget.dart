// lib/widgets/post_detail/post_media_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostMediaWidget extends StatelessWidget {
  final List<String>? imageUrls;

  const PostMediaWidget({
    Key? key,
    this.imageUrls,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrls == null || imageUrls!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (imageUrls!.length == 1) {
      return _buildSingleImage(imageUrls![0]);
    } else {
      return _buildImageGrid();
    }
  }

  Widget _buildSingleImage(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFAFCBEA),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            return Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 50, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Failed to load image'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 300,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 8,
        ),
        itemCount: imageUrls!.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrls![index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFAFCBEA),
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: const Icon(Icons.error, color: Colors.red),
              ),
            ),
          );
        },
      ),
    );
  }
}