import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';
import 'package:Telnet/services/project_api.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:flutter/services.dart';

class FinanceRequestCard extends StatefulWidget {
  final String titleText;
  final String userId; // ID du PM connecté
  const FinanceRequestCard({
    super.key,
    required this.titleText,
    required this.userId,
    String? currentProjectId,
  });

  @override
  State<FinanceRequestCard> createState() => _FinanceRequestCardState();
}

class _FinanceRequestCardState extends State<FinanceRequestCard> {
  final TextEditingController _amountController = TextEditingController();
  final ProjectApi _projectApi = ProjectApi();
  final AuthService _authService = AuthService();

  String? _selectedProjectId;
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);

    try {
      final List<Map<String, dynamic>> projects = await _projectApi
          .getProjectsByManagerId(widget.userId);
      final activeProjects = projects.where((p) => p['status'] == 2).toList();
      print("widget.userid");
      print(widget.userId);
      if (projects.isEmpty) {
        _showErrorSnackbar('Aucun projet trouvé pour ce manager');
      }

      setState(() => _projects = activeProjects);
    } catch (e) {
      _showErrorSnackbar('Erreur de chargement: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendBudgetRequest() async {
    if (_selectedProjectId == null) {
      _showErrorSnackbar('Veuillez sélectionner un projet');
      return;
    }

    if (_amountController.text.isEmpty) {
      _showErrorSnackbar('Veuillez entrer un montant');
      return;
    }
    // Validation que le montant est un nombre valide et positif
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount! <= 0) {
      _showErrorSnackbar('Le montant doit être positif');
      return;
    }

    setState(() => _isSending = true);

    try {
      await _projectApi.sendBudgetRequest(
        projectId: _selectedProjectId!,
        amount: double.parse(_amountController.text),
        userId: widget.userId,
      );

      _showSuccessSnackbar('Demande envoyée avec succès');
      _amountController.clear();
      setState(() => _selectedProjectId = null);
    } catch (e) {
      _showErrorSnackbar('Erreur lors de l\'envoi: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(defaultPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demande au Responsable Finance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Demande d\'ajout de budget pour un projet',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Liste déroulante des projets
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: InputDecoration(
                      labelText: 'Sélectionner un projet',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    items:
                        _projects.map<DropdownMenuItem<String>>((project) {
                          return DropdownMenuItem<String>(
                            value:
                                project['_id']
                                    ?.toString(), // Conversion explicite en String
                            child: Text(
                              project['name'] ??
                                  'Projet sans nom', // Valeur par défaut
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14.0),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProjectId = newValue;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Sélection obligatoire' : null,
                  ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant à ajouter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null) {
                    return 'Montant invalide';
                  }
                  if (amount <= 0) {
                    return 'Le montant doit être positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendBudgetRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      _isSending
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Envoyer la demande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
