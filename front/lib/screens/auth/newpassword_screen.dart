import 'package:flutter/material.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/constants.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const NewPasswordScreen({Key? key, required this.email, required this.code})
    : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  bool _obscurePassword = false;
  bool _obscureConfirmPassword = false;

  Future<void> _resetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _message = "Les mots de passe ne correspondent pas";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final response = await Api.verifyForgotPasswordCode(
        widget.email,
        widget.code,
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

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: Text("Nouveau mot de passe")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 40.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Définir un nouveau mot de passe",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: defaultPadding),
                    Text(
                      "Pour ${widget.email}",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: defaultPadding * 2),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Nouveau mot de passe",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    SizedBox(height: defaultPadding),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirmer le mot de passe",
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                      ),
                    ),
                    SizedBox(height: defaultPadding * 2),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _resetPassword,
                          child: Text("Enregistrer"),
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
