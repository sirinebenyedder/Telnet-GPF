import 'dart:convert';

import 'package:Telnet/screens/addInvoice/camera_screen.dart';
import 'package:Telnet/screens/addInvoice/manuel_invoice.dart';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:Telnet/services/api.dart';
import 'package:Telnet/services/project_api.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:Telnet/theme/input_decoration_theme.dart';

import 'package:flutter/material.dart';
import 'package:Telnet/theme/input_decoration_theme.dart';

class InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  bool isDescriptionEmpty = false;
  bool isQuantityEmpty = false;
  bool isUnitPriceEmpty = false;

  // Convertir l'item en map pour l'API
  Map<String, dynamic> toMap() {
    return {
      'description': descriptionController.text,
      'quantity': quantityController.text,
      'unit_price':
          unitPriceController.text.isNotEmpty
              ? double.parse(unitPriceController.text)
              : 0,
    };
  }
}

class AddInvoiceML extends StatefulWidget {
  final String? userId;
  final File initialImage;

  const AddInvoiceML({
    super.key,
    required this.userId,
    required this.initialImage,
  });

  @override
  State createState() => _AddInvoiceMLState();
}

class _AddInvoiceMLState extends State<AddInvoiceML> {
  // Contrôleurs pour les champs du formulaire alignés avec le schéma
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  // État des champs pour la validation visuelle
  bool _isInvoiceNoEmpty = false;
  bool _isDateEmpty = false;
  bool _isAddressEmpty = false;
  bool _isCurrencyEmpty = false;
  bool _isTotalEmpty = false;
  bool _isCompanyEmpty = false;
  bool _isProjectEmpty = false;

  String? _selectedCurrency;
  List<String> _availableCurrencies = [];
  bool _isLoadingCurrencies = false;
  bool _isProcessingImage =
      true; // Pour indiquer le traitement initial de l'image

  // Liste des items de facture (dynamique)
  List<InvoiceItem> _items = [];

  // Variable pour le projet (requis selon le schéma)
  String? _selectedProjectId;
  List<Map<String, dynamic>> _projects =
      []; // Pour stocker la liste des projets

  // Variable pour stocker l'image capturée
  File? _capturedImage;

  // Variable pour stocker l'ID de l'image temporaire
  String? _tempImageId;

  // Variable pour savoir si la facture a été enregistrée
  bool _isInvoiceSaved = false;

