import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/screens/onbording/components/decorative_circles.dart';
import 'package:Telnet/screens/onbording/components/userlist.dart';
import 'package:Telnet/screens/onbording/components/add_modify_user.dart';

class AddUserScreen extends StatefulWidget {
  final String? userId;

  const AddUserScreen({super.key, required this.userId});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class User {
  final String? id; // Id
  final String username;
  final String? email;
  //final String? projectName;
  final String? adresse;
  final int? phone;
  final String? password;
  final String? imageUrl;
  final String creepar;
  final String? role;
  final bool isHighlighted; //pour l'ADmin
  final bool activated;
  User({
    required this.id,
    required this.username,
    this.email,
    //this.projectName,
    this.adresse,
    this.phone,
    this.password,
    this.imageUrl,
    required this.creepar,
    this.role,
    this.isHighlighted = false,
    this.activated = true,
  });
  User copyWith({bool? isHighlighted, bool? activated}) {
    return User(
      id: id,
      username: username,
      phone: phone,
      imageUrl: imageUrl,
      creepar: creepar,
      adresse: adresse,
      email: email,
      role: role,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      activated: activated ?? this.activated,
    );
  }
}

class _AddUserScreenState extends State<AddUserScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  List<User> users = [];
  User? _selectedUser; // Pour stocker l'utilisateur en cours d'édition
  bool showAddUserCard = false; // Contrôle l'affichage du formulaire
  void _toggleAddUserCard() {
    setState(() {
      showAddUserCard = !showAddUserCard;
      if (!showAddUserCard) {
        _selectedUser = null; // Réinitialiser l'utilisateur sélectionné
      }
      FocusManager.instance.primaryFocus?.unfocus(); // Fermer le clavier
    });
  }

  void _handleUserSubmit(User user) {
    // Update local
    setState(() {
      if (_selectedUser != null) {
        // update the user
        final index = users.indexWhere((u) => u.id == _selectedUser!.id);
        if (index != -1) {
          users[index] = user;
        }
      } else {
        // add new user
        users.add(user);
      }
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (confirmContext) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ConfirmationCard(
              isSuccess: true,
              message:
                  _selectedUser != null
                      ? 'Utilisateur mis à jour avec succès'
                      : 'Utilisateur ajouté avec succès',
            ),
          ),
    );

    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      //
      if (mounted) {
        setState(() {
          _selectedUser = null;
          showAddUserCard = false;
        });
      }
    });
  }

  void _handleEditUser(User user) {
    setState(() {
      _selectedUser = user;
      showAddUserCard = true; // Afficher le formulaire en mode édition
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Fermer le clavier quand on tape en dehors
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              // Cercles décoratifs
              const DecoratedCircles(),

              // liste des utilisateurs
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Liste des Chefs Projets',
                        style: TextStyle(
                          fontFamily: 'Inter Tight',
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: UserListContainer(
                        users: users,
                        onUserTap: _handleEditUser,
                        userId: widget.userId ?? '',
                        onRefresh: () {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (showAddUserCard)
                UserFormCard(
                  currentUserRole: 'RF', // Nouveau paramètre
                  creterid: widget.userId,
                  isEditing: _selectedUser != null,
                  userToEdit: _selectedUser,
                  onSubmit: _handleUserSubmit,
                  onClose: _toggleAddUserCard,
                ),

              if (!showAddUserCard)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: _toggleAddUserCard,
                    backgroundColor: theme.primaryColor,
                    child: Tooltip(
                      message: "Ajouter un chef projets",
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.onPrimary,
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
}
