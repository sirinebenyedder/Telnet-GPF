import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';
import 'package:Telnet/screens/profile/notification_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Telnet/services/token_service.dart';

class NotificationListScreen extends StatefulWidget {
  final String titleText;
  const NotificationListScreen({super.key, required this.titleText});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? userId;
  final AuthService _authService = AuthService();
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchNotifications();
  }

  Future<void> _loadUserData() async {
    try {
      final tokenData = await _authService.LoadToken();
      print('Token Data: $tokenData'); // Debug complet

      if (tokenData['decodedToken'] != null) {
        final decodedToken = tokenData['decodedToken'];
        print('Decoded Token Content: $decodedToken'); // Debug spécifique

        // Correction ici: utiliser 'userId' au lieu de 'id'
        final extractedUserId = decodedToken['userId']?.toString();
        userRole = decodedToken['role']?.toString(); // Nouveau
        print('Extracted UserId: $extractedUserId'); // Debug

        setState(() {
          userId = extractedUserId;
          userRole = userRole;
        });

        print('After setState - _userId: $userId'); // Vérification
      } else {
        print('DecodedToken is null');
      }
    } catch (error) {
      print('Error loading user data: $error');
      if (error is NoSuchMethodError) {
        print('Possible key mismatch in token structure');
      }
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("token de la fonction getnotification $token");
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notifications = data['notifications'];
          _isLoading = false;
          print(data['notifications']);
        });
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
    }
  }

  Future<void> _handleResponse(String notificationId, bool accepted) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.patch(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/RequestResponse/$notificationId/respond',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'notificationId': notificationId,
          'response': accepted,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n['_id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['status'] =
                accepted ? 'accepted' : 'rejected';
            _notifications[index]['isRead'] = true;
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Réponse envoyée avec succès')));
      } else {
        throw Exception('Failed to send response: ${response.body}');
      }
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];

      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Vérifiez que l'URL est correcte
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/notifications/$notificationId/markAsRead',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n['_id'] == notificationId,
          );
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
      }
    } catch (error) {
      print('Error marking as read: $error');
    }
  }

  void _refreshNotifications() {
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.builder(
                padding: const EdgeInsets.all(defaultPadding),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  // Gérer en toute sécurité les valeurs potentiellement nulles
                  String? senderId;
                  String? recipientId;

                  // Vérifier si 'sender' et 'recipient' sont des objets ou des chaînes
                  if (notification['sender'] is Map) {
                    senderId = notification['sender']['_id']?.toString().trim();
                    print('theid of the sender $senderId');
                  } else {
                    senderId = notification['sender']?.toString();
                  }

                  if (notification['recipient'] is Map) {
                    recipientId =
                        notification['recipient']['_id']?.toString().trim();
                    print('the id of the receipt $recipientId');
                  } else {
                    recipientId = notification['recipient']?.toString();
                  }

                  final isSender = userId == senderId;
                  final isRecipient = userId == recipientId;
                  print(
                    'userid $userId senderid $senderId receiptid $recipientId',
                  );
                  print(isSender);
                  print('booleen recipient$isRecipient');
                  if (notification['isRead'] == false && isRecipient) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markAsRead(notification['_id']);
                    });
                  }

                  // Retourner explicitement le NotificationCard
                  return NotificationCard(
                    key: ValueKey(
                      notification['_id'],
                    ), // Ajout d'une clé unique
                    notification: notification,
                    showActions: isRecipient,
                    onRespond: (accepted) async {
                      try {
                        await _handleResponse(notification['_id'], accepted);
                        // Rafraîchir les données après réponse
                        _fetchNotifications();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: ${e.toString()}')),
                        );
                      }
                    },
                    isCurrentUserSender: isSender,
                    isCurrentUserRecipient: userId == recipientId,
                  );
                },
              ),
    );
  }
}
