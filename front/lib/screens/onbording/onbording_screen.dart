import 'dart:async';
import 'package:Telnet/screens/onbording/widgets/pie_chart.dart';
import 'package:Telnet/screens/addInvoice/add_screen.dart';
import 'package:Telnet/screens/onbording/detailsfacture.dart';
import 'package:Telnet/services/project_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:Telnet/services/api.dart';
import 'package:Telnet/screens/onbording/project_screen.dart';
import 'components/page-translation.dart';

class Invoice {
  final String id;
  final String supplier;
  final double total;
  final DateTime date;
  final String invoiceNo;
  final String address;
  final String currency;
  final String projectName;
  final String? imageUrl;
  Invoice({
    required this.id,
    required this.supplier,
    required this.total,
    required this.date,
    required this.invoiceNo,
    required this.address,
    required this.currency,
    required this.projectName,
    this.imageUrl,
  });
}

class OnBordingScreen extends StatefulWidget {
  final String? userId;
  final String? userRole;
  final String? viewOnlyProject;
  const OnBordingScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.viewOnlyProject,
  });

  @override
  State<OnBordingScreen> createState() => _OnBordingScreenState();
}

class _OnBordingScreenState extends State<OnBordingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 1;
  int _itemsPerPage = 8;
  List<Invoice> _factures = [];
  final _pageController = PageController();
  bool _isPageControllerReady = false;
  bool _showSearchBar = false;
  bool _showFilterOptions = false;
  final _searchController = TextEditingController();
  String? _selectedFilter;
  bool _isLoading = false;
  //
  Map<String, dynamic>? _selectedProject;
  // late String projectId;
  // Filtres
  Map<String, dynamic>? _paginationInfo;
  DateTimeRange? _selectedDateRange;
  String? _selectedFournisseur;
  double? _minMontant;
  double? _maxMontant;
  Timer? _searchDebounce;

  late AnimationController _backpackAnimationController;
  late Animation<double> _backpackAnimation;
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _bounceAnimation;
  //
  String _currentProjectName = '';
  int? currentProjectStatus;

  //
  bool _isSelectionMode = false;
  Set<String> _selectedInvoices = Set<String>();
  bool get isViewOnly =>
      widget.viewOnlyProject != null || widget.userRole != 'PM';
  @override
  void initState() {
    super.initState();

    print(
      ' OnBordingScreen init with viewOnlyProject: ${widget.viewOnlyProject}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_loadFactures();
      if (widget.viewOnlyProject != null) {
        print(widget.viewOnlyProject);
        _loadFactures(projectId: widget.viewOnlyProject);
      } else {
        // Comportement normal
        _loadFactures();
      }
      setState(() {
        _isPageControllerReady = true;
      });
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticInOut),
    );

    // Pour l'effet de rebond
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.85),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.1),
        weight: 25,
      ),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel(); // la recherche partielle
    //_backpackAnimationController.dispose();
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  //
  Future<DateTime?> showFrenchDatePicker(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Localizations(
          locale: const Locale('fr', 'FR'),
          delegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: child!,
        );
      },
    );
  }

  Future<void> _printFactures() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer toutes les factures sans pagination
      final response = await Api.fetchFactures(
        projectId: _selectedProject?['_id']?.toString(),
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        supplier: _selectedFournisseur ?? _searchController.text,
        minMontant: _minMontant,
        maxMontant: _maxMontant,
        page: 1,
        limit: 10000,
        userId: widget.userId!,
      );

      final allInvoices =
          (response['data'] as List).map((json) {
            DateTime parseDate(dynamic date) {
              try {
                if (date is DateTime) return date;
                if (date is String) {
                  return DateTime.parse(date.split('.').first);
                }
                return DateTime.now();
              } catch (e) {
                debugPrint('Erreur parsing date $date: $e');
                return DateTime.now();
              }
            }

            return Invoice(
              id: json['_id'].toString(),
              supplier: json['supplier'] ?? json['company'] ?? 'Inconnu',
              total: (json['total'] as num).toDouble(),
              date: parseDate(json['date']),
              invoiceNo: json['invoice_no'] ?? json['number'] ?? '',
              address: json['address'] ?? '',
              currency: json['currency'] ?? '€',
              projectName:
                  json['project']?['name'] ?? json['projectId']?['name'] ?? '',
              imageUrl:
                  json['imageUrl'] ??
                  (json['image'] is String ? json['image'] : null) ??
                  (json['image']?['url'] ?? json['image']?['path']),
            );
          }).toList();
      final pdf = pw.Document();
      final loadedImages = <String, pw.ImageProvider>{};

      // Fonction pour charger une image
      Future<void> _loadImage(String invoiceId, String? url) async {
        if (url == null || url.isEmpty) return;

        try {
          final uri = Uri.parse(url);
          if (!uri.isAbsolute) {
            url = '${ApiConfig.baseUrl}/${url.replaceAll(r'\', '/')}';
          }

          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            loadedImages[invoiceId] = pw.MemoryImage(response.bodyBytes);
          }
        } catch (e) {
          debugPrint('Erreur chargement image $url: $e');
        }
      }

      await Future.wait(
        allInvoices.map((inv) => _loadImage(inv.id, inv.imageUrl)),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(25),
          build: (pw.Context context) {
            return allInvoices.map((invoice) {
              final hasImage = loadedImages.containsKey(invoice.id);
              final imageAvailable =
                  invoice.imageUrl != null && invoice.imageUrl!.isNotEmpty;

              // Formatage sécurisé de la date
              String formatDate(DateTime date) {
                try {
                  return DateFormat('dd/MM/yyyy').format(date);
                } catch (e) {
                  return 'Date invalide';
                }
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Facture ${invoice.invoiceNo}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '${invoice.total.toStringAsFixed(2)} ${invoice.currency}',
                              style: pw.TextStyle(
                                color: PdfColors.blue,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text('Fournisseur: ${invoice.supplier}'),
                        pw.Text('Date: ${formatDate(invoice.date)}'),
                        pw.Text('Projet: ${invoice.projectName}'),
                        pw.Text('Adresse: ${invoice.address}'),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 10),
                  if (hasImage)
                    pw.Container(
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey200),
                      ),
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Image(
                        loadedImages[invoice.id]!,
                        width: 350,
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else if (imageAvailable)
                    pw.Container(
                      color: PdfColors.grey100,
                      padding: const pw.EdgeInsets.all(10),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Image non chargée\n${invoice.imageUrl}',
                        style: pw.TextStyle(color: PdfColors.red, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),

                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 20),
                ],
              );
            }).toList();
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'factures_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur génération PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFactures({
    bool resetPage = false,
    String? projectId,
  }) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (resetPage) _currentPage = 1;
    });

    print('widget.viewOnlyProject: ${widget.viewOnlyProject}');

    try {
      final data = await Api.fetchFactures(
        projectId:
            widget.viewOnlyProject ?? _selectedProject?['_id']?.toString(),
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        supplier: _selectedFournisseur,
        minMontant: _minMontant,
        maxMontant: _maxMontant,
        page: _currentPage,
        limit: _itemsPerPage,
        userId: widget.userId!,
      );
      //print('data');
      //print(data);
      final invoicesData = data['data'] as List? ?? [];
      final paginationData = data['pagination'] as Map? ?? {};
      final currentProjectData = data['currentProject'];
      print('currentProjectData');
      print(currentProjectData);

      String projectName = '';
      int projectStatus = 0;
      if (currentProjectData != null && currentProjectData is Map) {
        projectName = currentProjectData['name']?.toString() ?? '';
        projectStatus = currentProjectData['status'] as int? ?? 0;
      }
      print(' projectStatus');
      print(projectStatus);
      //print(projectName);

      setState(() {
        _currentProjectName = projectName;
        currentProjectStatus = projectStatus;
        _factures =
            invoicesData.map((json) {
              // Gestion optimisée de l'URL de l'image
              final dynamic imageData = json['image'];
              String? imageUrl;

              if (imageData is String) {
                imageUrl = imageData;
              } else if (imageData is Map) {
                imageUrl =
                    imageData['url'] ??
                    (imageData['path'] != null
                        ? '${ApiConfig.baseUrl}/${imageData['path'].toString().replaceAll(r'\', '/')}'
                        : null);
              }
              // Parsing
              DateTime parseFactureDate(dynamic dateInput) {
                try {
                  if (dateInput is DateTime) return dateInput;

                  if (dateInput is String && dateInput.length == 10) {
                    // Format attendu : "YYYY-MM-DD"
                    final parts = dateInput.split('-');
                    if (parts.length == 3) {
                      final year = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final day = int.parse(parts[2]);
                      return DateTime(year, month, day);
                    }
                  }

                  final maybeDate = DateTime.tryParse(dateInput);
                  if (maybeDate != null) return maybeDate;
                } catch (e) {
                  print('Erreur parsing date $dateInput: $e');
                }

                return DateTime.now();
              }

              return Invoice(
                id: json['_id'].toString(),
                supplier:
                    json['supplier'] as String? ??
                    json['company'] as String? ??
                    'Unknown',
                total: (json['total'] as num?)?.toDouble() ?? 0.0,
                date: parseFactureDate(json['date']),
                invoiceNo:
                    json['invoice_no'] as String? ??
                    json['number'] as String? ??
                    '',
                currency: json['currency'] as String? ?? '€',
                address: json['address'] as String? ?? '',
                projectName:
                    (json['project'] != null)
                        ? json['project']['name'] as String? ?? ''
                        : ((json['projectId'] != null)
                            ? json['projectId']['name'] as String? ?? ''
                            : ''),
                imageUrl: json['imageUrl'] ?? imageUrl,
              );
            }).toList();

        _paginationInfo = {
          'page': paginationData['page'] as int? ?? _currentPage,
          'limit': paginationData['limit'] as int? ?? _itemsPerPage,
          'total': paginationData['total'] as int? ?? 0,
          'totalPages': paginationData['totalPages'] as int? ?? 1,
        };

        if (resetPage && _isPageControllerReady && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } catch (e) {
      print('Erreur lors du chargement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur avec fonction load factures: ${e.toString()}'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedFilter = null;
      _selectedDateRange = null;
      _selectedFournisseur = null;
      _minMontant = null;
      _maxMontant = null;
    });
    _loadFactures(resetPage: true);
  }

  Widget _buildAnimatedBackpackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CustomPageRoute(
            page: ProjectsScreen(
              userId: widget.userId!,
              userRole: widget.userRole,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(Icons.work_outline_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Période', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _selectedDateRange != null
                      ? DateFormat(
                        'dd/MM/yyyy',
                      ).format(_selectedDateRange!.start)
                      : 'Date début',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _pickStartDate(),
              ),
            ),
            const Text('au'),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _selectedDateRange != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)
                      : 'Date fin',
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _pickEndDate(),
              ),
            ),
          ],
        ),
        if (_selectedDateRange != null)
          TextButton(
            onPressed: () => setState(() => _selectedDateRange = null),
            child: const Text('Effacer la sélection'),
          ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showFrenchDatePicker(context);
    if (picked != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: picked,
          end: _selectedDateRange?.end ?? picked.add(const Duration(days: 1)),
        );
      });
    }
  }

  Future<void> _pickEndDate() async {
    final initialDate =
        _selectedDateRange?.end ??
        (_selectedDateRange?.start ?? DateTime.now()).add(
          const Duration(days: 1),
        );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _selectedDateRange?.start ?? DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'), // Ajout crucial ici
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: _selectedDateRange?.start ?? picked,
          end: picked,
        );
      });
    }
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showSearchBar ? null : 0,
      //height: _showSearchBar ? 300 : 0,
      child:
          _showSearchBar
              ? SingleChildScrollView(
                physics:
                    const ClampingScrollPhysics(), // Pour un défilement plus fluide
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ligne supérieure : Champ de recherche + boutons
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              // Champ de recherche
                              Expanded(
                                child: TextFormField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Nom du fournisseur...',

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed:
                                          () => _handleSearch(resetPage: true),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Déclencher la recherche à chaque caractère tapé
                                    _handleSearch();
                                  },
                                  onFieldSubmitted:
                                      (_) => _handleSearch(resetPage: true),
                                ),
                              ),

                              // Bouton filtre
                              IconButton(
                                icon: Icon(
                                  Icons.filter_list,
                                  color:
                                      _showFilterOptions
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showFilterOptions = !_showFilterOptions;
                                  });
                                },
                              ),

                              // Bouton fermer
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showSearchBar = false;
                                    _showFilterOptions = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Section filtres avancés
                        if (_showFilterOptions) ...[
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                // Nouveau sélecteur de dates
                                _buildDateRangePicker(),

                                const SizedBox(height: 12),

                                // Filtre par montant
                                _buildRangeFilter(
                                  min: _minMontant,
                                  max: _maxMontant,
                                  onChanged: (min, max) {
                                    setState(() {
                                      _minMontant = min;
                                      _maxMontant = max;
                                    });
                                  },
                                ),

                                // Boutons d'action
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: _clearFilters,
                                        child: const Text('Réinitialiser'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          _handleSearch(resetPage: true);
                                          setState(
                                            () => _showFilterOptions = false,
                                          );
                                        },
                                        child: const Text('Appliquer'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  void _handleSearch({bool resetPage = false}) {
    // Annuler le timer précédent s'il existe
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      // Appliquer le filtre fournisseur si texte saisi
      setState(() {
        _selectedFournisseur =
            _searchController.text.isNotEmpty ? _searchController.text : null;

        if (_selectedFilter == 'Tous') {
          _selectedFilter = null;
        }
      });

      _loadFactures(resetPage: true);
    });
  }

  Widget _buildRangeFilter({
    required double? min,
    required double? max,
    required Function(double?, double?) onChanged,
  }) {
    final scaleFactor = 1.0;
    final minController = TextEditingController(text: min?.toString() ?? '');
    final maxController = TextEditingController(text: max?.toString() ?? '');
    return Transform.scale(
      scale: scaleFactor,
      alignment: Alignment.topLeft,
      child: Container(
        width:
            MediaQuery.of(context).size.width *
            ( //isMobile ? 0.7 :
            1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Montant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: min?.toString() ?? '',
                    //controller: minController, // Utilisez le contrôleur
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    /*onChanged: (value) {
                      onChanged(double.tryParse(value), max);
                    },*/
                    onChanged: (value) {
                      onChanged(
                        value.isEmpty ? null : double.tryParse(value),
                        max,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: max?.toString() ?? '',
                    //controller: maxController, // Utilisez le contrôleur
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    /* onChanged: (value) {
                      onChanged(min, double.tryParse(value));
                    },*/
                    onChanged: (value) {
                      onChanged(
                        min,
                        value.isEmpty ? null : double.tryParse(value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final scaleFactor = 1.0;

    return Transform.scale(
      scale: scaleFactor,
      alignment: Alignment.topLeft,
      child: Container(
        width:
            MediaQuery.of(context).size.width *
            ( //isMobile ? 0.7 :
            1.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              //if (widget.userRole != 'PM')
              if (widget.userRole != 'PM')
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: ProjectApi().getAllProjectsWithManager(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        'Erreur',
                        style: TextStyle(fontSize: 14),
                      );
                    }

                    final projects = snapshot.data ?? [];

                    // Trouver le projet correspondant à la sélection actuelle
                    Map<String, dynamic>? selectedItem;
                    if (_selectedProject != null) {
                      selectedItem =
                          projects
                              .where(
                                (p) => p['_id'] == _selectedProject!['_id'],
                              )
                              .cast<Map<String, dynamic>>()
                              .toList()
                              .firstOrNull;
                    }

                    // Si la sélection n'est pas valide, réinitialiser
                    if (_selectedProject != null && selectedItem == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedProject = null);
                      });
                    }

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.4,
                      ),
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedItem,
                        hint: const Text(
                          'Tous les projets',
                          style: TextStyle(fontSize: 14),
                        ),
                        underline: Container(height: 0),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<Map<String, dynamic>>(
                            value: null,
                            child: Text('Tous les projets'),
                          ),
                          ...projects.map((project) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: project,
                              child: Text(
                                project['name'] ?? 'Projet sans nom',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (Map<String, dynamic>? newValue) {
                          setState(() {
                            _selectedProject = newValue;
                            _loadFactures(
                              resetPage: true,
                              projectId: newValue?['_id']?.toString(),
                            );
                          });
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  _isSelectionMode
                      ? '${_selectedInvoices.length} sélectionné(s)'
                      : 'Factures',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              //if (_isSelectionMode) // Afficher seulement en mode sélection
              if (_isSelectionMode && !isViewOnly)
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedInvoices,
                ),

              // Supprimer le bouton de checklist qui activait le mode sélection
              if (!_isSelectionMode) // Afficher les autres boutons seulement hors sélection
                IconButton(
                  icon: Icon(Icons.search, color: Colors.grey.shade700),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (!_showSearchBar) _showFilterOptions = false;
                    });
                  },
                ),

              if (!_isSelectionMode)
                IconButton(
                  icon: Icon(Icons.print, color: Colors.grey.shade700),
                  onPressed: _printFactures,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /*
  Widget _buildHeaderWithBudget() {
    // Déterminer quel ID de projet utiliser selon le rôle
    Future<Map<String, dynamic>>? futureProjectData;

    if (widget.userRole == 'PM') {
      // Pour les PM - logique originale inchangée

      futureProjectData = ProjectApi().fetchiliProject(
        projectId: widget.viewOnlyProject,
      );
    } else if (widget.userRole == 'RF' &&
        _selectedProject != null &&
        _selectedProject!['_id'] != null) {
      // Pour les RF - seulement si un projet est sélectionné
      futureProjectData = ProjectApi().fetchiliProject(
        projectId: _selectedProject!['_id'].toString(),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: futureProjectData,
      builder: (context, snapshot) {
        // Données par défaut
        String projectTitle;
        double projectBudget = 0;
        String currency = '';
        double totalInvoices = 0;
        double remaining = 0;

        // Déterminer le message par défaut selon le rôle
        if (widget.userRole == 'RF' && futureProjectData == null) {
          projectTitle = 'Tous les projets';
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          projectTitle = 'Chargement...';
        } else if (snapshot.hasError) {
          projectTitle = 'Erreur de chargement';
        } else if (snapshot.hasData) {
          projectTitle = snapshot.data!['name'] ?? 'Projet sans nom';
          projectBudget = snapshot.data!['budget']?.toDouble() ?? 0;
          currency = snapshot.data!['currency'] ?? '';
          totalInvoices = snapshot.data!['totalinvoices']?.toDouble() ?? 0;
          remaining = double.parse(
            (projectBudget - totalInvoices).toStringAsFixed(2),
          );
        } else {
          projectTitle = 'Aucune donnée';
        }

        return Container(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                height: 155,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              projectTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildAnimatedBackpackButton(),
                          ),
                        ],
                      ),
                      if (snapshot
                          .hasData) // Afficher les infos seulement si on a des données
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBudgetInfo(
                              'Budget',
                              '$projectBudget $currency',
                              Icons.account_balance_wallet,
                            ),
                            SizedBox(width: 30),
                            _buildBudgetInfo(
                              'Reste',
                              '$remaining $currency',
                              Icons.savings,
                              textColor:
                                  remaining >= 0
                                      ? Colors.green[200]
                                      : Colors.red[200],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
*/
  Widget _buildHeaderWithBudget() {
    // Déterminer quel ID de projet utiliser selon le rôle
    Future<Map<String, dynamic>>? futureProjectData;

    if (widget.userRole == 'PM') {
      // Pour les PM - logique originale inchangée
      futureProjectData = ProjectApi().fetchiliProject(
        projectId: widget.viewOnlyProject,
      );
    } else if (widget.userRole == 'RF' &&
        _selectedProject != null &&
        _selectedProject!['_id'] != null) {
      // Pour les RF - seulement si un projet est sélectionné
      futureProjectData = ProjectApi().fetchiliProject(
        projectId: _selectedProject!['_id'].toString(),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: futureProjectData,
      builder: (context, snapshot) {
        // Données par défaut
        String projectTitle;
        double projectBudget = 0;
        String currency = '';
        double totalInvoices = 0;
        double remaining = 0;
        bool showBudgetInfo =
            false; // Nouvelle variable pour contrôler l'affichage

        // Déterminer le message par défaut selon le rôle
        if (widget.userRole == 'RF' && futureProjectData == null) {
          projectTitle = 'Tous les projets';
          showBudgetInfo =
              false; // Ne pas afficher les infos budget pour "Tous les projets"
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          projectTitle = 'Chargement...';
          showBudgetInfo = false; // Ne pas afficher pendant le chargement
        } else if (snapshot.hasError) {
          projectTitle = 'Aucune donnée trouvée';
          showBudgetInfo = false; // Ne pas afficher en cas d'erreur
        } else if (snapshot.hasData) {
          projectTitle = snapshot.data!['name'] ?? 'Projet sans nom';
          projectBudget = snapshot.data!['budget']?.toDouble() ?? 0;
          currency = snapshot.data!['currency'] ?? '';
          totalInvoices = snapshot.data!['totalinvoices']?.toDouble() ?? 0;
          remaining = double.parse(
            (projectBudget - totalInvoices).toStringAsFixed(2),
          );
          showBudgetInfo =
              true; // Afficher les infos budget seulement si on a des données
        } else {
          projectTitle = 'Aucune donnée';
          showBudgetInfo = false; // Ne pas afficher par défaut
        }

        return Container(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                height: 155,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              projectTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildAnimatedBackpackButton(),
                          ),
                        ],
                      ),
                      // Afficher les infos budget seulement si showBudgetInfo est true
                      if (showBudgetInfo)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBudgetInfo(
                              'Budget',
                              '$projectBudget $currency',
                              Icons.account_balance_wallet,
                            ),
                            SizedBox(width: 30),
                            _buildBudgetInfo(
                              'Reste',
                              '$remaining $currency',
                              Icons.savings,
                              textColor:
                                  remaining >= 0
                                      ? Colors.green[200]
                                      : Colors.red[200],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetInfo(
    String label,
    String value,
    IconData icon, {
    Color? textColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 16),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPagination() {
    if (_factures.isEmpty)
      return SizedBox.shrink(); // Ne rien afficher si pas de factures

    final currentPage = _paginationInfo?['page'] as int? ?? 1;
    final totalPages = _paginationInfo?['totalPages'] as int? ?? 1;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() {
                        _currentPage = currentPage - 1;
                      });
                      _loadFactures();
                    }
                    : null,
          ),
          Text('Page $currentPage / $totalPages'),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed:
                currentPage < totalPages
                    ? () {
                      setState(() {
                        _currentPage = currentPage + 1;
                      });
                      _loadFactures();
                    }
                    : null,
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedInvoices.clear();
      }
    });
  }

  // Méthode pour sélectionner/désélectionner une facture
  void _toggleInvoiceSelection(String invoiceId) {
    setState(() {
      if (_selectedInvoices.contains(invoiceId)) {
        _selectedInvoices.remove(invoiceId);
      } else {
        _selectedInvoices.add(invoiceId);
      }

      // Désactiver le mode de sélection si aucune facture n'est sélectionnée
      if (_selectedInvoices.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelectedInvoices() async {
    if (_selectedInvoices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmer la suppression'),
            content: Text(
              'Voulez-vous vraiment supprimer les ${_selectedInvoices.length} factures sélectionnées?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Capture the IDs to delete before clearing the state
    final List<String> invoicesToDelete = List.from(_selectedInvoices);

    if (mounted) {
      setState(() {
        _isLoading = true;
        // First remove the invoices from the local list for immediate UI feedback
        _factures.removeWhere(
          (invoice) => invoicesToDelete.contains(invoice.id),
        );
        _isSelectionMode = false;
        _selectedInvoices.clear();
      });
    }

    try {
      // Call the API to delete the invoices
      final success = await Api.deleteMultipleFactures(
        invoicesToDelete,
        widget.userId!,
      );

      if (success) {
        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ConfirmationCard(
              isSuccess: true,
              message: '${invoicesToDelete.length} factures supprimées',
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );

        // Reload data

        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _loadFactures(resetPage: true);
          }
        });
      }
    } catch (e) {
      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ConfirmationCard(
            isSuccess: false,
            message: 'Erreur lors de la suppression: ${e.toString()}',
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reload
      if (mounted) {
        _loadFactures(resetPage: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInvoiceCard(Invoice facture) {
    final isSelected = _selectedInvoices.contains(facture.id);
    final String invoiceNo = facture.invoiceNo;
    final String currency = facture.currency ?? '€';

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isSelected ? Colors.red.withOpacity(0.5) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          //if (_isSelectionMode)
          if (!isViewOnly && _isSelectionMode) {
            // En mode sélection, un clic simple sélectionne/désélectionne
            setState(() {
              if (_selectedInvoices.contains(facture.id)) {
                _selectedInvoices.remove(facture.id);
                // Quitter le mode sélection si plus aucune facture sélectionnée
                if (_selectedInvoices.isEmpty) {
                  _isSelectionMode = false;
                }
              } else {
                _selectedInvoices.add(facture.id);
              }
            });
          } else {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Center(child: CircularProgressIndicator());
              },
            );

            ProjectApi.getFactureDetails(facture.id)
                .then((factureDetails) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => UpdateFactureScreen(
                            facture: factureDetails,
                            userRole: widget.userRole,
                            currentProjectStatus: currentProjectStatus,
                            isViewOnly: isViewOnly,
                          ),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadFactures(resetPage: false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Facture mise à jour avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                })
                .catchError((error) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${error.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
          }
        },
        onLongPress:
            isViewOnly
                ? null // Désactive complètement le long press en viewOnly
                : () {
                  // Activer le mode sélection seulement si ce n'est pas déjà fait
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedInvoices.add(facture.id);
                    });
                  }
                },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF9FAFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Numéro de facture avec badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 15,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'N° $invoiceNo',
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 10,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date avec icône
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 15,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        formatDate(facture.date),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 14),

              // Fournisseur et montant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Fournisseur avec icône
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.business_outlined,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fournisseur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                facture.supplier,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Montant avec devise
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        //SizedBox(width: 4),
                        Text(
                          '${facture.total.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            color: Colors.green.shade700,
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 120),
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 20),
            Text(
              'Aucune facture trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Modifiez vos critères de recherche',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              //icon: Icon(Icons.refresh),
              label: Text(
                'Réinitialiser les filtres',
                style: TextStyle(
                  color: const Color.fromARGB(255, 245, 240, 240),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: _buildHeaderWithBudget(),
              ),

              //scrollable
              Positioned(
                top: 125,
                left: 0,
                right: 0,
                bottom: 0,
                child: SingleChildScrollView(
                  // Scroll principal
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 125, //
                    ),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // éviter l'overflow
                        children: [
                          SizedBox(height: 10),
                          _buildToolbar(),
                          _buildSearchBar(),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  constraints.maxHeight -
                                  200, // Réserve de l'espace pour header + toolbar
                            ),
                            child:
                                _isLoading
                                    ? Center(child: CircularProgressIndicator())
                                    : _factures.isEmpty
                                    ? _buildEmptyState()
                                    : PageView.builder(
                                      controller: _pageController,
                                      itemCount:
                                          _paginationInfo?['totalPages'] ?? 1,
                                      onPageChanged: (int page) {
                                        setState(() => _currentPage = page + 1);
                                        _loadFactures();
                                      },
                                      itemBuilder: (context, pageIndex) {
                                        return ListView.builder(
                                          //physics:
                                          //const NeverScrollableScrollPhysics(), // Désactive le scroll interne
                                          padding: EdgeInsets.all(16),
                                          itemCount: _factures.length,

                                          itemBuilder: (context, index) {
                                            return _buildInvoiceCard(
                                              _factures[index],
                                            );
                                          },
                                        );
                                      },
                                    ),
                          ),
                          _buildPagination(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Pagination
            ],
          );
        },
      ),
    );
  }
}
