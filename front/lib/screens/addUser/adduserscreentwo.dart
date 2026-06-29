import 'package:Telnet/screens/onbording/components/add_modify_user.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/screens/addUser/add_user_screen.dart';

class AddUserScreenTwo extends StatefulWidget {
  final String? userId;
  final String? userRole;
  final Function(User)? onUserTap;

  const AddUserScreenTwo({
    Key? key,
    required this.userId,
    required this.userRole,
    this.onUserTap,
  }) : super(key: key);

  @override
  State<AddUserScreenTwo> createState() => _AddUserScreenTwoState();
}

class _AddUserScreenTwoState extends State<AddUserScreenTwo> {
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

    // Cas 1: La réponse est directement une liste
    if (response is List) {
      return _mapUserData(response);
    }

    // Cas 2: La réponse est un Map avec une clé 'data' contenant une liste
    if (response is Map && response['data'] is List) {
      return _mapUserData(response['data']);
    }

    // Cas 3: La réponse est un Map avec une clé 'data' qui est un Map contenant une liste
    if (response is Map &&
        response['data'] is Map &&
        response['data']['data'] is List) {
      return _mapUserData(response['data']['data']);
    }
    //print(object);
    // Cas 4: Autres structures non reconnues
    print('Structure de réponse non reconnue: ${response.runtimeType}');
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
        print(responseData);
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
    // Extraction de l'état d'activation (avec valeur par défaut = true)
    bool activated = true;
    if (userData.containsKey('activated')) {
      activated = userData['activated'] == true;
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
      activated: activated,
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
              currentUserRole: 'Admin', // Nouveau paramètre
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

                  //
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  //
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

                    // Auto-dismiss
                    Future.delayed(const Duration(seconds: 2)).then((_) {
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    });
                  }
                } catch (e) {
                  //
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  //
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

                    // Auto-dismiss
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
              currentUserRole: 'Admin', // Nouveau paramètre
              isEditing: false,
              creterid: _selectedRfId ?? widget.userId,
              onSubmit: (newUser) async {
                //
                Navigator.of(dialogContext).pop();

                // indicateur de chargement
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (loadingContext) =>
                          const Center(child: CircularProgressIndicator()),
                );

                try {
                  // attendre
                  await Future.delayed(const Duration(milliseconds: 300));

                  // Reload Datz
                  await _loadAllData();

                  // indicateur de chargement
                  if (mounted) Navigator.of(context).pop();

                  //
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (successContext) => ConfirmationCard(
                            isSuccess: true,
                            message: 'Utilisateur ajouté avec succès',
                          ),
                    );

                    //
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted && Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  // indicateur
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }

                  // Afficher l'erreur
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder:
                          (errorContext) => ConfirmationCard(
                            isSuccess: false,
                            message: 'Erreur lors de l\'ajout: ${e.toString()}',
                          ),
                    );

                    //
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
              //_buildSearchBar(),
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
          // Ligne pour les listes
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
                          ? 'Aucun chef de projets trouvé'
                          : 'Aucun chef de projets pour ce responsable finance',
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
  ///////////

  //reinitialiser les hifhlights
  void _resetHighlights() {
    setState(() {
      _allRfUsers =
          _allRfUsers.map((rf) => rf.copyWith(isHighlighted: false)).toList();
    });
  }

  /////////////////
  // Fonction pour basculer l'état d'activation d'un utilisateur (RF ou PM)
  Future<void> _toggleUserActivation(User user) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Afficher un dialogue de confirmation avant de changer l'état
      final bool confirmChange =
          await showDialog(
            context: context,
            builder:
                (dialogContext) => AlertDialog(
                  title: Text(
                    user.activated
                        ? 'Désactiver ${user.username}'
                        : 'Activer ${user.username}',
                  ),
                  content: Text(
                    user.activated
                        ? 'Êtes-vous sûr de vouloir désactiver ${user.username}?'
                        : 'Êtes-vous sûr de vouloir activer ${user.username}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text('Confirmer'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirmChange) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Appel API pour changer l'état activated
      final response = await Api.updateUser(
        userId: user.id!,
        name: user.username,
        email: user.email ?? '',
        phone: user.phone?.toString() ?? '',
        adress: user.adresse ?? '',
        activated: !user.activated,
      );

      if (response['success'] == true) {
        // Mettre à jour l'état local après confirmation du serveur
        setState(() {
          // Mise à jour pour les RF
          if (user.role == 'RF') {
            final index = _allRfUsers.indexWhere((u) => u.id == user.id);
            if (index != -1) {
              _allRfUsers[index] = user.copyWith(activated: !user.activated);
            }

            final filteredIndex = _filteredRfUsers.indexWhere(
              (u) => u.id == user.id,
            );
            if (filteredIndex != -1) {
              _filteredRfUsers[filteredIndex] = user.copyWith(
                activated: !user.activated,
              );
            }
          }
          // Mise à jour pour les PM
          else if (user.role == 'PM') {
            final index = _allPmUsers.indexWhere((u) => u.id == user.id);
            if (index != -1) {
              _allPmUsers[index] = user.copyWith(activated: !user.activated);
            }

            final filteredIndex = _filteredPmUsers.indexWhere(
              (u) => u.id == user.id,
            );
            if (filteredIndex != -1) {
              _filteredPmUsers[filteredIndex] = user.copyWith(
                activated: !user.activated,
              );
            }
          }
        });

        // Afficher une confirmation de succès
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: ConfirmationCard(
                  isSuccess: true,
                  message:
                      user.activated
                          ? '${user.username} a été désactivé avec succès'
                          : '${user.username} a été activé avec succès',
                ),
              ),
        );

        // Auto-fermeture après 2 secondes
        Future.delayed(const Duration(seconds: 2)).then((_) {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      } else {
        throw Exception(
          'Échec de la mise à jour du statut: ${response['error']}',
        );
      }
    } catch (e) {
      // Afficher une notification d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildActivationToggleSwitch(User user) {
    return GestureDetector(
      onTap: () => _toggleUserActivation(user),
      child: Container(
        width: 48.0,
        height: 24.0,
        padding: EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: user.activated ? Colors.green : Colors.grey.shade400,
        ),
        child: AnimatedAlign(
          duration: Duration(milliseconds: 200),
          alignment:
              user.activated ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeInOut,
          child: Container(
            width: 20.0,
            height: 20.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 1.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Toggle mdawra
  Widget _buildModernToggle(User user) {
    return Tooltip(
      message: user.activated ? 'Désactiver ' : 'Activer ',
      child: InkWell(
        onTap: () => _toggleUserActivation(user),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                user.activated
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
          ),
          child: Icon(
            user.activated
                ? Icons.check_circle_rounded
                : Icons.remove_circle_rounded,
            color: user.activated ? Colors.green : Colors.red,
            size: 22,
          ),
        ),
      ),
    );
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
              // Bouton d'activation personnalisé
              if (user.role == 'RF')
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: _buildModernToggle(user),
                ),
              if (user.role == 'RF')
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  color: Colors.grey[600],
                  tooltip: "Modifier ",
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
