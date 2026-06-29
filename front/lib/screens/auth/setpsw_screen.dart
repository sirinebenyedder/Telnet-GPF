import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SetPasswordScreen extends StatefulWidget {
  final String token;

  const SetPasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  _SetPasswordScreenState createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('http://VOTRE_IP_BACKEND:3000/activate-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': widget.token,
          'password': _passwordController.text,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mot de passe défini avec succès!')),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Erreur inconnue';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Définir votre mot de passe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 8) {
                    return 'Le mot de passe doit contenir au moins 8 caractères';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmez le mot de passe',
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPassword,
                child:
                    _isLoading
                        ? CircularProgressIndicator()
                        : Text('Enregistrer le mot de passe'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
