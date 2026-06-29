import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/constants.dart';
import 'package:Telnet/route/screen_export.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({Key? key, required this.email}) : super(key: key);

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final int _codeLength = 6;
  final List<FocusNode> _focusNodes = [];
  final List<TextEditingController> _controllers = [];
  bool _isLoading = false;
  bool _isResendingCode = false;
  int _resendWaitTime = 0;
  String _message = '';

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs et focus nodes pour chaque chiffre
    for (int i = 0; i < _codeLength; i++) {
      _focusNodes.add(FocusNode());
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Obtenir le code complet à partir des contrôleurs
  String _getCompleteCode() {
    return _controllers.map((controller) => controller.text).join();
  }

  // Vérifier si tous les champs sont remplis
  bool _isCodeComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  // Gérer la suppression et passer au champ précédent
  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      // Déplacer le focus au champ précédent
      _focusNodes[index - 1].requestFocus();
    }
  }

  // Fonction pour renvoyer le code
  Future<void> _resendCode() async {
    if (_isResendingCode || _resendWaitTime > 0) {
      return;
    }

    setState(() {
      _isResendingCode = true;
      _message = '';
    });

    try {
      // Utiliser la fonction existante pour renvoyer le code
      final response = await Api.sendForgotPasswordCode(widget.email);

      setState(() {
        _isResendingCode = false;
        _message = response["message"];

        if (response["success"]) {
          _resendWaitTime = 60; // 60 secondes d'attente
          // Démarrer le compte à rebours
          _startResendTimer();
        }
      });

      if (response["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() {
        _isResendingCode = false;
        _message = "Erreur lors de l'envoi du code. Veuillez réessayer.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message), backgroundColor: Colors.red),
      );
    }
  }

  // Démarrer le compte à rebours pour le bouton de renvoi
  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      setState(() {
        if (_resendWaitTime > 0) {
          _resendWaitTime--;
        }
      });

      return _resendWaitTime > 0;
    });
  }

  Future<void> _verifyCode() async {
    if (!_isCodeComplete()) {
      setState(() {
        _message = 'Veuillez entrer le code complet à 6 chiffres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final code = _getCompleteCode();
      final response = await Api.verifyCode(widget.email, code);
      print("Réponse du serveur: ${response.toString()}"); // Debug

      setState(() {
        _isLoading = false;
        _message = response["message"];
      });

      if (response["success"]) {
        debugPrint(
          "Arguments pour navigation: email=${widget.email}, code=$code",
        );
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          newPasswordScreenRoute,
          arguments: {'email': widget.email, 'code': code},
        );
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
      appBar: AppBar(title: const Text("Vérification du code")),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: EdgeInsets.all(isLargeScreen ? 40.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Vérification du code",
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: defaultPadding),
                    Text(
                      "Un code de vérification a été envoyé à ${widget.email}",
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: defaultPadding * 2),

                    // Champs de code PIN stylés
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_codeLength, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildCodeDigitField(index),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: defaultPadding * 2),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _verifyCode,
                          child: const Text("Vérifier le code"),
                        ),
                    const SizedBox(height: defaultPadding),
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
                    const SizedBox(height: defaultPadding),
                    TextButton.icon(
                      onPressed:
                          (_resendWaitTime > 0 || _isResendingCode)
                              ? null
                              : _resendCode,
                      icon:
                          _isResendingCode
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.refresh),
                      label: Text(
                        _resendWaitTime > 0
                            ? "Renvoyer le code (${_resendWaitTime}s)"
                            : "Je n'ai pas reçu de code",
                      ),
                      style: ButtonStyle(
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.disabled)) {
                                return Colors.grey;
                              }
                              return Theme.of(context).primaryColor;
                            }),
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

  Widget _buildCodeDigitField(int index) {
    // Déterminer la taille en fonction de l'écran
    final bool isSmallScreen = MediaQuery.of(context).size.width < 400;
    final double fieldSize = isSmallScreen ? 40 : 50;
    final double fontSize = isSmallScreen ? 20 : 24;

    return Container(
      width: fieldSize,
      height: fieldSize + 10, // Un peu plus haut que large
      decoration: BoxDecoration(
        color:
            _focusNodes[index].hasFocus
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              _focusNodes[index].hasFocus
                  ? Theme.of(context).primaryColor
                  : Colors.grey.withOpacity(0.3),
          width: _focusNodes[index].hasFocus ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          errorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < _codeLength - 1) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              if (_isCodeComplete()) {
                _verifyCode();
              }
            }
          } else {
            _handleBackspace(index);
          }
        },
        onTap: () {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }
}