  @override
  void initState() {
    super.initState();
    _capturedImage = widget.initialImage;

    // Montrer un dialogue de chargement pendant l'analyse ML
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      const Text(
                        "Analyse de la facture en cours...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });

    _loadProjects().then((_) async {
      // Après avoir chargé les projets, récupérer les données utilisateur
      final userData = await _fetchUserData();

      List<Map<String, dynamic>> organizedProjects = [..._projects];
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
      print(userData);
      if (userData != null && userData['currentProject'] != null) {
        // Prendre l'ID du currentProject (qui est un objet)
        final currentProjectId = userData['currentProject']['_id'];

        // Vérifier si le projet courant existe dans la liste
        final currentProjectIndex = _projects.indexWhere(
          (p) => p['_id'] == currentProjectId,
        );

        print('currentProjectIndex');
        print(currentProjectIndex);

        if (currentProjectIndex != -1) {
          // Le projet courant existe, le sélectionner
          setState(() {
            _selectedProjectId = userData['currentProject']['_id'];
            _isProjectEmpty = false;
            print('ooow');
            print(_selectedProjectId);
          });
        } else if (_projects.isNotEmpty) {
          // sélectionner le premier
          setState(() {
            _selectedProjectId = _projects[0]['_id'];
            _isProjectEmpty = false;
          });
        } else {
          setState(() {
            _isProjectEmpty = true;
          });
        }
      } else if (_projects.isNotEmpty) {
        setState(() {
          _selectedProjectId = _projects[0]['_id'];
          _isProjectEmpty = false;
        });
      } else {
        setState(() {
          _isProjectEmpty = true;
        });
      }

      // Charger les devises une fois le projet sélectionné
      if (_selectedProjectId != null) {
        await _fetchAvailableCurrencies(_selectedProjectId!);
      }
    });

    _addItem();

    // Process de l'image pour ML
    _processInitialImage();
  }

  Future<void> _processInitialImage() async {
    try {
      // Envoyer l'image au serveur pour un enregistrement temporaire et analyse ML
      final result = await Api.uploadImageInvioce(
        widget.initialImage,
        oldTempImageId: _tempImageId,
      );

      // Stocker l'ID de l'image temporaire
      setState(() {
        _tempImageId = result['tempImageId'];
        _isProcessingImage = false;
      });

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Remplir les champs du formulaire avec les données extraites
      setState(() {
        // Mettre à jour les valeurs et l'état de validation des champs
        _invoiceNoController.text = result['invoiceData']['invoice_no'] ?? '';
        _isInvoiceNoEmpty = _invoiceNoController.text.isEmpty;

        _dateController.text = result['invoiceData']['date'] ?? '';
        _isDateEmpty = _dateController.text.isEmpty;

        _addressController.text =
            result['invoiceData']['address_country'] ?? '';
        _isAddressEmpty = _addressController.text.isEmpty;

        _currencyController.text = result['invoiceData']['currency'] ?? '';
        _isCurrencyEmpty = _currencyController.text.isEmpty;

        _totalController.text = result['invoiceData']['total'] ?? '';
        _isTotalEmpty = _totalController.text.isEmpty;

        _companyController.text = result['invoiceData']['company'] ?? '';
        _isCompanyEmpty = _companyController.text.isEmpty;

        // Si des items sont détectés
        if (result['invoiceData']['items'] != null &&
            result['invoiceData']['items'].isNotEmpty) {
          // Effacer les items existants
          _items.clear();

          // Ajouter les nouveaux items détectés
          for (var item in result['invoiceData']['items']) {
            final newItem = InvoiceItem();
            newItem.descriptionController.text = item['description'] ?? '';
            newItem.isDescriptionEmpty =
                newItem.descriptionController.text.isEmpty;

            newItem.quantityController.text = item['quantity'] ?? '';
            newItem.isQuantityEmpty = newItem.quantityController.text.isEmpty;

            newItem.unitPriceController.text =
                item['unit_price']?.toString() ?? '';
            newItem.isUnitPriceEmpty = newItem.unitPriceController.text.isEmpty;

            _items.add(newItem);
          }
        }

        // Si aucun item n'a été détecté, ajouter un item vide
        if (_items.isEmpty) {
          _addItem();
        }
      });
    } catch (e) {
      print(
        'Échec du scan - Fonctionnalité non disponible',
      ); // Message simplifié
      if (context.mounted) {
        // Fermer d'abord le dialogue de chargement
        Navigator.pop(context);

        // Puis rediriger vers la page manuelle
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AddInvoiceManuelle(userId: widget.userId),
          ),
        );

        // Afficher un message à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le scan automatique a échoué. Veuillez saisir les informations manuellement.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Ajouter un nouvel item vide
  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  // Fetch le projet current
  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      final userData = await Api.fetchUserData(widget.userId!);
      return userData;
    } catch (e) {
      print('Failed to fetch user data: $e');
      return null;
    }
  }

  Future<List<String>> _getProjectCurrencies(String projectId) async {
    try {
      final tokenData = await authService.LoadToken();
      final token = tokenData['authToken'];

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/invoices/$projectId/currenciesperproject',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['currencies']);
      } else {
        throw Exception(
          'Failed to load currencies - Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getProjectCurrencies: $e');
      rethrow;
    }
  }

