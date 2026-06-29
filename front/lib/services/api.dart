import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:Telnet/services/token_service.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    final host = dotenv.env['API_HOST'] ?? 'localhost';
    final port = dotenv.env['API_PORT'] ?? '8000';
    print('http://$host:$port');
    return 'http://$host:$port';
  }
}

class Api {
  static final baseUrl = "${ApiConfig.baseUrl}/api/";

  static Future<Map<String, String>> _getAuthHeaders() async {
    try {
      Map<String, dynamic> tokenData = await authService.LoadToken();
      String? token = tokenData['authToken'];

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found');
      }

      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('Error getting auth headers: $e');
      throw Exception('Failed to get authentication headers');
    }
  }

  static Future<Map<String, dynamic>> auth(
    Map<String, dynamic> loginData,
  ) async {
    var url = Uri.parse("${ApiConfig.baseUrl}/api/auth/signin");

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginData),
      );

      final responseBody = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final token = jsonDecode(res.body)['token'];
        print('Token received from backend: $token');
        await authService.saveToken(token); // Sauvegarde le token
        print('Token saved using authService:');
        // Rafraîchit l'interface utilisateur

        return {"success": true, "message": "Connexion réussie"};
      } else {
        return {
          "success": false,
          "message": responseBody["message"] ?? "Erreur inconnue",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de contacter le serveur",
      };
    }
  }

  static Future<Map<String, dynamic>> fetchUserData(String userId) async {
    Map<String, dynamic> tokenData = await authService.LoadToken();
    String? token = tokenData['authToken']; // Extraire authToken du Map
    print("$token");
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/profile?_id=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        print('Fetched user data: $data'); // Debug print
        return data; // Return the user data
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  static Future<String> uploadImage(File image) async {
    try {
      var url = Uri.parse('${ApiConfig.baseUrl}/api/user/upload');
      var request = http.MultipartRequest('POST', url);

      print('Uploading image to: $url');

      // Add the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Field name for the image
          image.path,
        ),
      );

      print('Image added to the request: ${image.path}');

      final response = await request.send();

      print(
        'Response status code: ${response.statusCode}',
      ); // Print status code of the response

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('Response data: $responseData'); // Print the response data

        return json.decode(responseData)['imageUrl']; // Return the image URL
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error during image upload: $e'); // Print the error details
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> updatedFields,
    File? image,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/user/update?_id=$userId");
    final request = http.MultipartRequest('POST', url);
    updatedFields.forEach((key, value) {
      request.fields[key] = value.toString();
    });
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final responseJson = json.decode(responseData);

      return {
        "success": response.statusCode == 200,
        "message":
            responseJson["message"] ??
            (response.statusCode == 200 ? "Profile updated" : "Update failed"),
        "data": responseJson["data"],
      };
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> signout() async {
    //
    if (authService.authToken == null) {
      throw Exception('No token found');
    }
    final token = authService.authToken; //

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/signout"),
      headers: await _getAuthHeaders(), //
    );
    print("reponse du logout :$response");
    if (response.statusCode == 200) {
      //
      await authService.clearToken();

      return json.decode(response.body);
    } else {
      throw Exception('Failed to sign out');
    }
  }

  static Future<Map<String, dynamic>> uploadImageInvioce(
    File image, {
    String? oldTempImageId,
  }) async {
    try {
      var url = Uri.parse('${ApiConfig.baseUrl}/api/invoices/process-invoice');
      var request = http.MultipartRequest('POST', url);

      print('Uploading image to: $url');

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      print(
        'Image added to the request: ${image.path}',
      ); // Afficher le chemin de l'image

      final response = await request.send();

      print(
        'Response status code: ${response.statusCode}',
      ); // Afficher le code de statut

      if (response.statusCode == 200) {
        // Lire la réponse du serveur
        final responseData = await response.stream.bytesToString();
        print('Response data: $responseData');
        final Map<String, dynamic> extractedData = json.decode(responseData);
        print(extractedData);
        return extractedData;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during image upload: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<Map<String, dynamic>> saveInvoice(
    Map<String, dynamic> invoiceData,
    String userId,
  ) async {
    try {
      // Préparer les données pour l'API
      final Map<String, dynamic> requestBody = {
        'number': invoiceData['invoice_no'] ?? '',
        'date': invoiceData['date'] ?? '',
        'address_country': invoiceData['address'] ?? '',
        'currency': invoiceData['currency'] ?? '',
        'total': invoiceData['total'] ?? 0.0,
        'supplier': invoiceData['company'] ?? '',
        'items': invoiceData['items'] ?? '',
        'projectId': invoiceData['projectId'] ?? '',
        //'tva': invoiceData['tva'] ?? '',
        //'enfant': invoiceData['enfant'] ?? '',
        'imageId': invoiceData['tempImageId'],
        'userId': userId, // Utiliser l'ID de l'image temporaire
      };

      print('Sending invoice data to server: $requestBody');

      // Envoyer la requête
      final url = Uri.parse('${ApiConfig.baseUrl}/api/invoices/save-invoice');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Save invoice response status: ${response.statusCode}');
      print('Save invoice response body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseBody;
      } else {
        // Extraire seulement le message
        throw Exception(responseBody['message'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      print('Exception during save invoice: $e');
      throw Exception(
        e is Map
            ? e['message'] ?? 'Erreur lors de l\'enregistrement'
            : e.toString(),
      );
    }
  }

  // Supprimer une image temporaire
  static Future<void> deleteTempImage(String tempImageId) async {
    print('flutter fais tourner delete function');
    print("$tempImageId");
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/invoices/delete-temp-image',
      );
      print('Sending request to: $url');
      print('Request body: ${jsonEncode({'tempImageId': tempImageId})}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tempImageId': tempImageId}),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Rest of your code...
    } catch (e) {
      print('Exception during HTTP request: $e');
      throw Exception('Failed to delete temp image: $e');
    }
  }

  // envoyer le code de réinitialisation du mot de passe
  static Future<Map<String, dynamic>> sendForgotPasswordCode(
    String email,
  ) async {
    var url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/send-forgot-password-code",
    );

    try {
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final responseBody = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message": responseBody["message"] ?? "Code envoyé avec succès !",
        };
      } else {
        return {
          "success": false,
          "message": responseBody["message"] ?? "Échec de l'envoi du code.",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de se connecter au serveur.",
      };
    }
  }
  ///////////

  static Future<Map<String, dynamic>> verifyCode(
    String email,
    String code,
  ) async {
    var url = Uri.parse("${ApiConfig.baseUrl}/api/auth/verify-code");

    try {
      print(code);
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "code": code}),
      );

      final responseBody = jsonDecode(res.body);
      print(responseBody);
      if (res.statusCode == 200) {
        return {
          "success": true,
          "message":
              responseBody["message"] ??
              "Mot de passe mis à jour avec succès !",
        };
      } else {
        return {
          "success": false,
          "message":
              responseBody["message"] ??
              "Échec de la réinitialisation du mot de passe.",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de se connecter au serveur.",
      };
    }
  }

  ///////

  static Future<Map<String, dynamic>> verifyForgotPasswordCode(
    String email,
    String code,
    String newPassword,
  ) async {
    var url = Uri.parse(
      "${ApiConfig.baseUrl}/api/auth/verify-forgot-password-code",
    );

    try {
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "providedCode": code,
          "newPassword": newPassword,
        }),
      );

      final responseBody = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message":
              responseBody["message"] ??
              "Mot de passe mis à jour avec succès !",
        };
      } else {
        return {
          "success": false,
          "message":
              responseBody["message"] ??
              "Échec de la réinitialisation du mot de passe.",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de se connecter au serveur.",
      };
    }
  }

  static Future<Map<String, dynamic>> fetchFactures({
    //
    String? projectId,
    //
    DateTime? startDate,
    DateTime? endDate,
    String? supplier,
    double? minMontant,
    double? maxMontant,
    int page = 1,
    int limit = 8,
    required String userId,
    //required projectId,
  }) async {
    try {
      final tokenData = await authService.LoadToken();
      final token = tokenData['authToken'];

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final uri = Uri.parse("${ApiConfig.baseUrl}/api/invoices/fetch_invoices");
      print('ena id ta3 widget');
      print(projectId);
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (startDate != null)
          'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        if (endDate != null)
          'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        if (minMontant != null) 'minMontant': minMontant.toString(),
        if (maxMontant != null) 'maxMontant': maxMontant.toString(),
        if (supplier != null && supplier.isNotEmpty) 'supplier': supplier,
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
      };

      final url = uri.replace(queryParameters: params);
      print('Requête API: $url');
      print("userid$userId");
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Add null checks for critical fields
        if (data['data'] == null) {
          throw Exception('API returned null data');
        }

        return {
          'data': data['data'] ?? [],
          'pagination': {
            'page': (data['pagination']?['page'] as int?) ?? page,
            'limit': (data['pagination']?['limit'] as int?) ?? limit,
            'total': (data['pagination']?['total'] as int?) ?? 0,
            'totalPages': (data['pagination']?['totalPages'] as int?) ?? 1,
          },
          'currentProject': data['currentProject'] ?? {},
        };
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int limit = 8,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/api/user/users");

      final params = {'page': page.toString(), 'limit': limit.toString()};

      final url = uri.replace(queryParameters: params);
      print('Requête API: $url');

      final response = await http.get(url, headers: await _getAuthHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Add null checks for critical fields
        if (data['data'] == null) {
          throw Exception('API returned null data');
        }

        return {
          'data': data['data'] ?? [],
          'pagination': {
            'page': (data['pagination']?['page'] as int?) ?? page,
            'limit': (data['pagination']?['limit'] as int?) ?? limit,
            'total': (data['pagination']?['total'] as int?) ?? 0,
            'totalPages': (data['pagination']?['totalPages'] as int?) ?? 1,
          },
        };
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  /////////////////
  static Future<Map<String, dynamic>> createBudgetRequest({
    required String projectId,
    required double amount,
    required String currency,
    required String reason,
    required String token,
  }) async {
    var url = Uri.parse("${ApiConfig.baseUrl}/api/budgetRequest/request");

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "projectId": projectId,
          "amount": amount,
          "currency": currency,
          "reason": reason,
        }),
      );

      final responseBody = jsonDecode(res.body);

      if (res.statusCode == 201) {
        return {
          "success": true,
          "message": responseBody["message"] ?? "Demande envoyée avec succès",
          "data": responseBody["data"],
        };
      } else {
        return {
          "success": false,
          "message": responseBody["message"] ?? "Échec de la demande",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur de connexion au serveur"};
    }
  }

  ////
  static Future<Map<String, dynamic>> respondToBudgetRequest({
    required String requestId,
    required bool response,
    required String token,
  }) async {
    var url = Uri.parse("${ApiConfig.baseUrl}/api/$requestId/respond");

    try {
      final res = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"response": response}),
      );

      final responseBody = jsonDecode(res.body);

      if (res.statusCode == 200) {
        return {
          "success": true,
          "message": responseBody["message"] ?? "Réponse enregistrée",
          "data": responseBody["data"],
        };
      } else {
        return {
          "success": false,
          "message": responseBody["message"] ?? "Échec de la réponse",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur de connexion au serveur"};
    }
  }

  static Future<Map<String, dynamic>> addUser({
    required String name,
    required String email,
    required String phone,

    required String? userId,
    required String? adresse,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/user/add'),

        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'email': email,
          //'password': password,
          'name': name,
          'phone': phone,

          'adress': adresse,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur inconnue',
        };
      }
    } catch (e) {
      print("Exception dans API.addUser: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  // modifier un utilisateur
  static Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String adress,
    String? password,
    bool? activated,
  }) async {
    try {
      final requestBody = {
        'name': name,
        'email': email,
        'phone': phone,
        'adress': adress,
        'activated': activated,
        if (password != null) 'password': password,
      };

      print('Envoi des données: $requestBody');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/user/modifier/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Réponse du serveur: ${response.body}');

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              data['message'] ??
              'Erreur inconnue (code ${response.statusCode})',
        };
      }
    } catch (e) {
      print('Erreur lors de la requête: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchUsersByRole({
    required int page,
    required int limit,
    //required String userId,
    String? role,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/user/fetchusersbyrole?'
        'page=$page&limit=$limit${role != null ? '&role=$role' : ''}',
      );
      print(url);
      final response = await http.get(url, headers: await _getAuthHeaders());

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Erreur inconnue',
        };
      }
    } catch (e) {
      print("Exception dans API.fetchUsersByRole: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> fetchPmByRf({
    required String rfId,
    required int page,
    required int limit,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/user/fetchpm?'
        'rfId=$rfId&page=$page&limit=$limit',
      );

      final response = await http.get(url, headers: await _getAuthHeaders());
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error':
              data['message'] ??
              'Erreur inconnue (code ${response.statusCode})',
        };
      }
    } catch (e) {
      print('Erreur lors de la requête fetchPmByRf: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<bool> deleteFacture(String invoiceId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/invoices/$invoiceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Échec de la suppression: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  static Future<bool> deleteMultipleFactures(
    List<String> invoiceIds,
    String userId,
  ) async {
    try {
      print('functionapi');
      print(invoiceIds);
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/invoices'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ids': invoiceIds}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Échec de la suppression multiple: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression multiple: $e');
    }
  }
}
