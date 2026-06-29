import 'dart:convert';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/services/project_api.dart';
import 'package:Telnet/theme/input_decoration_theme.dart'; // Import du thème
import 'package:Telnet/services/api.dart'; // Import de l'API
import 'package:Telnet/services/token_service.dart';
import 'package:http/http.dart' as http;

class InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  bool isDescriptionEmpty = false;
  bool isQuantityEmpty = false;
  bool isUnitPriceEmpty = false;

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

class AddInvoiceManuelle extends StatefulWidget {
  final String? userId;
  const AddInvoiceManuelle({super.key, required this.userId});

  @override
  State createState() => _AddInvoiceManuelleState();
}

class _AddInvoiceManuelleState extends State<AddInvoiceManuelle> {
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

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

  List<InvoiceItem> _items = [];
  String? _selectedProjectId;
  List<Map<String, dynamic>> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects().then((_) async {
      final userData = await _fetchUserData();
      // Variable pour stocker les projets réorganisés si nécessaire
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
  }

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

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
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
      final projectApi = ProjectApi();
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

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  void _saveInvoice() async {
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

    final items =
        _items
            .where((item) => item.descriptionController.text.isNotEmpty)
            .map((item) => item.toMap())
            .toList();

    final invoiceData = {
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

    print("Données à envoyer à l'API:");
    print("--------------------------------");
    print("Numéro de facture (invoice_no): ${invoiceData['invoice_no']}");
    print("Date: ${invoiceData['date']}");
    print("Adresse (address): ${invoiceData['address']}");
    print("Devise: ${invoiceData['currency']}");
    print("Total: ${invoiceData['total']}");
    print("Fournisseur (company): ${invoiceData['company']}");
    print("ID Projet: ${invoiceData['projectId']}");
    print("Items:");

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

      showDialog(
        context: context,
        builder:
            (context) => ConfirmationCard(
              isSuccess: true,
              message: 'Facture enregistrée avec succès',
            ),
      ).then((_) => Navigator.pop(context, true));
    } catch (e) {
      print('Failed to save invoice: $e');

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

                    DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: InputDecoration(
                        labelText: 'Projet associé',
                        prefixIcon: const Icon(Icons.folder),
                        fillColor: lightInputDecorationTheme.fillColor,
                        filled: lightInputDecorationTheme.filled,
                        border: lightInputDecorationTheme.border,
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                        errorText: _isProjectEmpty ? 'Projet requis' : null,
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
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
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
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                        errorText: _isDateEmpty ? 'Date requise' : null,
                      ),
                      onTap: () async {
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
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                        errorText:
                            _isCompanyEmpty ? 'Fournisseur requis' : null,
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
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                        errorText:
                            _isTotalEmpty ? 'Montant total requis' : null,
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
                            prefixIcon: const Icon(Icons.currency_exchange),
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
                                _isCurrencyEmpty ? 'Devise requise' : null,
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
                        enabledBorder: lightInputDecorationTheme.enabledBorder,
                        focusedBorder: lightInputDecorationTheme.focusedBorder,
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        errorStyle: TextStyle(color: Colors.red),
                        errorText: _isAddressEmpty ? 'Adresse requise' : null,
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
                                  prefixIcon: const Icon(Icons.description),
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
                                      item.isDescriptionEmpty
                                          ? 'Description requise'
                                          : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    item.isDescriptionEmpty = value.isEmpty;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.quantityController,
                                      decoration: InputDecoration(
                                        labelText: 'Quantité',
                                        prefixIcon: const Icon(Icons.numbers),
                                        fillColor:
                                            lightInputDecorationTheme.fillColor,
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
                                            item.isQuantityEmpty
                                                ? 'Quantité requise'
                                                : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          item.isQuantityEmpty = value.isEmpty;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: item.unitPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Prix unitaire',
                                        prefixIcon: const Icon(
                                          Icons.price_change,
                                        ),
                                        fillColor:
                                            lightInputDecorationTheme.fillColor,
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
                                            item.isUnitPriceEmpty
                                                ? 'Prix unitaire requis'
                                                : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          item.isUnitPriceEmpty = value.isEmpty;
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

                    // Bouton Ajouter un article en bas de la liste
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