  Future<void> _fetchAvailableCurrencies(String projectId) async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    try {
      final currencies = await _getProjectCurrencies(projectId);
      setState(() {
        _availableCurrencies = currencies;
        if (_availableCurrencies.isNotEmpty) {
          _selectedCurrency = _availableCurrencies.first;
          _currencyController.text = _selectedCurrency!;
          _isCurrencyEmpty = false;
        } else {
          _isCurrencyEmpty = true;
        }
      });
    } catch (e) {
      print('Error fetching currencies: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des devises: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrencies = false;
        });
      }
    }
  }

  // Supprimer un item à l'index spécifié
  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      // Si c'est le dernier item, on le vide plutôt que de le supprimer
      setState(() {
        _items[0].descriptionController.clear();
        _items[0].isDescriptionEmpty = true;
        _items[0].quantityController.clear();
        _items[0].isQuantityEmpty = true;
        _items[0].unitPriceController.clear();
        _items[0].isUnitPriceEmpty = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Au moins un article doit être présent')),
      );
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projectApi = ProjectApi(); // Créer une instance
      List<Map<String, dynamic>> projectsList = await projectApi
          .getProjectsByManagerId(widget.userId!);
      final activeProjects =
          projectsList.where((p) => p['status'] == 2).toList();

      setState(() {
        _projects = activeProjects;
        if (_projects.isNotEmpty) {
          _selectedProjectId = _projects[0]['_id'];
          _isProjectEmpty = false;
        } else {
          _isProjectEmpty = true;
        }
      });
    } catch (e) {
      print('Failed to load projects: $e');
      setState(() {
        _isProjectEmpty = true;
      });
    }
  }

  // Fonction pour ouvrir la caméra et prendre une photo
  /*Future<void> _openCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      // Afficher un indicateur de chargement
      // S'assurer que l'indicateur global ne s'affiche pas
      setState(() {
        _isProcessingImage = false;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      "Analyse s...",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Supprimer l'ancienne image temporaire si elle existe
      if (_tempImageId != null) {
        print('Deleting old temp image: $_tempImageId');
        await Api.deleteTempImage(_tempImageId!);
      }

      // Envoyer la nouvelle image au serveur pour un enregistrement temporaire
      print('Uploading new temp image...');
      print('mechya l node bich yab3athha li flask');
      final result = await Api.uploadImageInvioce(
        File(pickedFile.path),
        oldTempImageId: _tempImageId,
      );
      print('Upload result: $result');

      // Fermer le dialogue de chargement
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Stocker l'ID de la nouvelle image temporaire
      setState(() {
        _tempImageId = result['tempImageId'];
        _capturedImage = File(pickedFile.path);
      });

      // Remplir les champs du formulaire avec les données extraites
      setState(() {
        // Mettre à jour les valeurs et l'état de validation des champs
        _invoiceNoController.text = result['invoiceData']['number'] ?? '';
        _isInvoiceNoEmpty = _invoiceNoController.text.isEmpty;

        _dateController.text = result['invoiceData']['date'] ?? '';
        _isDateEmpty = _dateController.text.isEmpty;

        _addressController.text =
            result['invoiceData']['address_country'] ?? '';
        _isAddressEmpty = _addressController.text.isEmpty;

        _currencyController.text = result['invoiceData']['currency'] ?? '';
        _isCurrencyEmpty = _currencyController.text.isEmpty;

        _totalController.text = result['invoiceData']['total'] ?? '';
        _isTotalEmpty = _totalController.text.isEmpty;

        _companyController.text = result['invoiceData']['supplier'] ?? '';
        _isCompanyEmpty = _companyController.text.isEmpty;

        // Si des items sont détectés
        if (result['invoiceData']['items'] != null &&
            result['invoiceData']['items'].isNotEmpty) {
          // Effacer les items existants
          _items.clear();

          // Ajouter les nouveaux items détectés
          for (var item in result['invoiceData']['items']) {
            final newItem = InvoiceItem();
            newItem.descriptionController.text = item['description'] ?? '';
            newItem.isDescriptionEmpty =
                newItem.descriptionController.text.isEmpty;

            newItem.quantityController.text = item['quantity'] ?? '';
            newItem.isQuantityEmpty = newItem.quantityController.text.isEmpty;

            newItem.unitPriceController.text =
                item['unit_price']?.toString() ?? '';
            newItem.isUnitPriceEmpty = newItem.unitPriceController.text.isEmpty;

            _items.add(newItem);
          }

          // Si aucun item n'a été détecté, ajouter un item vide
          if (_items.isEmpty) {
            _addItem();
          }
        }
      });
    }
  }*/
  Future<void> _openCamera() async {
    // Naviguer vers CameraScreen et attendre le résultat (l'image capturée)
    final capturedImage = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(userId: widget.userId),
      ),
    );

    if (capturedImage != null) {
      // Mettre à jour l'état avec la nouvelle image
      setState(() {
        _capturedImage = capturedImage;
        _isProcessingImage = true;
      });

      // Traiter la nouvelle image
      await _processInitialImage();
    }
  }

  // Fonction pour enregistrer la facture
  void _saveInvoice() async {
    // Validation des champs obligatoires
    setState(() {
      _isInvoiceNoEmpty = _invoiceNoController.text.isEmpty;
      _isDateEmpty = _dateController.text.isEmpty;
      _isCompanyEmpty = _companyController.text.isEmpty;
      _isTotalEmpty = _totalController.text.isEmpty;
      _isCurrencyEmpty =
          _selectedCurrency == null || _selectedCurrency!.isEmpty;
      _isProjectEmpty = _selectedProjectId == null;

      for (var item in _items) {
        item.isDescriptionEmpty = item.descriptionController.text.isEmpty;
        item.isQuantityEmpty = item.quantityController.text.isEmpty;
        item.isUnitPriceEmpty = item.unitPriceController.text.isEmpty;
      }
    });

    // Vérifier si des champs obligatoires sont vides
    if (_isInvoiceNoEmpty ||
        _isDateEmpty ||
        _isCompanyEmpty ||
        _isTotalEmpty ||
        _isCurrencyEmpty ||
        _isProjectEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez remplir tous les champs obligatoires (en rouge)',
          ),
        ),
      );
      return;
    }

    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un projet')),
      );
      return;
    }

    // Préparer les items
    final items =
        _items
            .where((item) => item.descriptionController.text.isNotEmpty)
            .map((item) => item.toMap())
            .toList();

    final invoiceData = {
      'tempImageId': _tempImageId,
      'invoice_no': _invoiceNoController.text,
      'date': _dateController.text,
      'address': _addressController.text,
      'currency': _selectedCurrency ?? _currencyController.text,
      'total':
          _totalController.text.isNotEmpty
              ? double.parse(_totalController.text)
              : 0,
      'company': _companyController.text,
      'items': items,
      'projectId': _selectedProjectId,
    };

    // Afficher les données avant envoi
    print("Données à envoyer à l'API:");
    print("--------------------------------");
    print("TempImageId: ${invoiceData['tempImageId']}");
    print("Numéro de facture (invoice_no): ${invoiceData['invoice_no']}");
    print("Date: ${invoiceData['date']}");
    print("Adresse (address): ${invoiceData['address']}");
    print("Devise: ${invoiceData['currency']}");
    print("Total: ${invoiceData['total']}");
    print("Fournisseur (company): ${invoiceData['company']}");
    print("ID Projet: ${invoiceData['projectId']}");
    print("Items:");

    // Vérifier que items n'est pas null avant d'itérer
    if (invoiceData['items'] != null && invoiceData['items'] is List) {
      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        invoiceData['items'] as List,
      );
      for (var item in items) {
        print("  - Description: ${item['description']}");
        print("    Quantité: ${item['quantity']}");
        print("    Prix unitaire: ${item['unit_price']}");
      }
    } else {
      print("  Aucun item");
    }

    print("--------------------------------");

    try {
      final result = await Api.saveInvoice(invoiceData, widget.userId!);
      print('Invoice saved successfully: $result');
      setState(() {
        _isInvoiceSaved = true;
      });

      // Après l'enregistrement réussi:
      showDialog(
        context: context,
        builder:
            (context) => ConfirmationCard(
              isSuccess: true,
              message: 'Facture enregistrée avec succès',
            ),
      ).then((_) => Navigator.pop(context, true));

      // Naviguer en arrière après enregistrement réussi
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, true);
      });
    } catch (e) {
      print('Failed to save invoice: $e');
      // Afficher un message d'erreur
      showDialog(
        context: context,
        builder:
            (context) => ConfirmationCard(
              isSuccess: false,
              message: e.toString().replaceAll('Exception: ', ''),
            ),
      );
    }
  }

  @override
  void dispose() {
    // Supprimer l'image temporaire si elle existe et que la facture n'a pas été enregistrée
    if (_tempImageId != null && !_isInvoiceSaved) {
      print('Cleaning up temp image: $_tempImageId, saved: $_isInvoiceSaved');
      Api.deleteTempImage(_tempImageId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Ajouter une Facture",
          style: TextStyle(
            fontFamily: "PlusJakartaDisplay-Bold",
            fontSize: 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isProcessingImage
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section de capture d'image
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Photo de la facture",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child:
                                      _capturedImage != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.file(
                                              _capturedImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                          : const Center(
                                            child: Icon(
                                              Icons.camera_alt,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                          ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _openCamera,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section des informations principales
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Informations principales",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Sélection du projet
                            DropdownButtonFormField<String>(
                              value: _selectedProjectId,
                              decoration: InputDecoration(
                                labelText: 'Projet associé',
                                prefixIcon: const Icon(Icons.folder),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText:
                                    _isProjectEmpty ? 'Projet requis' : null,
                              ),
                              items:
                                  _projects.map((project) {
                                    // Mettre en évidence le projet courant
                                    final bool isCurrentProject =
                                        project['_id'] == _selectedProjectId;
                                    return DropdownMenuItem<String>(
                                      value: project['_id'],
                                      child: Text(
                                        project['name'],
                                        style: TextStyle(
                                          fontWeight:
                                              isCurrentProject
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) async {
                                setState(() {
                                  _selectedProjectId = value;
                                  _isProjectEmpty = false;
                                });
                                if (value != null) {
                                  await _fetchAvailableCurrencies(value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _invoiceNoController,
                              decoration: InputDecoration(
                                labelText: 'Numéro de Facture',
                                prefixIcon: const Icon(Icons.receipt),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText:
                                    _isInvoiceNoEmpty
                                        ? 'Numéro de facture requis'
                                        : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isInvoiceNoEmpty = value.isEmpty;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _dateController,
                              decoration: InputDecoration(
                                labelText: 'Date de Facturation',
                                prefixIcon: const Icon(Icons.calendar_today),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText: _isDateEmpty ? 'Date requise' : null,
                              ),
                              onTap: () async {
                                // Vous pouvez ajouter un sélecteur de date ici
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _dateController.text =
                                        "${picked.day}/${picked.month}/${picked.year}";
                                    _isDateEmpty = false;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _companyController,
                              decoration: InputDecoration(
                                labelText: 'Fournisseur',
                                prefixIcon: const Icon(Icons.business),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText:
                                    _isCompanyEmpty
                                        ? 'Fournisseur requis'
                                        : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isCompanyEmpty = value.isEmpty;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section détails financiers
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Détails financiers",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _totalController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Montant Total',
                                prefixIcon: const Icon(Icons.money),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText:
                                    _isTotalEmpty
                                        ? 'Montant total requis'
                                        : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isTotalEmpty = value.isEmpty;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            _isLoadingCurrencies
                                ? Center(child: CircularProgressIndicator())
                                : DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  decoration: InputDecoration(
                                    labelText: 'Devise',
                                    prefixIcon: const Icon(
                                      Icons.currency_exchange,
                                    ),
                                    fillColor:
                                        lightInputDecorationTheme.fillColor,
                                    filled: lightInputDecorationTheme.filled,
                                    border: lightInputDecorationTheme.border,
                                    enabledBorder:
                                        lightInputDecorationTheme.enabledBorder,
                                    focusedBorder:
                                        lightInputDecorationTheme.focusedBorder,
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.red),
                                    ),
                                    errorStyle: TextStyle(color: Colors.red),
                                    errorText:
                                        _isCurrencyEmpty
                                            ? 'Devise requise'
                                            : null,
                                  ),
                                  items:
                                      _availableCurrencies.map((currency) {
                                        return DropdownMenuItem<String>(
                                          value: currency,
                                          child: Text(currency),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCurrency = value;
                                      _isCurrencyEmpty = false;
                                    });
                                  },
                                ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                labelText: 'Adresse',
                                prefixIcon: const Icon(Icons.location_on),
                                fillColor: lightInputDecorationTheme.fillColor,
                                filled: lightInputDecorationTheme.filled,
                                border: lightInputDecorationTheme.border,
                                enabledBorder:
                                    lightInputDecorationTheme.enabledBorder,
                                focusedBorder:
                                    lightInputDecorationTheme.focusedBorder,
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                errorStyle: TextStyle(color: Colors.red),
                                errorText:
                                    _isAddressEmpty ? 'Adresse requise' : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _isAddressEmpty = value.isEmpty;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section articles avec bouton d'ajout
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Articles",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Liste des items
                            ..._items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                color: Colors.grey[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Article ${index + 1}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _removeItem(index),
                                            tooltip: "Supprimer cet article",
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: item.descriptionController,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                          prefixIcon: const Icon(
                                            Icons.description,
                                          ),
                                          fillColor:
                                              lightInputDecorationTheme
                                                  .fillColor,
                                          filled:
                                              lightInputDecorationTheme.filled,
                                          border:
                                              lightInputDecorationTheme.border,
                                          enabledBorder:
                                              lightInputDecorationTheme
                                                  .enabledBorder,
                                          focusedBorder:
                                              lightInputDecorationTheme
                                                  .focusedBorder,
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                          errorStyle: TextStyle(
                                            color: Colors.red,
                                          ),
                                          errorText:
                                              item.isDescriptionEmpty
                                                  ? 'Description requise'
                                                  : null,
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            item.isDescriptionEmpty =
                                                value.isEmpty;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  item.quantityController,
                                              decoration: InputDecoration(
                                                labelText: 'Quantité',
                                                prefixIcon: const Icon(
                                                  Icons.numbers,
                                                ),
                                                fillColor:
                                                    lightInputDecorationTheme
                                                        .fillColor,
                                                filled:
                                                    lightInputDecorationTheme
                                                        .filled,
                                                border:
                                                    lightInputDecorationTheme
                                                        .border,
                                                enabledBorder:
                                                    lightInputDecorationTheme
                                                        .enabledBorder,
                                                focusedBorder:
                                                    lightInputDecorationTheme
                                                        .focusedBorder,
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                errorStyle: TextStyle(
                                                  color: Colors.red,
                                                ),
                                                errorText:
                                                    item.isQuantityEmpty
                                                        ? 'Quantité requise'
                                                        : null,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  item.isQuantityEmpty =
                                                      value.isEmpty;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller:
                                                  item.unitPriceController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Prix unitaire',
                                                prefixIcon: const Icon(
                                                  Icons.price_change,
                                                ),
                                                fillColor:
                                                    lightInputDecorationTheme
                                                        .fillColor,
                                                filled:
                                                    lightInputDecorationTheme
                                                        .filled,
                                                border:
                                                    lightInputDecorationTheme
                                                        .border,
                                                enabledBorder:
                                                    lightInputDecorationTheme
                                                        .enabledBorder,
                                                focusedBorder:
                                                    lightInputDecorationTheme
                                                        .focusedBorder,
                                                errorBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                errorStyle: TextStyle(
                                                  color: Colors.red,
                                                ),
                                                errorText:
                                                    item.isUnitPriceEmpty
                                                        ? 'Prix unitaire requis'
                                                        : null,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  item.isUnitPriceEmpty =
                                                      value.isEmpty;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                            // Bouton  article louta
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text("Ajouter un article"),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Enregistrer
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer la facture',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
    );
  }
}
