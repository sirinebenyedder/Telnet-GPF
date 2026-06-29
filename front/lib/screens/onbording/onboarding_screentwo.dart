import 'package:Telnet/screens/onbording/components/add_modify_user.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/screens/addUser/add_user_screen.dart';

class OnBordingScreenTwo extends StatefulWidget {
  final String? userId;
  final String? userRole;
  final Function(User)? onUserTap;

  const OnBordingScreenTwo({
    Key? key,
    required this.userId,
    required this.userRole,
    this.onUserTap,
  }) : super(key: key);

  @override
  State<OnBordingScreenTwo> createState() => _OnBordingScreenTwoState();
}

class _OnBordingScreenTwoState extends State<OnBordingScreenTwo> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _allRfUsers = [];
  List<User> _allPmUsers = [];
  List<User> _filteredPmUsers = [];
  int _currentPage = 1;
  int _itemsPerPage = 8;
  bool _isLoading = false;
  bool _hasError = false;
  Map<String, dynamic>? _paginationInfo;
  String? _selectedRfId;
  User? _selectedUser;
  //
  final TextEditingController _rfSearchController = TextEditingController();
  final TextEditingController _pmSearchController = TextEditingController();
  List<User> _filteredRfUsers = []; // Nouvelle liste pour les RF filtrés
  //
  @override
  void initState() {
    super.initState();
    _loadAllData();
    _rfSearchController.addListener(_filterRfUsers);
    _pmSearchController.addListener(_filterPmUsers);
  }

  @override
  void dispose() {
    _rfSearchController.dispose();
    _pmSearchController.dispose();
    super.dispose();
  }

  //reset filter
  void _resetAllFilters() {
    setState(() {
      _rfSearchController.clear();
      _pmSearchController.clear();
      _selectedRfId = null;
      _filteredRfUsers = _allRfUsers;
      _filteredPmUsers = _allPmUsers;
      _currentPage = 1; // Réinitialise aussi la pagination
    });
  }

  Future<void> _loadAllData() async {
    // Sauvegarder l'état actuel
    final currentSelectedRfId = _selectedRfId;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final rfResponse = await Api.fetchUsersByRole(
        page: _currentPage,
        limit: _itemsPerPage,
        role: 'RF',
      );

      final pmResponse = await Api.fetchUsersByRole(
        page: _currentPage,
        limit: _itemsPerPage,
        role: 'PM',
      );

      setState(() {
        setState(() {
          _allRfUsers = _extractUsersFromResponse(rfResponse);
          _allPmUsers = _extractUsersFromResponse(pmResponse);
          _filteredRfUsers = _allRfUsers; // Initialiser la liste filtrée
          _filteredPmUsers = _allPmUsers; // Initialiser la liste filtrée
          _resetAllFilters(); // Réinitialisation après chargement
        });

        _paginationInfo =
            _extractPaginationInfo(rfResponse) ??
            _extractPaginationInfo(pmResponse);
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRfUsers() {
    final query = _rfSearchController.text.toLowerCase();
    setState(() {
      _filteredRfUsers =
          query.isEmpty
              ? _allRfUsers
              : _allRfUsers
                  .where(
                    (rf) =>
                        rf.username.toLowerCase().contains(query) ||
                        (rf.email?.toLowerCase().contains(query) ?? false),
                  )
                  .toList();
    });
  }

  void _filterPmUsers() {
    final query = _pmSearchController.text.toLowerCase();
    setState(() {
      // Base = tous les PM ou seulement ceux du RF sélectionné
      final baseList =
          _selectedRfId == null
              ? _allPmUsers
              : _allPmUsers.where((pm) => pm.creepar == _selectedRfId).toList();

      _filteredPmUsers =
          query.isEmpty
              ? baseList
              : baseList
                  .where(
                    (pm) =>
                        pm.username.toLowerCase().contains(query) ||
                        (pm.email?.toLowerCase().contains(query) ?? false) ||
                        (pm.phone?.toString().contains(query) ?? false),
                  )
                  .toList();
    });
  }

  List<User> _extractUsersFromResponse(dynamic response) {
    if (response == null) return [];

    if (response is List) {
      return _mapUserData(response);
    }

    if (response is Map && response['data'] is List) {
      return _mapUserData(response['data']);
    }

    // data contient data map
    if (response is Map &&
        response['data'] is Map &&
        response['data']['data'] is List) {
      return _mapUserData(response['data']['data']);
    }

    return [];
  }

  Map<String, dynamic>? _extractPaginationInfo(dynamic response) {
    if (response is Map) {
      return response['pagination'] ??
          (response['data'] is Map ? response['data']['pagination'] : null);
    }
    return null;
  }

  List<User> _mapUserData(dynamic responseData) {
    try {
      if (responseData is List) {
        return responseData.map((data) => _parseUser(data)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur de mapping: $e');
      return [];
    }
  }

  User _parseUser(dynamic data) {
    final userData =
        data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data);

    // Extraction du creepar
    dynamic creepar = userData['creepar'];
    String creeparId = '';

    if (creepar is Map) {
      creeparId = creepar['_id']?.toString() ?? '';
    } else if (creepar is String) {
      creeparId = creepar;
    }

    return User(
      id: userData['_id']?.toString() ?? '',
      username: userData['name']?.toString() ?? 'Inconnu',
      phone: userData['phone'],
      imageUrl: userData['imageUrl']?.toString(),
      creepar: creeparId, // On stocke seulement l'ID maintenant
      adresse: userData['adresse']?.toString() ?? '',
      email: userData['email']?.toString() ?? '',
      role: userData['role']?.toString() ?? '',
    );
  }

  void _filterPmByRf(String? rfId) {
    _resetHighlights();
    setState(() {
      _selectedRfId = rfId;
      _filteredPmUsers =
          rfId == null
              ? _allPmUsers
              : _allPmUsers.where((pm) => pm.creepar == rfId).toList();
    });
  }

  void _handleSearch() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        // Réinitialiser si la recherche est vide
        _filteredPmUsers =
            _selectedRfId == null
                ? _allPmUsers
                : _allPmUsers
                    .where((pm) => pm.creepar == _selectedRfId)
                    .toList();
        _resetHighlights();
        return;
      }

      // Filtrer les RF
      _allRfUsers =
          _allRfUsers.map((rf) {
            final matches =
                rf.username.toLowerCase().contains(query) ||
                (rf.email?.toLowerCase().contains(query) ?? false);
            return rf.copyWith(isHighlighted: matches);
          }).toList();

      // Filtrer les PM en fonction du RF sélectionné
      final basePmList =
          _selectedRfId == null
              ? _allPmUsers
              : _allPmUsers.where((pm) => pm.creepar == _selectedRfId);

      _filteredPmUsers =
          basePmList.where((pm) {
            return pm.username.toLowerCase().contains(query) ||
                (pm.email?.toLowerCase().contains(query) ?? false) ||
                (pm.phone?.toString().contains(query) ?? false);
          }).toList();
    });
  }

  void _changePage(int newPage) {
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
      _loadAllData();
    }
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            child: UserFormCard(
              isEditing: true,
              userToEdit: user,
              creterid: widget.userId,
              onSubmit: (updatedUser) async {
                // Close the form dialog
                Navigator.of(dialogContext).pop();

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (loadingContext) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Reload data
                  await _loadAllData();

                  // Close loading indicator
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  // Show success confirmation that auto-dismisses
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (confirmContext) => Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: ConfirmationCard(
                              isSuccess: true,
                              message: 'Utilisateur mis à jour avec succès',
                            ),
                          ),
                    );

                    // Auto-dismiss after 2 seconds
                    Future.delayed(const Duration(seconds: 2)).then((_) {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                } catch (e) {
                  // Close loading indicator if still showing
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  // Show error message
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (errorContext) => Dialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            child: ConfirmationCard(
                              isSuccess: false,
                              message: 'Erreur: ${e.toString()}',
                            ),
                          ),
                    );

                    // Auto-dismiss after 2 seconds
                    Future.delayed(const Duration(seconds: 2)).then((_) {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                }
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
    );
  }

  //add
  void _showAddUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            child: UserFormCard(
              isEditing: false,
              creterid: _selectedRfId ?? widget.userId,
              onSubmit: (newUser) async {
                // Fermer le dialogue du formulaire
                Navigator.of(dialogContext).pop();

                // Afficher l'indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (loadingContext) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Attendre
                  await Future.delayed(const Duration(milliseconds: 300));

                  // Recharger les données après l'ajout
                  await _loadAllData();

                  // Fermer l'indicateur de chargement
                  if (mounted) Navigator.of(context).pop();

                  // Afficher la confirmation
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (successContext) => ConfirmationCard(
                            isSuccess: true,
                            message: 'Utilisateur ajouté avec succès',
                          ),
                    );

                    // Fermer
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  // Fermer l'indicateur de chargement en cas d'erreur
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (errorContext) => ConfirmationCard(
                            isSuccess: false,
                            message: 'Erreur lors de l\'ajout: ${e.toString()}',
                          ),
                    );
                    await Future.delayed(const Duration(seconds: 3));
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  }
                }
              },
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else if (_hasError)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else
                _buildDualListView(),
              if (!_isLoading && !_hasError && _paginationInfo != null)
                _buildPagination(),
            ],
          ),
        ),
        // Bouton flottant pour ajouter un utilisateur
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton(
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              {
                _showAddUserDialog();
              }
            },
            tooltip: 'Ajouter un Responsable Financier',
          ),
        ),
      ],
    );
  }

  Widget _buildDualListView() {
    return Container(
      constraints: BoxConstraints(maxHeight: 450, minHeight: 200),
      child: Column(
        children: [
          // Ligne pour les titres des sections
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '                             ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _selectedRfId == null
                        ? 'Tous les Chefs de Projet'
                        : 'Chefs de Projet du responable finance sélectionné',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Ligne pour les champs de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSectionSearchBar(
                    controller: _rfSearchController,
                    hintText: 'Rechercher responsable finance',
                    onChanged: _filterRfUsers,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildSectionSearchBar(
                    controller: _pmSearchController,
                    hintText: 'Rechercher chef de projet',
                    onChanged: _filterPmUsers,
                  ),
                ),
              ],
            ),
          ),
          // les listes
          Expanded(
            child: Row(
              children: [
                // Liste RF
                Expanded(
                  child: _buildUserList(
                    users: _filteredRfUsers,
                    isLeftSide: true,
                    selectedId: _selectedRfId,
                    onItemTap: (user) => _filterPmByRf(user.id),
                    onClearSelection: () => _filterPmByRf(null),
                    title: 'Responsables Financiers',
                  ),
                ),
                VerticalDivider(width: 1),
                // Liste PM
                Expanded(
                  child: _buildUserList(
                    users: _filteredPmUsers,
                    isLeftSide: false,
                    onItemTap: (user) {
                      setState(() => _selectedUser = user);
                      widget.onUserTap?.call(user);
                    },
                    title: 'Chefs de projet',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSearchBar({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon:
            controller.text.isNotEmpty
                ? IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                )
                : Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) => onChanged(),
    );
  }

  Widget _buildSearchBar(
    TextEditingController controller,
    String hintText,
    VoidCallback onSearch,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(),
          suffixIcon: IconButton(icon: Icon(Icons.search), onPressed: onSearch),
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) => onSearch(),
      ),
    );
  }

  Widget _buildUserList({
    required List<User> users,
    required String title,
    bool isLeftSide = true,
    String? selectedId,
    required Function(User) onItemTap,
    VoidCallback? onClearSelection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (isLeftSide && selectedId != null)
                IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: onClearSelection,
                  tooltip: 'Effacer la sélection',
                ),
            ],
          ),
        ),
        Expanded(
          child:
              users.isEmpty
                  ? Center(
                    child: Text(
                      isLeftSide
                          ? 'Aucun responsable finance trouvé'
                          : _selectedRfId == null
                          ? 'Aucun chef de projet trouvé'
                          : 'Aucun chef de projet pour ce responsable finance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                  : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(
                        user,
                        isSelected: isLeftSide ? user.id == selectedId : false,
                        onTap: () => onItemTap(user),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  //reinitialiser les hifhlights
  void _resetHighlights() {
    setState(() {
      _allRfUsers =
          _allRfUsers.map((rf) => rf.copyWith(isHighlighted: false)).toList();
    });
  }

  Widget _buildUserCard(
    User user, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.blue[50]
                  : user.isHighlighted
                  ? Colors.yellow[100]
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 1)
                  : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // User avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 246, 242, 242),
                  borderRadius: BorderRadius.circular(12),
                  image:
                      user.imageUrl != null
                          ? DecorationImage(
                            image: NetworkImage(user.imageUrl!),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    user.imageUrl == null
                        ? Center(
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                        : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      user.adresse ?? 'Aucune adresse',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      user.phone != null
                          ? user.phone.toString()
                          : 'Aucun numéro',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (user.role == 'RF')
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  color: Colors.grey[600],
                  onPressed: () => _showEditUserDialog(user),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final currentPage = _paginationInfo?['page'] as int? ?? 1;
    final totalPages = _paginationInfo?['totalPages'] as int? ?? 1;

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
                currentPage > 1 ? () => _changePage(currentPage - 1) : null,
          ),
          Text('Page $currentPage / $totalPages'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed:
                currentPage < totalPages
                    ? () => _changePage(currentPage + 1)
                    : null,
          ),
        ],
      ),
    );
  }
}
