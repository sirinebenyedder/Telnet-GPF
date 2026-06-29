import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:Telnet/constants.dart';
import 'package:intl/intl.dart';
import 'package:Telnet/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Telnet/screens/onbording/components/response_card.dart';
import 'dart:async';

class AddProjectCard extends StatefulWidget {
  final String titleText;
  final VoidCallback? onBackPressed;
  final Function(bool)? onRequestComplete;

  const AddProjectCard({
    super.key,
    required this.titleText,
    this.onBackPressed,
    this.onRequestComplete,
  });

  @override
  State<AddProjectCard> createState() => _AddProjectCardState();
}

class _AddProjectCardState extends State<AddProjectCard> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final _countryController = TextEditingController();
  final List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());
  String _selectedCurrency = 'EUR';
  String? _secondaryCurrency;
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  bool _showConfirmation = false;
  bool _requestSuccess = false;
  String _confirmationMessage = '';
  List<String> _allCountries = [];
  List<String> _filteredCountries = [];
  Timer? _debounceTimer;
  // Ajoutez cette propriété dans votre classe d'état
  Map<String, String> _countryCurrencies = {};
  @override
  void initState() {
    super.initState();
    _logTokenInfo();
    // _fetchCountries();
    _countryController.addListener(_onCountrySearchChanged);
  }

  Future<void> _logTokenInfo() async {
    try {
      final tokenData = await authService.LoadToken();
      print('TOKEN: ${tokenData['authToken']}');
    } catch (e) {
      print('ERROR GETTING TOKEN: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _countryController.dispose();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /* void _onCountrySearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_countryController.text.length >= 2) {
        _filterCountries(_countryController.text);
      } else {
        setState(() {
          _filteredCountries = [];
        });
      }
    });
  }*/

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries =
          _allCountries
              .where(
                (country) =>
                    country.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  Future<void> _fetchCountries(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/project/countries?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Créer une map pour stocker les paires nom/devise
        final Map<String, String> countryToCurrency = {};
        final List<String> countryNames = [];

        // Extraire les noms et les devises
        for (var item in data) {
          final String name = item['nom'] as String;
          final String? currency = item['currencies'] as String?;

          countryNames.add(name);

          // Stocker la paire nom/devise si la devise est disponible
          if (currency != null) {
            countryToCurrency[name] = currency;
          }
        }

        setState(() {
          _allCountries = countryNames;
          _filteredCountries = _allCountries; // Mettre à jour les pays filtrés
          _countryCurrencies = countryToCurrency; // Sauvegarder les devises
        });
        print(data);
        print('Pays chargés: $_allCountries');
        print('Devises chargées: $_countryCurrencies');
      }
    } catch (e) {
      print('Erreur: $e');
      setState(() {
        _allCountries = [];
        _filteredCountries = [];
        _countryCurrencies = {};
      });
    }
  }

  Future<void> _fetchCurrencyForCountry(String countryName) async {
    try {
      final tokenData = await authService.LoadToken();
      final token = tokenData['authToken'];

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/project/getcurrencypay?name=${Uri.encodeComponent(countryName)}',
        ),
        //headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _secondaryCurrency = data['currency'];
        });
      } else {
        throw Exception('Failed to load currency');
      }
    } catch (e) {
      print('Error fetching currency: $e');
      setState(() {
        _secondaryCurrency = '';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        controllers[1].text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitProjectRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _showConfirmation = false;
    });

    try {
      final tokenData = await authService.LoadToken();
      final token = tokenData['authToken'];

      final requestData = {
        'requestType': 'PROJECT_CREATION',
        'message': 'Demande de création de projet: ${controllers[0].text}',
        'metadata': {
          'projectName': controllers[0].text,
          'startDate': controllers[1].text,
          'budget': controllers[2].text,
          'currency': _selectedCurrency,
          'secondaryCurrency': _secondaryCurrency,
          'country': _countryController.text,
        },
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/RequestResponse/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        _showConfirmationMessage(true, 'Demande envoyée avec succès');
        if (widget.onRequestComplete != null) {
          widget.onRequestComplete!(true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        _showConfirmationMessage(false, errorMessage);
        if (widget.onRequestComplete != null) {
          widget.onRequestComplete!(false);
        }
      }
    } catch (e) {
      _showConfirmationMessage(false, 'Échec de l\'envoi: ${e.toString()}');
      if (widget.onRequestComplete != null) {
        widget.onRequestComplete!(false);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showConfirmationMessage(bool success, String message) {
    setState(() {
      _showConfirmation = true;
      _requestSuccess = success;
      _confirmationMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfirmation = false;
        });
      }
    });
  }

  void _onCountrySearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _countryController.text;
      if (query.length >= 2) {
        _fetchCountries(query);
      } else {
        setState(() {
          _filteredCountries = [];
        });
      }
    });
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required int index,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: defaultPadding),
      child: TextFormField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: theme.cardColor,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          if (label.contains('Budget') && double.tryParse(value) == null) {
            return 'Montant invalide';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.all(defaultPadding),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.titleText,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Inter Tight',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'Nom du projet',
                          icon: Icons.work_outline,
                          index: 0,
                        ),
                        _buildTextField(
                          label: 'Date de début',
                          icon: Icons.calendar_today,
                          index: 1,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        _buildTextField(
                          label: 'Budget',
                          icon: Icons.attach_money,
                          index: 2,
                          keyboardType: TextInputType.number,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: 'Devise principale',
                            prefixIcon: const Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          items:
                              ['EUR', 'USD'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (mounted) {
                              setState(() {
                                _selectedCurrency = newValue!;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: defaultPadding),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'Pays',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                                hintText: 'Commencez à taper pour rechercher',
                                suffixIcon:
                                    _countryController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _countryController.clear();
                                              _filteredCountries = [];
                                            });
                                          },
                                        )
                                        : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez sélectionner un pays';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _onCountrySearchChanged();
                              },
                            ),
                            if (_filteredCountries.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  maxHeight: 150,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _filteredCountries.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(_filteredCountries[index]),
                                      /*onTap: () {
                                        setState(() {
                                          _countryController.text =
                                              _filteredCountries[index];
                                          _filteredCountries = [];
                                         _fetchCurrencyForCountry(
                                            _countryController.text,
                                          );
                                        });
                                        FocusScope.of(context).unfocus();
                                      },*/
                                      onTap: () {
                                        setState(() {
                                          _countryController.text =
                                              _filteredCountries[index];
                                          _filteredCountries = [];

                                          // Utilisation directe de la devise si disponible
                                          _secondaryCurrency =
                                              _countryCurrencies[_countryController
                                                  .text];

                                          // Fallback API si nécessaire
                                          if (_secondaryCurrency == null) {
                                            _fetchCurrencyForCountry(
                                              _countryController.text,
                                            );
                                          }
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: defaultPadding),
                        TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Devise secondaire',
                            prefixIcon: const Icon(Icons.currency_exchange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          controller: TextEditingController(
                            text: _secondaryCurrency,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _submitProjectRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : Text(
                                    'Envoyer la demande',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showConfirmation)
            Positioned.fill(
              child: Center(
                child: ConfirmationCard(
                  isSuccess: _requestSuccess,
                  message: _confirmationMessage,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
