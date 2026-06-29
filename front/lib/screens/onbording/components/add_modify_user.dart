import 'dart:async';
import 'package:Telnet/screens/addUser/add_user_screen.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';

class UserFormCard extends StatefulWidget {
  final String? currentUserRole;
  final bool isEditing;
  final User? userToEdit;
  final Function(User) onSubmit;
  final VoidCallback onClose;
  final String? creterid;
  const UserFormCard({
    super.key,
    this.currentUserRole,
    required this.isEditing,
    this.userToEdit,
    required this.onSubmit,
    required this.onClose,
    required this.creterid,
  });

  @override
  _UserFormCardState createState() => _UserFormCardState();
}

class _UserFormCardState extends State<UserFormCard> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.userToEdit != null) {
      print('heeeeeeeeeey');
      print(widget.currentUserRole);
      _initializeFormWithUserData();
    }
  }

  void _initializeFormWithUserData() {
    final user = widget.userToEdit!;
    print('$user');
    controllers[0].text = user.username ?? '';
    controllers[1].text = user.email ?? '';
    //controllers[2].text = user.projectName ?? '';
    controllers[3].text = user.adresse ?? '';
    controllers[4].text = user.phone?.toString() ?? '';
    //controllers[5].text = user.password ?? ''; inajim back igenereha
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      validator: (value) {
        if (label == 'Email' && value!.isNotEmpty && !value.contains('@')) {
          return 'Email invalide';
        }
        if (label == 'Nom d\'utilisateur' && value!.isEmpty) {
          return 'Ce champ est requis';
        }
        if (label == 'Numéro de téléphone') {
          if (value == null || value.isEmpty) return 'Ce champ est requis';
          if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
            // Exactement 8 chiffres
            return 'Doit contenir exactement 8 chiffres';
          }
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controllers[5],
      focusNode: focusNodes[5],
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      validator: (value) {
        if (!widget.isEditing && (value == null || value.isEmpty)) {
          return 'Ce champ est requis';
        }
        if (value != null && value.isNotEmpty && value.length < 6) {
          return '6 caractères minimum';
        }
        return null;
      },
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (loadingContext) =>
                  const Center(child: CircularProgressIndicator()),
        );

        // API call
        final result =
            widget.isEditing
                ? await Api.updateUser(
                  userId: widget.userToEdit!.id!,
                  name: controllers[0].text,
                  email: controllers[1].text,
                  phone: controllers[4].text,
                  adress: controllers[3].text,
                  password:
                      controllers[5].text.isNotEmpty
                          ? controllers[5].text
                          : null,
                )
                : await Api.addUser(
                  name: controllers[0].text,
                  email: controllers[1].text,
                  phone: controllers[4].text,
                  adresse: controllers[3].text,
                  userId: widget.creterid,
                );
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        if (result['success']) {
          final user = User(
            id:
                widget.isEditing
                    ? widget.userToEdit!.id
                    : result['data']['_id'],
            username: controllers[0].text,
            email: controllers[1].text,
            adresse:
                controllers[3].text.isNotEmpty ? controllers[3].text : null,
            phone:
                controllers[4].text.isNotEmpty
                    ? int.tryParse(controllers[4].text)
                    : null,
            creepar: widget.creterid ?? "",
          );
          widget.onSubmit(user);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erreur inconnue'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        print("Erreur lors de la soumission: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  //
  // Méthode pour obtenir le titre dynamique
  String _getTitle() {
    if (widget.isEditing) {
      // Mode modification
      if (widget.currentUserRole == 'Admin') {
        return 'Modifier le Responsable Financier';
      } else if (widget.currentUserRole == 'RF') {
        return 'Modifier le Chef de Projets';
      } else {
        return 'Modifier l\'utilisateur';
      }
    } else {
      // Mode ajout
      if (widget.currentUserRole == 'Admin') {
        return 'Ajouter un Responsable Financier';
      } else if (widget.currentUserRole == 'RF') {
        return 'Ajouter un Chef de Projets';
      } else {
        return 'Ajouter un utilisateur';
      }
    }
  }

  // Méthode pour obtenir le texte du bouton de soumission
  String _getSubmitButtonText() {
    if (widget.isEditing) {
      if (widget.currentUserRole == 'Admin') {
        return 'Mettre à jour le Responsable Financier';
      } else if (widget.currentUserRole == 'RF') {
        return 'Mettre à jour le Chef de Projets';
      } else {
        return 'Mettre à jour';
      }
    } else {
      if (widget.currentUserRole == 'Admin') {
        return 'Ajouter le Responsable Financier';
      } else if (widget.currentUserRole == 'RF') {
        return 'Ajouter le Chef de Projets';
      } else {
        return 'Ajouter';
      }
    }
  }

  // Méthode pour obtenir le placeholder du nom
  String _getNamePlaceholder() {
    if (widget.currentUserRole == 'ADMIN') {
      return 'Nom du Responsable Financier';
    } else if (widget.currentUserRole == 'RF') {
      return 'Nom du Chef de Projet';
    } else {
      return 'Nom de l\'utilisateur';
    }
  }

  //
  Future<void> _showAndAutoCloseConfirmation({
    required BuildContext context,
    required bool isSuccess,
    required String message,
  }) async {
    if (!context.mounted) return;

    final completer = Completer<void>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConfirmationCard(isSuccess: isSuccess, message: message),
            ),
          ),
    ).then((_) => completer.complete());

    await Future.delayed(const Duration(seconds: 2));
    if (context.mounted) Navigator.of(context).pop();

    await completer.future;
  }

  //
  Future<void> _showConfirmationDialog({
    required BuildContext context,
    required bool isSuccess,
    required String message,
  }) async {
    final completer = Completer<void>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: ConfirmationCard(isSuccess: isSuccess, message: message),
            ),
          ),
    ).then((_) => completer.complete());

    Future.delayed(const Duration(seconds: 2)).then((_) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GestureDetector(
            onTap: () => {},
            child: Container(
              width: 400,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTitle(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontFamily: 'Inter Tight',
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            context,
                            controller: controllers[0],
                            focusNode: focusNodes[0],
                            label: 'Nom d\'utilisateur',
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            controller: controllers[1],
                            focusNode: focusNodes[1],
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            controller: controllers[3],
                            focusNode: focusNodes[3],
                            label: 'Adresse',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            context,
                            controller: controllers[4],
                            keyboardType: TextInputType.number,
                            focusNode: focusNodes[4],
                            label: 'Numéro de téléphone',
                            icon: Icons.phone_outlined,
                          ),

                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              _getSubmitButtonText(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontFamily: 'Inter Tight',
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
