// lib/widgets/chat/media_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerBottomSheet extends StatelessWidget {
  final Function(ImageSource) onImagePicked;
  final Function(ImageSource) onVideoPicked;
  final Function(String) onGifPicked;
  final Function(String) onStickerPicked;
  final VoidCallback onContactPicked;

  const MediaPickerBottomSheet({
    Key? key,
    required this.onImagePicked,
    required this.onVideoPicked,
    required this.onGifPicked,
    required this.onStickerPicked,
    required this.onContactPicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          
          Text(
            'Выберите тип контента',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 24),
          
          // First row - Camera and Gallery
          Row(
            children: [
              Expanded(
                child: _buildMediaOption(
                  context,
                  Icons.camera_alt,
                  'Камера',
                  Colors.blue,
                  () => _showImageVideoOptions(context, ImageSource.camera),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMediaOption(
                  context,
                  Icons.photo_library,
                  'Галерея',
                  Colors.purple,
                  () => _showImageVideoOptions(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Second row - GIF and Stickers
          Row(
            children: [
              Expanded(
                child: _buildMediaOption(
                  context,
                  Icons.gif_box,
                  'GIF',
                  Colors.orange,
                  () => _showGifPicker(context),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMediaOption(
                  context,
                  Icons.emoji_emotions,
                  'Стикеры',
                  Colors.green,
                  () => _showStickerPicker(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Third row - Contact
          Row(
            children: [
              Expanded(
                child: _buildMediaOption(
                  context,
                  Icons.contacts,
                  'Контакт',
                  Colors.indigo,
                  () {
                    Navigator.pop(context);
                    onContactPicked();
                  },
                ),
              ),
              Expanded(child: SizedBox()), // Empty space to balance the row
            ],
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMediaOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageVideoOptions(BuildContext context, ImageSource source) {
    Navigator.pop(context); // Close first bottom sheet
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              source == ImageSource.camera ? 'Камера' : 'Галерея',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildSubOption(
                    context,
                    Icons.photo,
                    'Фото',
                    Colors.blue,
                    () {
                      Navigator.pop(context);
                      onImagePicked(source);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildSubOption(
                    context,
                    Icons.videocam,
                    'Видео',
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      onVideoPicked(source);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubOption(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGifPicker(BuildContext context) {
    Navigator.pop(context); // Close first bottom sheet
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => GifPickerWidget(
          scrollController: scrollController,
          onGifSelected: (gifUrl) {
            Navigator.pop(context);
            onGifPicked(gifUrl);
          },
        ),
      ),
    );
  }

  void _showStickerPicker(BuildContext context) {
    Navigator.pop(context); // Close first bottom sheet
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => StickerPickerWidget(
          scrollController: scrollController,
          onStickerSelected: (stickerUrl) {
            Navigator.pop(context);
            onStickerPicked(stickerUrl);
          },
        ),
      ),
    );
  }
}

// GIF Picker Widget
class GifPickerWidget extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String) onGifSelected;

  const GifPickerWidget({
    Key? key,
    required this.scrollController,
    required this.onGifSelected,
  }) : super(key: key);

  @override
  _GifPickerWidgetState createState() => _GifPickerWidgetState();
}

class _GifPickerWidgetState extends State<GifPickerWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _gifs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrendingGifs();
  }

  void _loadTrendingGifs() {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate loading trending GIFs
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _gifs = [
            'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
            'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
            'https://media.giphy.com/media/3oz8xLd9DJq2l2VFtu/giphy.gif',
            'https://media.giphy.com/media/xT9IgzoKnwFNmISR8I/giphy.gif',
            'https://media.giphy.com/media/26u4cr7LipNdcxzTi/giphy.gif',
            'https://media.giphy.com/media/l0HlvtIPzPdt2usKs/giphy.gif',
            // Добавить больше GIF URL-ов
          ];
          _isLoading = false;
        });
      }
    });
  }

  void _searchGifs(String query) {
    if (query.isEmpty) {
      _loadTrendingGifs();
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate searching GIFs
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          // В реальном приложении здесь был бы API вызов к Giphy
          _gifs = [
            'https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif',
            'https://media.giphy.com/media/26u4cqiYI30juCOGY/giphy.gif',
          ];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Выберите GIF',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          
          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск GIF...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: _searchGifs,
            ),
          ),
          SizedBox(height: 16),
          
          // GIF grid
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : GridView.builder(
                  controller: widget.scrollController,
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _gifs.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => widget.onGifSelected(_gifs[index]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _gifs[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

// Sticker Picker Widget
class StickerPickerWidget extends StatelessWidget {
  final ScrollController scrollController;
  final Function(String) onStickerSelected;

  const StickerPickerWidget({
    Key? key,
    required this.scrollController,
    required this.onStickerSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample sticker URLs
    final stickers = [
      'https://via.placeholder.com/100x100/FF6B6B/FFFFFF?text=😀',
      'https://via.placeholder.com/100x100/4ECDC4/FFFFFF?text=😊',
      'https://via.placeholder.com/100x100/45B7D1/FFFFFF?text=😂',
      'https://via.placeholder.com/100x100/FFA07A/FFFFFF?text=❤️',
      'https://via.placeholder.com/100x100/98D8C8/FFFFFF?text=👍',
      'https://via.placeholder.com/100x100/F7DC6F/FFFFFF?text=🔥',
      'https://via.placeholder.com/100x100/BB8FCE/FFFFFF?text=🎉',
      'https://via.placeholder.com/100x100/85C1E9/FFFFFF?text=😎',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Text(
            'Выберите стикер',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          
          // Sticker grid
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stickers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onStickerSelected(stickers[index]),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        stickers[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}