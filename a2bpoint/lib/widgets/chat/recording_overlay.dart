// lib/widgets/chat/recording_overlay.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' show sin;

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
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;
  
  @override
  void initState() {
    super.initState();
    
    // Анимация пульсации для кнопки записи
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Анимация волн для индикации записи
    _waveController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
    
    // Запуск анимаций
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    
    // Таймер для отсчета времени записи
    _startTimer();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _timer?.cancel();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration = Duration(seconds: timer.tick);
      });
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Индикатор записи с анимацией
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Icons.fiber_manual_record,
                        color: Colors.white,
                        size: 16,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                Text(
                  'ЗАПИСЬ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Время записи
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          
          SizedBox(height: 30),
          
          // Визуализация звуковых волн
          Container(
            height: 60,
            width: 200,
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(_waveAnimation.value),
                  size: Size(200, 60),
                );
              },
            ),
          ),
          
          SizedBox(height: 40),
          
          // Кнопки управления
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Кнопка отмены
              GestureDetector(
                onTap: widget.onCancel,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              
              // Кнопка отправки
              GestureDetector(
                onTap: widget.onSend,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Подсказка
          Text(
            'Нажмите и удерживайте для записи голосового сообщения',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  
  WavePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;
    
    final center = size.height / 2;
    final barWidth = 3.0;
    final barSpacing = 5.0;
    final numBars = (size.width / (barWidth + barSpacing)).floor();
    
    for (int i = 0; i < numBars; i++) {
      final x = i * (barWidth + barSpacing);
      
      // Создаем эффект волны с разной высотой столбиков
      final normalizedIndex = i / numBars;
      final waveOffset = (animationValue + normalizedIndex) % 1.0;
      final barHeight = (0.2 + 0.8 * (0.5 + 0.5 * sin(waveOffset * 2 * 3.14159))) * size.height * 0.8;
      
      final rect = Rect.fromLTWH(
        x,
        center - barHeight / 2,
        barWidth,
        barHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
