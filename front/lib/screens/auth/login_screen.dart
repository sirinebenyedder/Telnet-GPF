import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:Telnet/route/route_constants.dart';
import '../../forms/login_form.dart';
import '../../theme/login_theme.dart';
import 'package:Telnet/route/screen_export.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late FocusNode _emailFocusNode;
  late FocusNode _passwordFocusNode;
  bool _showEmailError = false;
  bool _isLoading = false;
  String _message = '';
  bool _obscurePassword =
      true; // Nouvel état pour masquer/afficher le mot de passe

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword; // Inverse l'état
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void Hi() {
    print("hii");
  }

  void loginUser() async {
    if (_formKey.currentState!.validate()) {
      print("Validation réussie");

      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      print("Email: $email, Password: $password");

      try {
        final response = await Api.auth({"email": email, "password": password});

        if (response["success"]) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            entryPointScreenRoute,
            ModalRoute.withName(logInScreenRoute),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response["message"]),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print("Exception attrapée: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Une erreur inattendue est survenue"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print("Validation échouée");
    }
  }

  Future<void> _sendForgotPasswordCode() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await Api.sendForgotPasswordCode(
        _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _message = response["message"];
      });

      if (response["success"]) {
        // Naviguer vers l'écran de vérification du code
        Navigator.pushNamed(
          context,
          newVerifyCodeScreenRouter,
          arguments:
              _emailController.text.trim(), // Passer l'email comme argument
        );
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = "Une erreur s'est produite. Veuillez réessayer.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message), backgroundColor: Colors.red),
      );
    }
  }

  void _handleForgotPassword() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez saisir votre email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérification basique du format email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veuillez saisir un email valide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Réinitialisation du mot de passe"),
            content: Text(
              "Un code de réinitialisation sera envoyé à $email. Continuer ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Annuler"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _sendForgotPasswordCode();
                },
                child: Text("Confirmer", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: loginTheme.scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Align(
                  alignment: AlignmentDirectional(-1, -1),
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Color(0x334B39EF),
                      borderRadius: BorderRadius.circular(90),
                    ),
                    alignment: AlignmentDirectional(0.8, 0.3),
                    child: Align(
                      alignment: AlignmentDirectional(-0.99, -0.96),
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Color(0x334B39EF),
                          borderRadius: BorderRadius.circular(90),
                        ),
                        alignment: AlignmentDirectional(0.8, 0.3),
                        child: Align(
                          alignment: AlignmentDirectional(-0.74, -0.93),
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Color(0x334B39EF),
                              borderRadius: BorderRadius.circular(90),
                            ),
                            alignment: AlignmentDirectional(0.8, 0.3),
                            child: Align(
                              alignment: AlignmentDirectional(-0.44, -0.86),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Color(0x334B39EF),
                                  borderRadius: BorderRadius.circular(90),
                                ),
                                alignment: AlignmentDirectional(0.8, 0.3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Image sur la moitié droite (uniquement pour les écrans larges)
                if (isLargeScreen)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2,
                      child: Lottie.asset(
                        'assets/lottie/Animation.json',
                        fit: BoxFit.cover,
                        repeat: true, // Boucle l'animation
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional(-2.01, -12.39),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      MediaQuery.of(context).size.width < 600 ? 24.0 : 100.0,
                      MediaQuery.of(context).size.width < 600 ? 50.0 : 80.0,
                      MediaQuery.of(context).size.width < 600 ? 24.0 : 80.0,
                      24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0, 0),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              4,
                              MediaQuery.of(context).size.width < 600
                                  ? 15.0
                                  : 7.0,
                              MediaQuery.of(context).size.width < 600
                                  ? 4.0
                                  : 700.0,
                              0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional(-1, -1),
                                  child: Text(
                                    'Se connecter',
                                    style: loginTheme.textTheme.displaySmall,
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(-1, 0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0,
                                      20,
                                      0,
                                      15,
                                    ),
                                    child: Text(
                                      'Bienvenue dans votre espace de travail!',
                                      style: loginTheme.textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                                LoginForm(
                                  formKey: _formKey,
                                  emailController: _emailController,
                                  passwordController: _passwordController,
                                  emailFocusNode: _emailFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  emailValidator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre login';
                                    }
                                    return null;
                                  },
                                  passwordValidator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer votre mot de passe';
                                    }
                                    return null;
                                  },
                                  obscurePassword: _obscurePassword,
                                  togglePasswordVisibility:
                                      _togglePasswordVisibility,
                                ),

                                Align(
                                  alignment: AlignmentDirectional(0, 1),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                      0,
                                      50,
                                      0,
                                      0,
                                    ),
                                    child: Column(
                                      children: [
                                        // Bouton "Mot de passe oublié"
                                        Align(
                                          alignment: AlignmentDirectional(
                                            1,
                                            0,
                                          ), // Aligner à droite
                                          child: TextButton(
                                            onPressed: _handleForgotPassword,
                                            child: Text(
                                              "Mot de passe oublié ?",
                                              style: TextStyle(
                                                color:
                                                    loginTheme
                                                        .primaryColor, // Couleur du texte
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Message d'erreur sous le bouton
                                        if (_showEmailError)
                                          Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              "Veuillez saisir votre login",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        SizedBox(
                                          height: 20,
                                        ), // Espacement entre les boutons
                                        ElevatedButton(
                                          onPressed: loginUser,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                loginTheme.primaryColor,
                                            padding: EdgeInsets.all(8),
                                            minimumSize: Size(
                                              MediaQuery.of(context).size.width,
                                              50,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                          ),
                                          child: const Text(
                                            "Se connecter",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
