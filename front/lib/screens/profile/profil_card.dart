import 'dart:io';
import 'package:Telnet/route/route_constants.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';
import 'package:Telnet/theme/input_decoration_theme.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:Telnet/services/api.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';

class ProfileCard extends StatefulWidget {
  final String titleText;
  final bool isForcedUpdate;
  final VoidCallback? onSuccess; // callback
  //final bool showBackButton; // Nouveau paramètre
  const ProfileCard({
    super.key,
    required this.titleText,
    this.isForcedUpdate = false,
    this.onSuccess,
    //this.showBackButton = true, // Par défaut true (compatibilité)
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _newpasswController;
  late TextEditingController _actuelpasswController;
  String? _userId;
  bool _isLoading = true;
  File? _selectedImage;
  String? _imageUrl;
  bool _showSaveConfirmation = false;
  String _saveMessage = "";
  bool _saveSuccess = false;
  bool _passwordUpdated = false;
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _actuelpasswController = TextEditingController();
    _newpasswController = TextEditingController();
    _fetchUserIdAndData();
    if (widget.isForcedUpdate) {
      // Focus automatique sur le champ mot de passe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _actuelpasswController.dispose();
    _newpasswController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserIdAndData() async {
    final token = await authService.loadToken();
    if (authService.decodedToken != null) {
      setState(() {
        _userId = authService.decodedToken?['userId'];
      });
      await _fetchUserData();
    } else {
      setState(() {
        _isLoading = false;
      });
      _showConfirmation(false, "Erreur de récupération du token");
    }
  }

  void _showConfirmation(bool success, String message) {
    setState(() {
      _showSaveConfirmation = true;
      _saveSuccess = success;
      _saveMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSaveConfirmation = false;
        });
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (_userId == null) return;

    try {
      final userData = await Api.fetchUserData(_userId!);
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _phoneController.text = userData['phone'].toString() ?? '';
        _addressController.text = userData['adresse'] ?? '';
        _imageUrl = userData['imageUrl'];
        _isLoading = false;
        print(_imageUrl);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showConfirmation(false, "Erreur lors du chargement: $e");
    }
  }

  Future<void> _saveChanges() async {
    if (_userId == null) return;

    // Validation mot de passe
    if (_newpasswController.text.isNotEmpty &&
        _actuelpasswController.text.isEmpty) {
      _showConfirmation(false, "Veuillez saisir votre mot de passe actuel");
      return;
    }
    if (widget.isForcedUpdate && _newpasswController.text.isEmpty) {
      _showConfirmation(false, "Vous devez définir un nouveau mot de passe");
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Créez un Map avec uniquement les champs modifiés
      final Map<String, dynamic> updatedFields = {};

      // Vérifiez chaque champ pour les modifications
      final currentData = await Api.fetchUserData(_userId!);
      if (_nameController.text != (currentData['name'] ?? '')) {
        updatedFields['name'] = _nameController.text;
      }
      if (_emailController.text != (currentData['email'] ?? '')) {
        updatedFields['email'] = _emailController.text;
      }
      if (_phoneController.text != (currentData['phone']?.toString() ?? '')) {
        updatedFields['phone'] = _phoneController.text;
      }
      if (_addressController.text != (currentData['adresse'] ?? '')) {
        updatedFields['adresse'] = _addressController.text;
      }
      if (_newpasswController.text.isNotEmpty) {
        updatedFields['oldPassword'] = _actuelpasswController.text;
        updatedFields['newPassword'] = _newpasswController.text;
      }

      // Envoyez seulement si des modifications existent
      if (updatedFields.isNotEmpty || _selectedImage != null) {
        final response = await Api.updateProfile(
          _userId!,
          updatedFields,
          _selectedImage,
        );

        if (response['success']) {
          _showConfirmation(true, "Profil mis à jour");
          if (widget.isForcedUpdate) {
            // Rechargez le statut depuis le serveur
            final stillRequiresReset =
                await authService.checkPasswordResetStatus();
            print("stillrequired");
            print(stillRequiresReset);
            if (!stillRequiresReset && mounted) {
              await Future.delayed(const Duration(seconds: 2));
              Navigator.of(context).pushNamedAndRemoveUntil(
                entryPointScreenRoute,
                (Route<dynamic> route) => false,
              );
            } else {
              _showConfirmation(
                false,
                "Erreur: Le statut n'a pas été mis à jour",
              );
            }
          }

          _actuelpasswController.clear();
          _newpasswController.clear();
          await _fetchUserData();
        } else {
          _showConfirmation(
            false,
            response['message'] ?? "Échec de la mise à jour",
          );
        }
      } else {
        _showConfirmation(false, "Aucune modification détectée");
      }
    } catch (e) {
      _showConfirmation(false, "Erreur: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _getCustomInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      fillColor: Theme.of(context).cardColor,
      filled: true,
      hintStyle: lightInputDecorationTheme.hintStyle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black54, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black54, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 1,
                margin: const EdgeInsets.all(defaultPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child:
                                  _selectedImage != null
                                      ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      )
                                      : _imageUrl != null &&
                                          _imageUrl!.isNotEmpty
                                      ? Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Image(
                                            image: AssetImage(
                                              //"assets/images/login_light.png",
                                              "assets/images/USERNOIMAGE.png",
                                            ),
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : const Image(
                                        image: AssetImage(
                                          //"assets/images/login_light.png",
                                          "assets/images/USERNOIMAGE.png",
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: primaryColor,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Form(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _getCustomInputDecoration(
                                'Nom d\'utilisateur',
                                Icons.person,
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _emailController,
                              decoration: _getCustomInputDecoration(
                                'Email',
                                Icons.email,
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _getCustomInputDecoration(
                                'Numéro de téléphone',
                                Icons.phone,
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _addressController,
                              decoration: _getCustomInputDecoration(
                                'Adresse',
                                Icons.location_on,
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _actuelpasswController,
                              decoration: _getCustomInputDecoration(
                                'Mot de passe actuel',
                                Icons.lock_outline,
                              ),
                              validator: (value) {
                                if (_newpasswController.text.isNotEmpty &&
                                    value!.isEmpty) {
                                  return 'Ce champ est requis pour changer le mot de passe';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _newpasswController,
                              decoration: _getCustomInputDecoration(
                                'Nouveau mot de passe',
                                Icons.lock,
                              ),
                            ),
                            const SizedBox(height: defaultPadding * 2),
                          ],
                        ),
                      ),
                      if (_showSaveConfirmation)
                        Center(
                          child: ConfirmationCard(
                            isSuccess: _saveSuccess,
                            message: _saveMessage,
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          child: const Text("Sauvegarder"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
