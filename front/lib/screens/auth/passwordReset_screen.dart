import 'package:flutter/material.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/constants.dart';

class PasswordResetScreen extends StatefulWidget {
  final String email; // L'email récupéré depuis l'écran précédent

  const PasswordResetScreen({Key? key, required this.email}) : super(key: key);

  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false; // Pour gérer l'état de chargement
  String _message = ''; // Pour afficher les messages d'erreur/succès

  Future<void> _resetPassword() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await Api.verifyForgotPasswordCode(
        widget.email,
        _codeController.text.trim(),
        _newPasswordController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _message = response["message"];
      });

      if (response["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
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

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: Text("Réinitialiser le mot de passe")),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Masquer le clavier
        },
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
              ), // Largeur maximale du formulaire
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 40.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Réinitialisation du mot de passe",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: defaultPadding),
                    Text(
                      "Entrez le code de vérification envoyé à ${widget.email} et votre nouveau mot de passe.",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: defaultPadding * 2),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: "Code de vérification",
                        hintText: "Entrez le code à 6 chiffres",
                        border:
                            OutlineInputBorder(), // Pour un meilleur rendu visuel
                      ),
                    ),
                    SizedBox(height: defaultPadding),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe",
                        hintText: "Entrez votre nouveau mot de passe",
                        border:
                            OutlineInputBorder(), // Pour un meilleur rendu visuel
                      ),
                    ),
                    SizedBox(height: defaultPadding * 2),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _resetPassword,
                          child: Text("Valider"),
                        ),
                    SizedBox(height: defaultPadding),
                    if (_message.isNotEmpty)
                      Text(
                        _message,
                        style: TextStyle(
                          color:
                              _message.contains("succès")
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        textAlign: TextAlign.center,
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
