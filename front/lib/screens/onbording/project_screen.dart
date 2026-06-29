import 'dart:async';
import 'dart:convert';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Telnet/services/project_api.dart';

class Project {
  final String id;
  final String name;
  final int status;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final double budget;
  final String currency;
  final String? secondCurrency;
  final String pays;
  final Map<String, dynamic>? manager;
  final double totalInvoices;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.dateDebut,
    this.dateFin,
    required this.budget,
    required this.currency,
    this.secondCurrency,
    required this.pays,
    required this.manager,
    double? totalInvoices, // nullable
  }) : totalInvoices = totalInvoices ?? 0.0; // default value

  String get statusText {
    switch (status) {
      case 1:
        return 'Non confirmé';
      case 2:
        return 'En cours';
      case 3:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }
}

class ProjectsScreen extends StatefulWidget {
  final String userId;
  final String? userRole;
  const ProjectsScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with TickerProviderStateMixin {
  // Variables d'état
  List<Project> _projects = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _currentPage = 1;
  int _itemsPerPage = 8;
  Map<String, dynamic>? _paginationInfo;
  late ProjectApi _projectApi;
  //
  String _searchQuery = '';
  // Contrôleurs d'animation
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _projectApi = ProjectApi();
    _initAnimations();
    _loadProjects();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.85),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.1),
        weight: 25,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      List<Map<String, dynamic>> projectsData;

      if (widget.userRole != "PM") {
        // Si l'utilisateur n'est pas PM, charger tous les projets avec les infos du manager
        final response = await _projectApi.getProjectswithmanagerPagination(
          page: _currentPage,
          limit: 10,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        setState(() {
          _projects =
              (response['projects'] as List)
                  .map(
                    (project) => Project(
                      id: project['_id'].toString(),
                      name: project['name'].toString(),
                      status: (project['status'] as num).toInt(),
                      dateDebut: DateTime.parse(
                        project['datedebut'].toString(),
                      ),
                      dateFin:
                          project['datefin'] != null
                              ? DateTime.parse(project['datefin'].toString())
                              : null,
                      budget: (project['budget'] as num).toDouble(),
                      currency: project['currency'].toString(),
                      secondCurrency: project['second_currency']?.toString(),
                      totalInvoices:
                          (project['totalinvoices'] as num?)?.toDouble(),
                      pays: project['pays'].toString(),
                      manager: {
                        'name':
                            project['manager']?['name']?.toString() ??
                            'Non assigné',
                      },
                    ),
                  )
                  .toList();

          _paginationInfo = response['pagination'];
          _isLoading = false;
        });
      } else {
        // Si PM  charger seulement ses projets
        final response = await _projectApi.getProjectsByManagerIdPagination(
          widget.userId,
          managerId: widget.userId,
          page: _currentPage,
          limit: 10,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        setState(() {
          _projects =
              (response['projects'] as List)
                  .map(
                    (project) => Project(
                      id: project['_id'].toString(),
                      name: project['name'].toString(),
                      status: (project['status'] as num).toInt(),
                      dateDebut: DateTime.parse(
                        project['datedebut'].toString(),
                      ),
                      dateFin:
                          project['datefin'] != null
                              ? DateTime.parse(project['datefin'].toString())
                              : null,
                      budget: (project['budget'] as num).toDouble(),
                      currency: project['currency'].toString(),
                      secondCurrency: project['second_currency']?.toString(),
                      totalInvoices:
                          (project['totalinvoices'] as num?)?.toDouble(),
                      pays: project['pays'].toString(),
                      manager: {
                        'name':
                            project['manager']?['name']?.toString() ??
                            'Non assigné',
                      },
                    ),
                  )
                  .toList();
          //print(project.t);

          _paginationInfo = response['pagination'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des projets: $e')),
      );
    }
  }

  Future<void> _updateProjectStatus(String projectId, int newStatus) async {
    setState(() => _isLoading = true);
    print("hiiiiiiiiiiiiiiiiiiiiiiiiiiiiii");
    try {
      final tokenData = await authService.LoadToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/project/projetupdate/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${tokenData['authToken']}',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour avec succès')),
        );
        _loadProjects();
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Échec de la mise à jour: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProjectDetails(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.all(16),
            child: ProjectDetailsCard(
              userRole: widget.userRole,
              project: project,
              onStatusUpdate:
                  (newStatus) => _updateProjectStatus(project.id, newStatus),
            ),
          ),
    );
  }

  //handle search
  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage =
          1; // Réinitialiser à la première page lors d'une nouvelle recherche
    });
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          _buildHeaderWithBudget(),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildToolbar(),
                  Expanded(
                    child:
                        _isLoading
                            ? Center(child: CircularProgressIndicator())
                            : _projects.isEmpty
                            ? SingleChildScrollView(
                              // Wrap empty state in SingleChildScrollView
                              child: _buildEmptyState(),
                            )
                            : RefreshIndicator(
                              onRefresh: _loadProjects,
                              child: ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _projects.length,
                                itemBuilder: (context, index) {
                                  return _buildProjectCard(_projects[index]);
                                },
                              ),
                            ),
                  ),
                  _buildPagination(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadProjects,
        child: Icon(Icons.refresh),
        backgroundColor: Color.fromRGBO(123, 97, 255, 1).withOpacity(0.9),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Widgets de construction
  Widget _buildHeaderWithBudget() {
    /*double totalBudget = _projects.fold(
      0,
      (sum, project) => sum + project.budget,
    );*/
    return Container(
      height: 125,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Liste des Projets',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  _buildAnimatedBackpackButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackpackButton() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(Icons.receipt_long, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher projets',
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade700),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                // Annuler le timer précédent s'il existe
                if (_searchDebounce?.isActive ?? false)
                  _searchDebounce?.cancel();

                // Démarrer un nouveau timer
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  _handleSearch(value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showProjectDetails(project),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Première ligne - Badge et date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nom du projet en violet (sans le label "Projet")
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: Text(
                          project.name,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.userRole !=
                          "PM") // Afficher le nom du PM seulement si l'utilisateur n'est pas PM
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
                          ),
                          child: Text(
                            'Chef de projet : ${project.manager?['name'] ?? 'Non assigné'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 15,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(project.dateDebut),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 14),

              // Deuxième ligne - Détails
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pays avec icône
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            project.pays,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Budget
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 4),
                        Text(
                          '${project.budget.toStringAsFixed(2)} ${project.currency}',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Troisième ligne - Statut seulement
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(project.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(project.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    project.statusText.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(project.status),
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final currentPage =
        _paginationInfo?['currentPage'] as int? ??
        1; // Utilisez 'currentPage' au lieu de 'page'
    final totalPages = _paginationInfo?['totalPages'] as int? ?? 1;
    final hasNextPage = _paginationInfo?['hasNextPage'] as bool? ?? false;
    final hasPreviousPage =
        _paginationInfo?['hasPreviousPage'] as bool? ?? false;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed:
                hasPreviousPage
                    ? () {
                      setState(() => _currentPage = currentPage - 1);
                      _loadProjects();
                    }
                    : null,
          ),
          Text('Page $currentPage / $totalPages'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed:
                hasNextPage
                    ? () {
                      setState(() => _currentPage = currentPage + 1);
                      _loadProjects();
                    }
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Aucun projet trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Modifiez vos critères de recherche',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return const Color.fromARGB(255, 186, 63, 14);
      default:
        return Colors.grey;
    }
  }
}

//
class ProjectDetailsCard extends StatefulWidget {
  final Project project;
  final Function(int) onStatusUpdate;

  final String? userRole;

  const ProjectDetailsCard({
    super.key,
    required this.project,
    required this.onStatusUpdate,
    this.userRole,
  });

  @override
  State<ProjectDetailsCard> createState() => _ProjectDetailsCardState();
}

class _ProjectDetailsCardState extends State<ProjectDetailsCard> {
  bool _isSubmitting = false;

  void _confirmStatusChange() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Souhaitez-vous clôturer ce projet ?"),
          actions: [
            TextButton(
              child: Text(
                "Annuler",
                style: TextStyle(color: Colors.grey.shade700),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Confirmer", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isSubmitting = true);
                await widget.onStatusUpdate(3); // 3 = terminé
                if (mounted) {
                  setState(() => _isSubmitting = false);
                  Navigator.of(context).pop(); //
                }
              },
            ),
          ],
        );
      },
    );
  }

  //@override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isPM = widget.userRole == "PM";
    // Valeur sécurisée pour le nom du manager
    final managerName =
        widget.project.manager != null
            ? widget.project.manager!['name']?.toString()
            : null;

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(10),
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails du Projet',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Inter Tight',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildDetailField(
                    label: 'Nom du projet',
                    value: widget.project.name,
                    icon: Icons.work_outline,
                  ),
                  // Ajout du champ Chef de projet si l'utilisateur n'est pas PM
                  if (!isPM)
                    _buildDetailField(
                      label: 'Chef de projet',

                      value: managerName ?? 'Non assigné',

                      icon: Icons.person_outline,
                    ),
                  _buildDetailField(
                    label: 'Date de début',
                    value: dateFormat.format(widget.project.dateDebut),
                    icon: Icons.calendar_today,
                  ),
                  if (widget.project.dateFin != null)
                    _buildDetailField(
                      label: 'Date de fin',
                      value: dateFormat.format(widget.project.dateFin!),
                      icon: Icons.calendar_today,
                    ),
                  _buildDetailField(
                    label: 'Budget',
                    value:
                        '${widget.project.budget.toStringAsFixed(2)} ${widget.project.currency}',
                    icon: Icons.account_balance_wallet,
                  ),
                  _buildDetailField(
                    label: 'Devise principale',
                    value: widget.project.currency,
                    icon: Icons.currency_exchange,
                  ),
                  if (widget.project.secondCurrency != null)
                    _buildDetailField(
                      label: 'Devise secondaire',
                      value: widget.project.secondCurrency!,
                      icon: Icons.currency_exchange,
                    ),
                  if (widget.project.totalInvoices != null)
                    _buildDetailField(
                      label: 'Montant consommé',
                      value:
                          '${widget.project.totalInvoices!.toStringAsFixed(2)} ${widget.project.currency}',
                      icon: Icons.account_balance_wallet,
                    ),

                  _buildDetailField(
                    label: 'Pays',
                    value: widget.project.pays,
                    icon: Icons.location_on,
                  ),
                  _buildStatusField(),
                  const SizedBox(height: 24),
                  // Afficher le bouton seulement si l'utilisateur est PM et que le projet est en cours
                  if (isPM && widget.project.status == 2)
                    ElevatedButton(
                      onPressed: _confirmStatusChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red),
                        ),
                      ),
                      child: Text(
                        'Marquer comme Terminé',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(text: value),
        style: TextStyle(color: Colors.black87), // Texte noir
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white, // Fond blanc
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildStatusField() {
    final statusColor = _getStatusColor(widget.project.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        readOnly: true,
        controller: TextEditingController(text: widget.project.statusText),
        style: TextStyle(color: statusColor),
        decoration: InputDecoration(
          labelText: 'Statut',
          labelStyle: TextStyle(color: Colors.grey.shade600),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white, // Fond blanc
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return const Color.fromARGB(255, 186, 63, 14);
      default:
        return Colors.grey;
    }
  }
}
