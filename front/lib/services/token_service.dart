import 'dart:convert';

import 'package:Telnet/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  String? authToken;
  Map<String, dynamic>? decodedToken;

  // Charger le token depuis SharedPreferences
  Future<Map<String, dynamic>> LoadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      if (!JwtDecoder.isExpired(token)) {
        authToken = token;
        decodedToken = JwtDecoder.decode(token);
        return {
          'authToken': authToken, // Retourner authToken
          'decodedToken': decodedToken, // Retourner decodedToken
        };
      } else {
        authToken = null;
        decodedToken = null;
        print("Token expiré. Supprimez-le ou reconnectez-vous.");
        return {'authToken': null, 'decodedToken': null};
      }
    } else {
      authToken = null;
      decodedToken = null;
      print("Aucun token trouvé.");
      return {'authToken': null, 'decodedToken': null};
    }
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token'); // Clé correcte

    if (token != null && token.isNotEmpty) {
      if (!JwtDecoder.isExpired(token)) {
        authToken = token;
        decodedToken = JwtDecoder.decode(token);
      } else {
        authToken = null;
        decodedToken = null;
        print("Token expiré. Supprimez-le ou reconnectez-vous.");
      }
    } else {
      authToken = null;
      decodedToken = null;
      print("Aucun token trouvé.");
    }
  }

  // Sauvegarder le token dans SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    authToken = token;
    decodedToken = JwtDecoder.decode(token);
    print("le token de la fonction save de token service$authToken");
    print("decodedtoken$decodedToken");
  }

  // Supprimer le token de SharedPreferences
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    authToken = null;
    decodedToken = null;
  }

  ////////////
  Future<bool> checkPasswordResetStatus() async {
    // 2. Vérification serveur pour confirmation (optionnel mais recommandé)
    Map<String, dynamic> tokenData = await authService.LoadToken();
    String? token = tokenData['authToken'];
    print(token);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/check-reset-status'),
        // Dans votre Node.js (backend)'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('fonction de forcage reset');
      return jsonDecode(response.body)['requiresReset'] ?? false;
    } catch (e) {
      return true;
    }
  }
}

//instance unique
final authService = AuthService();
