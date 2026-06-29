import 'package:flutter/material.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/screens/addUser/add_user_screen.dart';

class UserListContainer extends StatefulWidget {
  final String userId;
  final Function(User) onUserTap;
  final VoidCallback? onRefresh;
  const UserListContainer({
    Key? key,
    required this.userId,
    required this.onUserTap,
    required List<User> users,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<UserListContainer> createState() => _UserListContainerState();
}

class _UserListContainerState extends State<UserListContainer> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  int _currentPage = 1;
  int _itemsPerPage = 8;
  bool _isLoading = false;
  bool _hasError = false;
  Map<String, dynamic>? _paginationInfo;
  //
  final double _userCardHeight = 75.0;
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Méthode publique pour rafraîchir bich nrafraichi mi screen
  Future<void> refreshUsers() async {
    await _loadUsers();
    widget.onRefresh?.call();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await Api.fetchUsers(
        page: _currentPage,
        limit: _itemsPerPage,
        userId: widget.userId,
      );

      final List<dynamic> userData = response['data'] ?? [];
      print(response['data']);
      setState(() {
        _users =
            userData
                .map(
                  (data) => User(
                    id: data['_id'],
                    username: data['name'] ?? 'Inconnu',
                    phone: data['phone'],
                    imageUrl: data['imageUrl'],
                    creepar:
                        data['creepar'] != null ? data['creepar']['name'] : '',
                    adresse: data['adresse'] ?? '',
                    email: data['email'],
                    activated: data['activated'],
                  ),
                )
                .toList();
        print("activated function");
        print(userData);
        _filteredUsers = _users;
        _paginationInfo = response['pagination'];
      });
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print('Erreur de chargement des utilisateurs: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /////////////////////////////
  Future<void> _toggleUserActivation(User user) async {
    try {
      setState(() => _isLoading = true);

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

      final response = await Api.updateUser(
        userId: user.id!,
        name: user.username,
        email: user.email ?? '',
        phone: user.phone?.toString() ?? '',
        adress: user.adresse ?? '',
        activated: !user.activated,
      );

      if (response['success'] == true) {
        setState(() {
          final index = _users.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _users[index] = user.copyWith(activated: !user.activated);
            _filteredUsers = [
              ..._users,
            ]; // Crée une nouvelle référence pour forcer le rebuild
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserCard(User user) {
    return InkWell(
      onTap: () => widget.onUserTap(user),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage:
                  user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
              child:
                  user.imageUrl == null
                      ? Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            // Infos utilisateur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.adresse ?? 'Aucune adresse',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    user.phone?.toString() ?? 'Aucun numéro',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),

            // Toggle switch
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: _buildModernToggle(user),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildActivationToggle(User user) {
    return Tooltip(
      message: user.activated ? 'Désactiver' : 'Activer',
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _toggleUserActivation(user),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 50,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color:
                user.activated
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
          ),
          child: Row(
            mainAxisAlignment:
                user.activated
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  user.activated ? Icons.check : Icons.close,
                  size: 16,
                  color: user.activated ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ////////////////////////
  void _handleSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers =
            _users
                .where((user) => user.username.toLowerCase().contains(query))
                .toList();
      }
    });
  }

  void _changePage(int newPage) {
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
      _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double listHeight = (_itemsPerPage * _userCardHeight) + 16;
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          _buildSearchBar(),

          // Loading/Error states
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else if (_hasError)
            Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Erreur de chargement des utilisateurs',
                style: TextStyle(color: Colors.red),
              ),
            )
          else
            // User list
            Container(
              constraints: BoxConstraints(maxHeight: 350, minHeight: 100),
              height: listHeight,
              child:
                  _filteredUsers.isEmpty
                      ? Center(
                        child: Text(
                          'Aucun utilisateur trouvé',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                      : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemCount: _filteredUsers.length,
                        separatorBuilder:
                            (context, index) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          return _buildUserCard(_filteredUsers[index]);
                        },
                      ),
            ),

          // Pagination
          if (!_isLoading && !_hasError && _paginationInfo != null)
            _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher un chef projets...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _handleSearch,
            ),
          ),
          onFieldSubmitted: (_) => _handleSearch(),
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
