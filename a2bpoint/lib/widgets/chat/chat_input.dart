// lib/widgets/chat/chat_input.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final VoidCallback onSendMedia;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final bool isRecording;
  final bool isTyping;
  final VoidCallback onSendLocation;
  final VoidCallback onSendFile;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSendText,
    required this.onSendMedia,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.isRecording,
    required this.isTyping,
    required this.onSendLocation,
    required this.onSendFile,
  }) : super(key: key);

  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  bool _showEmojiKeyboard = false;
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;

  @override
  void initState() {
    super.initState();
    _recordingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _recordingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _recordingAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _recordingAnimationController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _recordingAnimationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Media/Attachment button
            IconButton(
              icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
              onPressed: _showAttachmentOptions,
            ),
            
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    // Emoji button
                    IconButton(
                      icon: Icon(
                        _showEmojiKeyboard ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: _toggleEmojiKeyboard,
                    ),
                    
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: 'Сообщение...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          setState(() {}); // Rebuild to show/hide send button
                        },
                      ),
                    ),
                    
                    // Camera button
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.grey[600]),
                      onPressed: widget.onSendMedia,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(width: 4),
            
            // Send/Voice button
            GestureDetector(
              onTap: widget.isTyping ? widget.onSendText : null,
              onLongPressStart: widget.isTyping ? null : (_) => widget.onStartRecording(),
              onLongPressEnd: widget.isTyping ? null : (_) => widget.onStopRecording(),
              child: AnimatedBuilder(
                animation: _recordingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isRecording ? _recordingAnimation.value : 1.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.isRecording 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isTyping 
                          ? Icons.send 
                          : (widget.isRecording ? Icons.stop : Icons.mic),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleEmojiKeyboard() {
    setState(() {
      _showEmojiKeyboard = !_showEmojiKeyboard;
    });
    // Здесь можно добавить логику показа/скрытия эмодзи клавиатуры
  }

  void _showAttachmentOptions() {
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
            Text(
              'Выберите действие',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Галерея',
                  Colors.purple,
                  widget.onSendMedia,
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'Файл',
                  Colors.blue,
                  widget.onSendFile,
                ),
                _buildAttachmentOption(
                  Icons.location_on,
                  'Локация',
                  Colors.green,
                  widget.onSendLocation,
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Recording Overlay Widget
class RecordingOverlay extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const RecordingOverlay({
    Key? key,
    required this.onCancel,
    required this.onSend,
  }) : super(key: key);

  @override
  _RecordingOverlayState createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Duration _recordingDuration = Duration.zero;
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_startTime);
        });
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(40),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Запись голосового сообщения',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              Text(
                _formatDuration(_recordingDuration),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: widget.onCancel,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.close),
                    heroTag: "cancel",
                  ),
                  FloatingActionButton(
                    onPressed: widget.onSend,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.send),
                    heroTag: "send",
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Отмена'),
                  Text('Отправить'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}