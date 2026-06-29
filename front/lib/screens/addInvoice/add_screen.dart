import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Telnet/screens/addInvoice/shimmerbuttom.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Telnet/screens/addInvoice/camera_screen.dart'
    if (dart.library.html) 'package:Telnet/screens/addInvoice/web_stubs/camera_stub.dart';

class AddScreen extends StatefulWidget {
  final String? userId;
  const AddScreen({super.key, required this.userId});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  int? _currentProjectStatus;
  bool _isLoading = true;
  bool _showErrorCard = false;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_userId == null) return;

    try {
      final userData = await Api.fetchUserData(_userId!);
      setState(() {
        _currentProjectStatus = userData['currentProjectStatus'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("Erreur lors du chargement: $e");
    }
  }

  void _showError(String message) {
    setState(() {
      _showErrorCard = true;
      _errorMessage = message;
    });

    // Masquer la carte après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showErrorCard = false;
        });
      }
    });
  }

  // Navigation vers la caméra personnalisée
  void _navigateToCameraScreen() {
    if (kIsWeb) {
      return;
    }

    if (_currentProjectStatus == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(userId: widget.userId),
        ),
      );
    } else {
      _showError(
        "Ce projet est déjà terminé. Vous ne pouvez plus ajouter de facturation.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              "Souhaitez-vous ajouter une facture ?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 60),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  children: [
                                    ShimmerButton(
                                      text: "",
                                      icon: CupertinoIcons.camera,
                                      isRound: true,
                                      width: 130,
                                      height: 130,
                                      level: ShimmerLevel.level2,
                                      effect: ShimmerEffect.pulse,
                                      onPressed: _navigateToCameraScreen,
                                      showTextShine: false,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
            ),
            if (_showErrorCard)
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: ConfirmationCard(
                  isSuccess: false,
                  message: _errorMessage ?? "Une erreur est survenue",
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationCard extends StatelessWidget {
  final bool isSuccess;
  final String message;

  const ConfirmationCard({
    super.key,
    required this.isSuccess,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
