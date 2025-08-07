import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  BuildContext? _context;
  final String backendUrl =
      'https://gohive-notification-service-f9323a5e641a.herokuapp.com';

  void initialize(BuildContext context) {
    _context = context;
    _listenForMessages();
    _handleNotificationClicks();
  }

  Future<String?> setupNotifications() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  Future<void> updateToken(String userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/update-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'token': token}),
      );
      if (response.statusCode != 200) {
        print('Failed to update token: ${response.body}');
      }
    } catch (e) {
      print('Error updating token: $e');
    }
  }

  void _listenForMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'Foreground message: ${message.notification?.title}, data: ${message.data}');
      if (message.notification != null && _context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNotificationDialog(
            message.data['type'],
            message.notification!.title!,
            message.notification!.body!,
            message.data['postId'],
            message.data['chatId'],
            message.data['serviceId'],
          );
        });
      }
    });
  }

  void _handleNotificationClicks() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null && _context != null) {
        print(
            'App opened from terminated: ${message.notification?.title}, data: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNotificationDialog(
            message.data['type'],
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? 'Check it out!',
            message.data['postId'],
            message.data['chatId'],
            message.data['serviceId'],
          );
        });
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (_context != null) {
        print(
            'App opened from background: ${message.notification?.title}, data: ${message.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNotificationDialog(
            message.data['type'],
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? 'Check it out!',
            message.data['postId'],
            message.data['chatId'],
            message.data['serviceId'],
          );
        });
      }
    });
  }

  void _showNotificationDialog(
    String type,
    String title,
    String body,
    String? postId,
    String? chatId,
    String? serviceId,
  ) {
    if (_context == null) return;
    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
