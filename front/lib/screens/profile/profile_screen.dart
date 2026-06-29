import 'package:Telnet/entry_point.dart';

import 'package:flutter/material.dart';
import 'package:Telnet/route/route_constants.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:Telnet/services/api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:Telnet/screens/profile/profil_card.dart';
import 'package:Telnet/screens/profile/demande_budget.dart';
import 'package:Telnet/screens/profile/demande_interaction.dart';
import 'package:Telnet/screens/profile/addproject_card.dart';
import 'package:Telnet/screens/profile/list_notification.dart';
import 'package:Telnet/services/project_api.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  final String? userRole;
  final bool forcePasswordUpdate;
  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.forcePasswordUpdate = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget? _currentCard;
  final ProjectApi _projectApi = ProjectApi();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showConfirmation = false;
  bool _requestSuccess = false;
  String _confirmationMessage = '';
  //
  @override
  void initState() {
    super.initState();
    print("=== DEBUG ProfileScreen ===");
    print("forcePasswordUpdate: ${widget.forcePasswordUpdate}");
    if (widget.forcePasswordUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCard(
          ProfileCard(
            titleText: "Profil",
            isForcedUpdate: true,
            onSuccess: () {
              // Optionnel: naviguer vers la page d'accueil après succès
              Navigator.pushNamedAndRemoveUntil(
                context,
                entryPointScreenRoute,
                (route) => false,
              );
            },
          ),
        );
      });
    }
  }

  void _showCard(Widget card) {
    setState(() {
      _currentCard = card;
    });
  }

  void _hideCard() {
    setState(() {
      _currentCard = null;
    });
  }

  Future<void> _logout() async {
    try {
      final response = await Api.signout();
      if (response['success']) {
        await authService.clearToken();
        Navigator.pushReplacementNamed(context, logInScreenRoute);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showConfirmationMessage(bool success, String message) {
    setState(() {
      _showConfirmation = true;
      _requestSuccess = success;
      _confirmationMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfirmation = false;
        });
      }
    });
  }

  Future<void> _changeProject() async {
    try {
      setState(() => _isLoading = true);

      // 1. Récupérer le userId depuis le token
      final tokenData = await _authService.LoadToken();
      final currentUserId = tokenData['decodedToken']?['userId'];

      if (currentUserId == null) {
        _showSnackBar("Utilisateur non identifié");
        return;
      }

      // 2. Fetch les projets normaux et consultables
      final managedProjects = await _projectApi.getProjectsByManagerId(
        currentUserId,
      );
      final viewableProjects = await _projectApi.getProjectsByViewableUser(
        currentUserId,
      );

      final activeManagedProjects =
          managedProjects
              .where((p) => p['status'] == 2 || p['status'] == 3)
              .toList();
      final activeViewableProjects =
          viewableProjects
              .where((p) => p['status'] == 2 || p['status'] == 3)
              .toList();

      if (activeManagedProjects.isEmpty && activeViewableProjects.isEmpty) {
        _showConfirmationMessage(false, "Aucun projet disponible");
        return;
      }

      // 3. Afficher le dialogue de sélection
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              "Choisir un projet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color.fromARGB(255, 58, 73, 81),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Section Mes Projets
                  if (activeManagedProjects.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Mes Projets",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...activeManagedProjects.map((project) {
                      return ListTile(
                        title: Text(project['name'].toString()),
                        trailing: Text(
                          project['status'] == 2 ? 'En cours' : 'Terminé',
                          style: TextStyle(
                            color:
                                project['status'] == 2
                                    ? Colors.blue
                                    : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                        onTap:
                            () => Navigator.pop(context, {
                              'project': project,
                              'type': 'normal',
                            }),
                      );
                    }).toList(),
                  ],
                  //print(project);
                  // Section Projets Consultables
                  if (activeViewableProjects.isNotEmpty) ...[
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Projets Partagés",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 58, 57, 57),
                        ),
                      ),
                    ),
                    ...activeViewableProjects.map((project) {
                      return Container(
                        //decoration: BoxDecoration(border: Border.all(color: Colors.red.withOpacity(0.3),),),
                        child: ListTile(
                          title: Text(
                            project['name'].toString(),
                            style: const TextStyle(
                              color: Color.fromARGB(255, 78, 77, 77),
                            ),
                          ),

                          onTap:
                              () => Navigator.pop(context, {
                                'project': project,
                                'type': 'viewable',
                              }),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
            ],
          );
        },
      );
      print('selectedprojectnchofou');
      print(selected);

      // 4. Traitement selon le type de projet sélectionné
      if (selected != null) {
        if (selected['type'] == 'normal') {
          await _projectApi.setCurrentProject(selected['project']);
          _showConfirmationMessage(
            true,
            "Projet ${selected['project']['name']} sélectionné",
          );
          // On navigue vers OnBordingScreen sans viewOnlyProject
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print(
                  "DEBUG: Construction de EntryPoint avec viewOnlyProject: ${selected['project']['_id']}",
                );
                return EntryPoint(
                  userId: widget.userId!,
                  userRole: widget.userRole!,
                  viewOnlyProject: null,
                );
              },
            ),
          );
        } else {
          /*Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => OnBordingScreen(
                    userId: widget.userId!,
                    userRole: widget.userRole!,
                    viewOnlyProject: selected['project']['_id'].toString(),
                  ),
            ),
          );*/
          // Solution simple: naviguer vers EntryPoint avec l'index du OnBoardingScreen (1)
          // et passer directement le viewOnlyProject comme paramètre
          /* Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => EntryPoint(
                    userId: widget.userId!,
                    userRole: widget.userRole!,
                    viewOnlyProject: selected['project']['_id'].toString(),
                  ),
            ),
          );*/
          print(
            "DEBUG: Projet viewable sélectionné avec ID: ${selected['project']['_id']}",
          );

          // APPROCHE DIRECTE: Plus fiable
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                print(
                  "DEBUG: Construction de EntryPoint avec viewOnlyProject: ${selected['project']['_id']}",
                );
                return EntryPoint(
                  userId: widget.userId!,
                  userRole: widget.userRole!,
                  viewOnlyProject: selected['project']['_id'].toString(),
                );
              },
            ),
          );
        }
      }
    } catch (e) {
      _showConfirmationMessage(false, "Erreur: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scaffold principal
        Scaffold(
          appBar: AppBar(
            leading:
                //
                _currentCard != null && !widget.forcePasswordUpdate
                    ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _hideCard,
                    )
                    : null,

            title: Text(
              _currentCard != null
                  ? _getTitleFromCard(_currentCard!)
                  : "Préférences",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
            actions:
                _currentCard == null
                    ? [
                      IconButton(
                        icon:
                            _isLoading
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.swap_horiz),
                        onPressed: _isLoading ? null : _changeProject,
                      ),
                    ]
                    : null,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: _currentCard ?? _buildMenuButtons(),
        ),

        // ConfirmationCard superposée
        if (_showConfirmation)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ConfirmationCard(
              isSuccess: _requestSuccess,
              message: _confirmationMessage,
            ),
          ),
      ],
    );
  }

  // Fonction pour extraire le titre de la carte actuelle
  String _getTitleFromCard(Widget card) {
    if (card is ProfileCard) {
      return card.titleText;
    } else if (card is FinanceRequestCard) {
      return card.titleText;
    } else if (card is PmRequestCard) {
      return card.titleText;
    } else if (card is AddProjectCard) {
      return card.titleText;
    } else if (card is NotificationListScreen) {
      return card.titleText;
    }
    return "Détails"; // Valeur par défaut
  }

  Widget _buildMenuButtons() {
    return ListView(
      children: [
        _buildSettingsButton(
          icon: Icons.person_outline,
          title: "Profil",
          onTap: () => _showCard(const ProfileCard(titleText: "Profil ")),
        ),
        if (widget.userRole == 'PM')
          _buildSettingsButton(
            icon: Icons.monetization_on_outlined,
            title: "Demande Finance",
            onTap:
                () => _showCard(
                  FinanceRequestCard(
                    titleText: "Demande d'augmentation de Budget",
                    userId: widget.userId!,
                  ),
                ),
          ),
        if (widget.userRole == 'PM')
          _buildSettingsButton(
            icon: Icons.people_outline,
            title: "Demande consultation",
            onTap:
                () => _showCard(
                  const PmRequestCard(titleText: "Consultation Projet"),
                ),
          ),
        if (widget.userRole == 'PM')
          _buildSettingsButton(
            icon: Icons.add_box_outlined,
            title: "Ajouter Projet",
            onTap:
                () => _showCard(
                  const AddProjectCard(titleText: "Nouveau Projet"),
                ),
          ),
        if (widget.userRole == 'RF')
          _buildSettingsButton(
            icon: Icons.notifications,
            title: "Gestion dépenses",
            onTap:
                () => _showCard(
                  const NotificationListScreen(titleText: "Gestion dépenses"),
                ),
          ),
        if (widget.userRole == 'PM')
          _buildSettingsButton(
            icon: Icons.notifications,
            title: "Interaction",
            onTap:
                () => _showCard(
                  const NotificationListScreen(titleText: "Interaction"),
                ),
          ),
        const Divider(),
        _buildSettingsButton(
          icon: Icons.logout,
          title: "Déconnexion",
          onTap: _showLogoutConfirmation,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey[600]),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Déconnexion"),
          content: const Text("Voulez-vous vraiment vous déconnecter ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                "Déconnexion",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
