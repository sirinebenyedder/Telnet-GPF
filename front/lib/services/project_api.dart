import 'dart:convert';
import 'package:Telnet/services/api.dart';
import 'package:http/http.dart' as http;
import 'package:Telnet/services/token_service.dart';

class ProjectApi {
  final AuthService _authService = AuthService();
  static const String baseUrl = 'http://192.168.1.157:8000/api';

  //lezim id ta3 RF bich ifetchi que ses PM ////////////////
  Future<List<Map<String, dynamic>>> getAllProjectsWithManager() async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("Token utilisé pour getProjects: $token");
      final decodedToken = tokenData['decodedToken'];
      final extractedUserId = decodedToken['userId']?.toString();
      //userId = extractedUserId;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/project'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load projects: ${response.body}');
      }
    } catch (error) {
      print('Error in getAllProjectsWithManager: $error');
      rethrow;
    }
  }

  //hethi li screen project feha pagination
  Future<Map<String, dynamic>> getProjectswithmanagerPagination({
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("Token utilisé pour getProjects: $token");
      final decodedToken = tokenData['decodedToken'];
      final extractedUserId = decodedToken['userId']?.toString();

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/project/projectPagination?page=$page&limit=$limit'
          '${searchQuery != null ? '&search=$searchQuery' : ''}',
        ),

        headers: {'Authorization': 'Bearer $token'},
      );

      print(
        "URL appelée: ${ApiConfig.baseUrl}/api/project/projetsfetch/pagination?page=$page&limit=$limit",
      );

      if (response.statusCode == 200) {
        return json.decode(
          response.body,
        ); // Retourne un Map avec projects et pagination
      } else if (response.statusCode == 404) {
        return {
          'projects': [],
          'pagination': {
            'totalItems': 0,
            'totalPages': 0,
            'currentPage': page,
            'itemsPerPage': limit,
            'hasNextPage': false,
            'hasPreviousPage': false,
          },
        };
      } else {
        throw Exception(
          'Failed to load projects with manager: ${response.body}',
        );
      }
    } catch (error) {
      print('Error in getProjectswithmanagerPagination: $error');
      rethrow;
    }
  }

  ////////////////////////////////////////////////////////////////////
  //facturedetaills

  static Future<Map<String, dynamic>> getFactureDetails(
    String factureId,
  ) async {
    try {
      final apiUrl = '${ApiConfig.baseUrl}/api/invoices/getinvioce/$factureId';
      final response = await http.get(Uri.parse(apiUrl));
      print('detail$apiUrl');
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData['data'];
      } else {
        throw Exception(
          responseData['message'] ??
              'Échec de la requête: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur dans getFactureDetails: $e');
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProjectsByManagerId(
    String managerId,
  ) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print('managerid fi project api $managerId');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/$managerId/pmproject'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return []; // Retourne une liste vide si aucun projet trouvé
      } else {
        throw Exception('Failed to load manager projects: ${response.body}');
      }
    } catch (error) {
      print('Error in getProjectsByManagerId: $error');
      rethrow;
    }
  }

  // Récupérer les projets d'un manager spécifique avec pagination
  Future<Map<String, dynamic>> getProjectsByManagerIdPagination(
    String userId, {
    String? managerId,
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print('managerid in project api $managerId');

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/project/projetcfetchpagination/$managerId/pmproject?page=$page&limit=$limit'
          '${searchQuery != null ? '&search=$searchQuery' : ''}',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
        'Request URI: ${ApiConfig.baseUrl}/api/project/projetcfetchpagination/$managerId/pmproject?page=$page&limit=$limit'
        '${searchQuery != null ? '&search=$searchQuery' : ''}',
      );
      if (response.statusCode == 200) {
        return json.decode(
          response.body,
        ); // Retourne un Map avec projects et pagination
      } else if (response.statusCode == 404) {
        return {
          'projects': [],
          'pagination': {
            'totalItems': 0,
            'totalPages': 0,
            'currentPage': page,
            'itemsPerPage': limit,
            'hasNextPage': false,
            'hasPreviousPage': false,
          },
        };
      } else {
        throw Exception('Failed to load manager projects: ${response.body}');
      }
    } catch (error) {
      print('Error in getProjectsByManagerId: $error');
      rethrow;
    }
  }

  // Envoyer une demande d'augmentation de budget
  Future<Map<String, dynamic>> sendBudgetRequest({
    required String projectId,
    required double amount,
    required String userId,
  }) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];

      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/RequestResponse/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'requestType': 'BUDGET_REQUEST',
          'message': 'Demande d\'augmentation de budget',
          'metadata': {'projectId': projectId, 'amount': amount},
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send budget request: ${response.body}');
      }
    } catch (error) {
      print('Error in sendBudgetRequest: $error');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer le projet courant
  Future<Map<String, dynamic>?> getCurrentProject() async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/getcurrentprject'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('[ProjectApi] Erreur getCurrentProject: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> setCurrentProject(selectedProject) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      final projectId = selectedProject['_id']; // Récupérer l'ID du projet
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/project/modifycurrentproject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },

        body: json.encode({
          'projectId': projectId, // Envoyer l'ID du projet dans le corps
        }),
      );
      print("${ApiConfig.baseUrl}/api/project/modifycurrentproject");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('[ProjectApi] Erreur getCurrentProject: $e');
      return null;
    }
  }

  //////////mta3 interaction
  Future<List<Map<String, dynamic>>> getColleagueProjects() async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("Token utilisé pour getProjects: $token");
      final decodedToken = tokenData['decodedToken'];
      final extractedUserId = decodedToken['userId']?.toString();
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/RequestResponse/getcolleague'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else {
        throw Exception('Failed to load colleague projects: ${response.body}');
      }
    } catch (error) {
      print('Error in getColleagueProjects: $error');
      rethrow;
    }
  }

  Future<void> sendProjectReviewRequest({
    required String projectId,
    String reviewNote = '',
    message = "Demande de consultation de projet",
  }) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("Token utilisé pour getProjects: $token");
      final decodedToken = tokenData['decodedToken'];
      final extractedUserId = decodedToken['userId']?.toString();

      if (token == null) throw Exception('No authentication token available');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/RequestResponse/request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'requestType': 'PROJECT_REVIEW',
          'message': "Demande de consultation de projet",
          'metadata': {'projectId': projectId, 'reviewNote': reviewNote},
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send review request: ${response.body}');
      }
    } catch (error) {
      print('Error in sendProjectReviewRequest: $error');
      rethrow;
    }
  }

  // Récupérer les projets consultables (viewableBy)
  Future<List<dynamic>> getProjectsByViewableUser(String userId) async {
    try {
      final tokenData = await _authService.LoadToken();
      final token = tokenData['authToken'];
      print("Token utilisé pour getProjects: $token");
      final decodedToken = tokenData['decodedToken'];
      final extractedUserId = decodedToken['userId']?.toString();

      if (token == null) throw Exception('No authentication token available');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/viewby'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'] ?? [];
      } else {
        throw Exception(
          'Failed to load viewable projects: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to load viewable projects: $e');
    }
  }

  ////////////////////////
  Future<Map<String, dynamic>> fetchiliProject({String? projectId}) async {
    final tokenData = await authService.LoadToken();
    final token = tokenData['authToken'];
    print('fetchiliprojet');
    print(projectId);
    final endpoint =
        projectId != null
            ? '${ApiConfig.baseUrl}/api/project/fetchiliprojet/$projectId'
            : '${ApiConfig.baseUrl}/api/project/fetchiliprojet';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load project data: ${response.statusCode}');
    }
  }
}
