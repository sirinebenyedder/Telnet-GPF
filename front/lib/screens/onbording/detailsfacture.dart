/*
import 'dart:convert';
import 'dart:io';
import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Telnet/theme/input_decoration_theme.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();

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

class UpdateFactureScreen extends StatefulWidget {
  final Map<String, dynamic> facture;
  //final String? userId;
  final String? userRole;
  final int? currentProjectStatus;
  final bool isViewOnly;
  const UpdateFactureScreen({
    super.key,
    required this.facture,
    this.userRole,
    this.currentProjectStatus,
    this.isViewOnly = false,
    int? status,
    //required this.userId,
  });

  @override
  _UpdateFactureScreenState createState() => _UpdateFactureScreenState();
}

class _UpdateFactureScreenState extends State<UpdateFactureScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceNoController;
  late TextEditingController _dateController;
  late TextEditingController _totalController;
  late TextEditingController _companyController;
  late TextEditingController _addressController;

  String _selectedDevise = 'EUR';
  File? _selectedImage;
  bool _isLoading = false;
  List<InvoiceItem> _items = [];
  bool _showConfirmation = false;
  String _confirmationMessage = '';
  bool _requestSuccess = false;
  String _mainCurrency = 'EUR';
  String _secondaryCurrency = 'EUR';
  String? _existingImageUrl; // Ajoutez cette lign
  // Variables pour la caméra
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _documentDetected = false;
  final Rect _guideRect = const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95);
  String? userRole;
  //
  bool get _isEditable =>
      widget.userRole == "PM" && widget.currentProjectStatus == 2;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFactureData();
    _initializeCameras(); // Juste pour obtenir la liste des caméras
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
  }

  void _initializeFactureData() {
    final factureData = widget.facture;
    print('heeeeeeeeeeeeeeeee');
    print(widget.currentProjectStatus);
    print(widget.userRole);
    print(_isEditable);
    print(widget.userRole == "PM" && widget.currentProjectStatus == 2);
    _existingImageUrl = factureData['imageUrl'] ?? factureData['image_url'];
    _mainCurrency =
        factureData['project']?['currency']?.toString().toUpperCase() ?? 'EUR';
    _secondaryCurrency =
        factureData['project']?['second_currency']?.toString().toUpperCase() ??
        '';
    _selectedDevise =
        (widget.facture['devise']?.toString().toUpperCase() ??
            _mainCurrency ??
            'EUR');

    _invoiceNoController = TextEditingController(
      text: factureData['invoice_no'] ?? factureData['invoiceNo'] ?? '',
    );

    _dateController = TextEditingController(
      text: factureData['date'] != null ? _parseDate(factureData['date']) : '',
    );

    _totalController = TextEditingController(
      text: factureData['total']?.toString() ?? '',
    );

    _companyController = TextEditingController(
      text: factureData['company'] ?? factureData['supplier'] ?? '',
    );

    _addressController = TextEditingController(
      text: factureData['address'] ?? factureData['address_country'] ?? '',
    );

    if (factureData['items'] != null && factureData['items'].isNotEmpty) {
      for (var item in factureData['items']) {
        final newItem = InvoiceItem();
        newItem.descriptionController.text = item['description'] ?? '';
        newItem.quantityController.text = item['quantity']?.toString() ?? '';
        newItem.unitPriceController.text = item['unit_price']?.toString() ?? '';
        _items.add(newItem);
        print(factureData['imageUrl'] ?? factureData['image_url']);
      }
    } else {
      _addItem();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Utiliser la caméra arrière
        CameraDescription? backCamera;
        for (var camera in _cameras) {
          if (camera.lensDirection == CameraLensDirection.back) {
            backCamera = camera;
            break;
          }
        }

        await _initializeCameraController(backCamera ?? _cameras[0]);
      }
    } catch (e) {
      print("Erreur initialisation caméra: $e");
    }
  }

  Future<void> _initializeCameraController(CameraDescription camera) async {
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isCameraReady = true;
        });
      }
    } catch (e) {
      print("Erreur initialisation contrôleur caméra: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invoiceNoController.dispose();
    _dateController.dispose();
    _totalController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    for (var item in _items) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.unitPriceController.dispose();
    }
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null) {
        _initializeCameraController(_cameraController!.description);
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile originalImage = await _cameraController!.takePicture();
      final File processedImage = await _processInvoiceImage(
        File(originalImage.path),
      );

      setState(() {
        _selectedImage = processedImage;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<File> _processInvoiceImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception("Impossible de décoder l'image");
      }

      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;

      final cropX = (imageWidth * 0.05).round();
      final cropY = (imageHeight * 0.05).round();
      final cropWidth = (imageWidth * 0.9).round();
      final cropHeight = (imageHeight * 0.9).round();

      img.Image croppedImage;
      try {
        croppedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );
      } catch (e) {
        print("Erreur lors du recadrage, utilisation de l'image complète: $e");
        croppedImage = originalImage;
      }

      croppedImage = img.grayscale(croppedImage);
      croppedImage = img.contrast(croppedImage, contrast: 150);

      final tempDir = await getTemporaryDirectory();
      final processedFilePath =
          '${tempDir.path}/processed_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedFilePath);

      await processedFile.writeAsBytes(
        img.encodeJpg(croppedImage, quality: 85),
      );

      return processedFile;
    } catch (e) {
      print("Erreur lors du traitement de l'image: $e");
      return imageFile;
    }
  }

  void _showFullScreenImage() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child:
                  _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.contain)
                      : Image.network(_existingImageUrl!, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            _selectedImage != null
                ? _buildSelectedImagePreview()
                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ? _buildExistingImagePreview()
                : _buildCameraPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_selectedImage!, fit: BoxFit.contain),
            ),
          ),
          //if (_isEditable) // Boutons seulement pour PM
          if (!widget.isViewOnly)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExistingImagePreview() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _existingImageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
          ),
          //if (_isEditable) // Boutons seulement pour PM
          if (!widget.isViewOnly)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(cameras: _cameras),
                        ),
                      );
                      if (result != null && result is File) {
                        setState(() {
                          _selectedImage = result;
                          _existingImageUrl = null;
                        });
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                    onPressed:
                        () => setState(() {
                          _existingImageUrl = null;
                          _selectedImage = null;
                        }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _parseDate(String dateString) {
    try {
      final dateWithTime = DateFormat('dd/MM/yyyy, HH:mm:ss').parse(dateString);
      return DateFormat('yyyy-MM-dd').format(dateWithTime);
    } catch (e) {
      try {
        final isoDate = DateTime.parse(dateString);
        return DateFormat('yyyy-MM-dd').format(isoDate);
      } catch (e) {
        return DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      _items[0].descriptionController.clear();
      _items[0].quantityController.clear();
      _items[0].unitPriceController.clear();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateController.text.isNotEmpty
              ? DateTime.parse(_dateController.text)
              : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateFacture() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showConfirmation = false;
    });

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '${ApiConfig.baseUrl}/api/invoices/updateinvoice/${widget.facture['_id']}',
        ),
      );

      request.fields.addAll({
        'invoice_no': _invoiceNoController.text,
        'date': _dateController.text,
        'total': _totalController.text,
        'company': _companyController.text,
        'address': _addressController.text,
        'currency': _selectedDevise,
        'items': json.encode(_items.map((item) => item.toMap()).toList()),
      });

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        _showMessage(true, 'Facture mise à jour avec succès');
        Navigator.pop(context, true);
      } else {
        _showMessage(
          false,
          jsonResponse['message'] ?? 'Échec de la mise à jour',
        );
      }
    } catch (e) {
      _showMessage(false, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(bool success, String message) {
    setState(() {
      _showConfirmation = true;
      _requestSuccess = success;
      _confirmationMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showConfirmation = false);
      }
    });
  }

  Widget _buildCameraPreview() {
    // Seulement visible pour les PM
    if (widget.userRole != "PM") {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Aucune photo disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(cameras: _cameras),
          ),
        );

        if (result != null && result is File) {
          setState(() {
            _selectedImage = result;
          });
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('Appuyez pour prendre une photo'),
          ],
        ),
      ),
    );
  }

  List<Offset> _calculateGuideCorners() {
    final screenWidth = MediaQuery.of(context).size.width;
    return [
      Offset(screenWidth * _guideRect.left, 200 * _guideRect.top),
      Offset(screenWidth * _guideRect.right, 200 * _guideRect.top),
      Offset(screenWidth * _guideRect.right, 200 * _guideRect.bottom),
      Offset(screenWidth * _guideRect.left, 200 * _guideRect.bottom),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Détecter si l'appareil est un PC (large écran)
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewOnly ? 'Consulter facture' : 'Modifier facture',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          // Pour les écrans larges (PC), limiter à 50% de la largeur avec un maximum de 800px
          width: isDesktop ? MediaQuery.of(context).size.width * 0.5 : null,
          constraints: isDesktop ? BoxConstraints(maxWidth: 800) : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Image avec caméra
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
                          _selectedImage != null
                              ? _buildSelectedImagePreview()
                              : (_existingImageUrl != null &&
                                      _existingImageUrl!.isNotEmpty
                                  ? _buildExistingImagePreview()
                                  : _buildCameraPreview()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Informations principales
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
                            ),
                            readOnly: !_isEditable, // Lecture seule si pas PM
                            //enabled: _isEditable, // Désactivé si pas PM
                            enabled: !widget.isViewOnly,
                            style: TextStyle(
                              color:
                                  _isEditable
                                      ? Colors.black
                                      : const Color.fromRGBO(
                                        66,
                                        66,
                                        66,
                                        1,
                                      ), // Texte grisé si lecture seule
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Champ requis' : null,
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
                            ),
                            enabled: !widget.isViewOnly,
                            readOnly: !_isEditable, // Lecture seule si pas PM
                            //enabled: _isEditable, // Désactivé si pas PM
                            style: TextStyle(
                              color:
                                  _isEditable
                                      ? Colors.black
                                      : const Color.fromRGBO(
                                        66,
                                        66,
                                        66,
                                        1,
                                      ), // Texte grisé si lecture seule
                            ),
                            onTap: () => _selectDate(context),
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Champ requis' : null,
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
                            ),
                            readOnly: !_isEditable, // Lecture seule si pas PM
                            //enabled: _isEditable, // Désactivé si pas PM
                            enabled: !widget.isViewOnly,
                            style: TextStyle(
                              color:
                                  _isEditable
                                      ? Colors.black
                                      : const Color.fromRGBO(
                                        97,
                                        97,
                                        97,
                                        1,
                                      ), // Texte grisé si lecture seule
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Champ requis' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Détails financiers
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
                            ),
                            readOnly: !_isEditable, // Lecture seule si pas PM
                            enabled: !widget.isViewOnly,
                            //enabled: _isEditable, // Désactivé si pas PM
                            style: TextStyle(
                              color:
                                  _isEditable
                                      ? Colors.black
                                      : const Color.fromRGBO(
                                        97,
                                        97,
                                        97,
                                        1,
                                      ), // Texte grisé si lecture seule
                            ),
                            validator: (value) {
                              if (value!.isEmpty) return 'Montant requis';
                              if (double.tryParse(value) == null)
                                return 'Nombre valide requis';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedDevise,
                            decoration: InputDecoration(
                              labelText: 'Devise',
                              prefixIcon: const Icon(Icons.currency_exchange),
                              fillColor:
                                  _isEditable
                                      ? lightInputDecorationTheme.fillColor
                                      : Colors.grey[200],
                              filled: lightInputDecorationTheme.filled,
                              border: lightInputDecorationTheme.border,
                              enabledBorder:
                                  lightInputDecorationTheme.enabledBorder,
                              focusedBorder:
                                  lightInputDecorationTheme.focusedBorder,
                            ),
                            items:
                                [
                                  _mainCurrency,
                                  if (_secondaryCurrency.isNotEmpty &&
                                      _secondaryCurrency != _mainCurrency)
                                    _secondaryCurrency,
                                ].map((devise) {
                                  return DropdownMenuItem(
                                    value: devise,
                                    child: Text(
                                      devise,
                                      style: TextStyle(
                                        color:
                                            _isEditable
                                                ? Colors.black
                                                : Colors.grey[700],
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                _isEditable
                                    ? (value) =>
                                        setState(() => _selectedDevise = value!)
                                    : null,
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
                            ),
                            readOnly: !_isEditable, // Lecture seule si pas PM
                            enabled: !widget.isViewOnly,
                            //enabled: _isEditable, // Désactivé si pas PM
                            style: TextStyle(
                              color:
                                  _isEditable
                                      ? Colors.black
                                      : Colors
                                          .grey[800], // Texte grisé si lecture seule
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Articles
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Articles",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),

                              //if (_isEditable)
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                        //if (_isEditable)
                                        if (!widget.isViewOnly)
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
                                      ),
                                      readOnly:
                                          !_isEditable, // Lecture seule si pas PM
                                      //enabled:_isEditable,
                                      enabled: !widget.isViewOnly,
                                      style: TextStyle(
                                        color:
                                            _isEditable
                                                ? Colors.black
                                                : Colors
                                                    .grey[800], // Texte grisé si lecture seule
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: item.quantityController,
                                            keyboardType: TextInputType.number,
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
                                            ),
                                            readOnly:
                                                !_isEditable, // Lecture seule si pas PM
                                            //enabled:_isEditable,
                                            enabled: !widget.isViewOnly,
                                            style: TextStyle(
                                              color:
                                                  _isEditable
                                                      ? Colors.black
                                                      : Colors
                                                          .grey[800], // Texte grisé si lecture seule
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                item.unitPriceController,
                                            keyboardType: TextInputType.number,
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
                                            ),
                                            readOnly:
                                                !_isEditable, // Lecture seule si pas PM
                                            //enabled:
                                            //_isEditable, // Désactivé si pas PM
                                            enabled: !widget.isViewOnly,
                                            style: TextStyle(
                                              color:
                                                  _isEditable
                                                      ? Colors.black
                                                      : const Color(
                                                        0xFF424242,
                                                      ), // Texte grisé si lecture seule
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          if (!widget.isViewOnly)
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
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton Enregistrer
                  //if (_isEditable)
                  if (!widget.isViewOnly)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateFacture,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  if (_showConfirmation)
                    Center(
                      child: Text(
                        _confirmationMessage,
                        style: TextStyle(
                          color: _requestSuccess ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DocumentBoundaryPainter extends CustomPainter {
  final List<Offset> corners;
  final bool documentDetected;

  DocumentBoundaryPainter({
    required this.corners,
    required this.documentDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = documentDetected ? Colors.green : Colors.yellow
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke;

    if (corners.length == 4) {
      final path = Path();
      path.moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);

      final dotPaint =
          Paint()
            ..color = documentDetected ? Colors.green : Colors.yellow
            ..style = PaintingStyle.fill;

      for (var corner in corners) {
        canvas.drawCircle(corner, 12.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(DocumentBoundaryPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.documentDetected != documentDetected;
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0], // Utilisez la caméra arrière
      ResolutionPreset.high,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print("Erreur initialisation caméra: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) return;

    try {
      final XFile file = await _controller.takePicture();
      Navigator.pop(context, File(file.path));
    } catch (e) {
      print("Erreur prise de photo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre une photo')),
      body: Stack(
        children: [
          if (_isCameraReady) CameraPreview(_controller),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/
import 'dart:convert';
import 'dart:io';
import 'package:Telnet/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:Telnet/theme/input_decoration_theme.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class InvoiceItem {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();

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

class UpdateFactureScreen extends StatefulWidget {
  final Map<String, dynamic> facture;
  final String? userRole;
  final int? currentProjectStatus;
  final bool isViewOnly;
  const UpdateFactureScreen({
    super.key,
    required this.facture,
    this.userRole,
    this.currentProjectStatus,
    this.isViewOnly = false,
    int? status,
  });

  @override
  _UpdateFactureScreenState createState() => _UpdateFactureScreenState();
}

class _UpdateFactureScreenState extends State<UpdateFactureScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _invoiceNoController;
  late TextEditingController _dateController;
  late TextEditingController _totalController;
  late TextEditingController _companyController;
  late TextEditingController _addressController;

  String _selectedDevise = 'EUR';
  File? _selectedImage;
  bool _isLoading = false;
  List<InvoiceItem> _items = [];
  bool _showConfirmation = false;
  String _confirmationMessage = '';
  bool _requestSuccess = false;
  String _mainCurrency = 'EUR';
  String _secondaryCurrency = 'EUR';
  String? _existingImageUrl; // Ajoutez cette lign
  // Variables pour la caméra
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _documentDetected = false;
  final Rect _guideRect = const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95);
  //
  // Variables pour la caméra
  //CameraController? _cameraController;
  //List<CameraDescription> _cameras = [];
  //bool _isCameraReady = false;
  bool _showCameraPreview = false;
  bool _isProcessingImage = false;

  String? userRole;
  //
  bool get _isEditable =>
      widget.userRole == "PM" && widget.currentProjectStatus == 2;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFactureData();
    _initializeCameras(); // Juste pour obtenir la liste des caméras
  }

  Future<void> _initializeCameras() async {
    _cameras = await availableCameras();
  }

  void _initializeFactureData() {
    final factureData = widget.facture;
    print('heeeeeeeeeeeeeeeee');
    print(widget.currentProjectStatus);
    print(widget.userRole);
    print(_isEditable);
    print(widget.userRole == "PM" && widget.currentProjectStatus == 2);
    _existingImageUrl = factureData['imageUrl'] ?? factureData['image_url'];
    _mainCurrency =
        factureData['project']?['currency']?.toString().toUpperCase() ?? 'EUR';
    _secondaryCurrency =
        factureData['project']?['second_currency']?.toString().toUpperCase() ??
        '';
    _selectedDevise =
        (widget.facture['devise']?.toString().toUpperCase() ??
            _mainCurrency ??
            'EUR');

    _invoiceNoController = TextEditingController(
      text: factureData['invoice_no'] ?? factureData['invoiceNo'] ?? '',
    );

    _dateController = TextEditingController(
      text: factureData['date'] != null ? _parseDate(factureData['date']) : '',
    );

    _totalController = TextEditingController(
      text: factureData['total']?.toString() ?? '',
    );

    _companyController = TextEditingController(
      text: factureData['company'] ?? factureData['supplier'] ?? '',
    );

    _addressController = TextEditingController(
      text: factureData['address'] ?? factureData['address_country'] ?? '',
    );

    if (factureData['items'] != null && factureData['items'].isNotEmpty) {
      for (var item in factureData['items']) {
        final newItem = InvoiceItem();
        newItem.descriptionController.text = item['description'] ?? '';
        newItem.quantityController.text = item['quantity']?.toString() ?? '';
        newItem.unitPriceController.text = item['unit_price']?.toString() ?? '';
        _items.add(newItem);
        print(factureData['imageUrl'] ?? factureData['image_url']);
      }
    } else {
      _addItem();
    }
  }

  //////////////////////////////////////////
  ///
  ///New methpdes
  ///
  ///
  ///
  ///
  // Fonction simplifiée pour ouvrir la caméra
  Future<void> _openCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showMessage(false, 'Aucune caméra disponible');
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCameraScreen(cameras: cameras),
        ),
      );

      if (result != null && result is File) {
        // Traitement de l'image (conversion en gris)
        final processedImage = await _processImageToGrayscale(result);
        setState(() {
          _selectedImage = processedImage;
          _existingImageUrl = null; // Remplacer l'image existante
        });
      }
    } catch (e) {
      _showMessage(false, 'Erreur lors de l\'ouverture de la caméra: $e');
    }
  }

  // Traitement simple : conversion en niveaux de gris
  Future<File> _processImageToGrayscale(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return imageFile;

      // Conversion en niveaux de gris
      final grayscaleImage = img.grayscale(originalImage);

      // Sauvegarde de l'image traitée
      final tempDir = await getTemporaryDirectory();
      final processedPath =
          '${tempDir.path}/processed_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(
        img.encodeJpg(grayscaleImage, quality: 85),
      );

      return processedFile;
    } catch (e) {
      print('Erreur traitement image: $e');
      return imageFile; // Retourner l'image originale en cas d'erreur
    }
  }

  // Widget pour afficher la section image
  Widget _buildImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            _buildImageDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    // Si on a une nouvelle image sélectionnée
    if (_selectedImage != null) {
      return _buildImagePreview(_selectedImage!, isFile: true);
    }

    // Si on a une image existante
    if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return _buildImagePreview(_existingImageUrl!, isFile: false);
    }

    // Placeholder - pas d'image
    return _buildPlaceholder();
  }

  Widget _buildImagePreview(dynamic imageSource, {required bool isFile}) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imageSource, isFile),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child:
                  isFile
                      ? Image.file(imageSource as File, fit: BoxFit.contain)
                      : Image.network(
                        imageSource as String,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
            ),
          ),
          if (!widget
              .isViewOnly) // Boutons de modification seulement si pas en lecture seule
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  // Bouton pour changer la photo
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _openCamera,
                  ),
                  SizedBox(width: 10),
                  // Bouton pour supprimer la photo
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                    onPressed:
                        () => setState(() {
                          _selectedImage = null;
                          _existingImageUrl = null;
                        }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return GestureDetector(
      onTap: widget.isViewOnly ? null : _openCamera,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border:
              widget.isViewOnly
                  ? null
                  : Border.all(
                    color: Colors.grey[400]!,
                    style: BorderStyle.solid,
                    width: 2,
                  ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isViewOnly ? Icons.image_not_supported : Icons.camera_alt,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 10),
            Text(
              widget.isViewOnly
                  ? 'Aucune photo disponible'
                  : 'Appuyez pour prendre une photo',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(dynamic imageSource, bool isFile) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child:
                  isFile
                      ? Image.file(imageSource as File, fit: BoxFit.contain)
                      : Image.network(
                        imageSource as String,
                        fit: BoxFit.contain,
                      ),
            ),
          ),
    );
  }

  //////////

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invoiceNoController.dispose();
    _dateController.dispose();
    _totalController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    for (var item in _items) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.unitPriceController.dispose();
    }
    _cameraController?.dispose();
    super.dispose();
  }

  /* Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile originalImage = await _cameraController!.takePicture();
      final File processedImage = await _processInvoiceImage(
        File(originalImage.path),
      );

      setState(() {
        _selectedImage = processedImage;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }*/

  Future<File> _processInvoiceImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception("Impossible de décoder l'image");
      }

      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;

      final cropX = (imageWidth * 0.05).round();
      final cropY = (imageHeight * 0.05).round();
      final cropWidth = (imageWidth * 0.9).round();
      final cropHeight = (imageHeight * 0.9).round();

      img.Image croppedImage;
      try {
        croppedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );
      } catch (e) {
        print("Erreur lors du recadrage, utilisation de l'image complète: $e");
        croppedImage = originalImage;
      }

      croppedImage = img.grayscale(croppedImage);
      croppedImage = img.contrast(croppedImage, contrast: 150);

      final tempDir = await getTemporaryDirectory();
      final processedFilePath =
          '${tempDir.path}/processed_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedFilePath);

      await processedFile.writeAsBytes(
        img.encodeJpg(croppedImage, quality: 85),
      );

      return processedFile;
    } catch (e) {
      print("Erreur lors du traitement de l'image: $e");
      return imageFile;
    }
  }

  /*void _showFullScreenImage() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child:
                  _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.contain)
                      : Image.network(_existingImageUrl!, fit: BoxFit.contain),
            ),
          ),
    );
  }*/

  /*Widget _buildImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            _selectedImage != null
                ? _buildSelectedImagePreview()
                : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ? _buildExistingImagePreview()
                : _buildCameraPreview(),
          ],
        ),
      ),
    );
  }*/

  /* Widget _buildSelectedImagePreview() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_selectedImage!, fit: BoxFit.contain),
            ),
          ),
          //if (_isEditable) // Boutons seulement pour PM
          if (!widget.isViewOnly)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExistingImagePreview() {
    return GestureDetector(
      onTap: _showFullScreenImage,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _existingImageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
          ),
          //if (_isEditable) // Boutons seulement pour PM
          if (!widget.isViewOnly)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(cameras: _cameras),
                        ),
                      );
                      if (result != null && result is File) {
                        setState(() {
                          _selectedImage = result;
                          _existingImageUrl = null;
                        });
                      }
                    },
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                    onPressed:
                        () => setState(() {
                          _existingImageUrl = null;
                          _selectedImage = null;
                        }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }*/

  String _parseDate(String dateString) {
    try {
      final dateWithTime = DateFormat('dd/MM/yyyy, HH:mm:ss').parse(dateString);
      return DateFormat('yyyy-MM-dd').format(dateWithTime);
    } catch (e) {
      try {
        final isoDate = DateTime.parse(dateString);
        return DateFormat('yyyy-MM-dd').format(isoDate);
      } catch (e) {
        return DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem());
    });
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
      });
    } else {
      _items[0].descriptionController.clear();
      _items[0].quantityController.clear();
      _items[0].unitPriceController.clear();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateController.text.isNotEmpty
              ? DateTime.parse(_dateController.text)
              : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _updateFacture() async {
    // if (!_formKey.currentState!.validate()) return;
    // Vérifier d'abord si le formulaire est valide
    if (!_formKey.currentState!.validate()) {
      _showMessage(false, 'Veuillez remplir tous les champs obligatoires');
      return;
    }

    // Vérification supplémentaire des champs
    if (_companyController.text.isEmpty ||
        _invoiceNoController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _totalController.text.isEmpty ||
        _items.any(
          (item) =>
              item.descriptionController.text.isEmpty ||
              item.quantityController.text.isEmpty ||
              item.unitPriceController.text.isEmpty,
        )) {
      _showMessage(false, 'Veuillez remplir tous les champs');
      return;
    }

    setState(() {
      _isLoading = true;
      _showConfirmation = false;
    });

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '${ApiConfig.baseUrl}/api/invoices/updateinvoice/${widget.facture['_id']}',
        ),
      );

      request.fields.addAll({
        'invoice_no': _invoiceNoController.text,
        'date': _dateController.text,
        'total': _totalController.text,
        'company': _companyController.text,
        'address': _addressController.text,
        'currency': _selectedDevise,
        'items': json.encode(_items.map((item) => item.toMap()).toList()),
      });

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        _showMessage(true, 'Facture mise à jour avec succès');
        Navigator.pop(context, true);
      } else {
        _showMessage(
          false,
          jsonResponse['message'] ?? 'Échec de la mise à jour',
        );
      }
    } catch (e) {
      _showMessage(false, 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(bool success, String message) {
    setState(() {
      _showConfirmation = true;
      _requestSuccess = success;
      _confirmationMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showConfirmation = false);
      }
    });
  }

  /*Widget _buildCameraPreview() {
    // Seulement visible pour les PM
    if (widget.userRole != "PM") {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            'Aucune photo disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(cameras: _cameras),
          ),
        );

        if (result != null && result is File) {
          setState(() {
            _selectedImage = result;
          });
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            SizedBox(height: 10),
            Text('Appuyez pour prendre une photo'),
          ],
        ),
      ),
    );
  }*/

  List<Offset> _calculateGuideCorners() {
    final screenWidth = MediaQuery.of(context).size.width;
    return [
      Offset(screenWidth * _guideRect.left, 200 * _guideRect.top),
      Offset(screenWidth * _guideRect.right, 200 * _guideRect.top),
      Offset(screenWidth * _guideRect.right, 200 * _guideRect.bottom),
      Offset(screenWidth * _guideRect.left, 200 * _guideRect.bottom),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isViewOnly ? 'Consulter la facture' : 'Modifier la facture',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Container(
          width: isDesktop ? MediaQuery.of(context).size.width * 0.7 : null,
          constraints: isDesktop ? BoxConstraints(maxWidth: 1200) : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Image avec caméra
                  _buildImageSection(),
                  const SizedBox(height: 24),

                  // Section Informations principales - Disposition différente pour desktop
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
                          isDesktop
                              ? _buildDesktopInfoFields()
                              : _buildMobileInfoFields(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Détails financiers - Disposition différente pour desktop
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
                          isDesktop
                              ? _buildDesktopFinancialFields()
                              : _buildMobileFinancialFields(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Articles - Disposition différente pour desktop
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Articles",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              if (!widget.isViewOnly)
                                ElevatedButton.icon(
                                  onPressed: _addItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text("Ajouter un article"),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                        if (!widget.isViewOnly)
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
                                    isDesktop
                                        ? _buildDesktopItemFields(item)
                                        : _buildMobileItemFields(item),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton Enregistrer
                  if (!widget.isViewOnly)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateFacture,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Enregistrer les modifications',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  if (_showConfirmation)
                    Center(
                      child: Text(
                        _confirmationMessage,
                        style: TextStyle(
                          color: _requestSuccess ? Colors.green : Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Nouvelle méthode pour les champs d'info en mode desktop
  Widget _buildDesktopInfoFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
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
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color:
                      _isEditable
                          ? Colors.black
                          : const Color.fromRGBO(66, 66, 66, 1),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color:
                      _isEditable
                          ? Colors.black
                          : const Color.fromRGBO(97, 97, 97, 1),
                ),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
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
                ),
                enabled: !widget.isViewOnly,
                readOnly: !_isEditable,
                style: TextStyle(
                  color:
                      _isEditable
                          ? Colors.black
                          : const Color.fromRGBO(66, 66, 66, 1),
                ),
                onTap: () => _selectDate(context),
                validator: (value) => value!.isEmpty ? 'Champ requis' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Méthode pour les champs d'info en mode mobile
  Widget _buildMobileInfoFields() {
    return Column(
      children: [
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
          ),
          readOnly: !_isEditable,
          enabled: !widget.isViewOnly,
          style: TextStyle(
            color:
                _isEditable
                    ? Colors.black
                    : const Color.fromRGBO(66, 66, 66, 1),
          ),
          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
          ),
          enabled: !widget.isViewOnly,
          readOnly: !_isEditable,
          style: TextStyle(
            color:
                _isEditable
                    ? Colors.black
                    : const Color.fromRGBO(66, 66, 66, 1),
          ),
          onTap: () => _selectDate(context),
          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
          ),
          readOnly: !_isEditable,
          enabled: !widget.isViewOnly,
          style: TextStyle(
            color:
                _isEditable
                    ? Colors.black
                    : const Color.fromRGBO(97, 97, 97, 1),
          ),
          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
        ),
      ],
    );
  }

  // Nouvelle méthode pour les champs financiers en mode desktop
  Widget _buildDesktopFinancialFields() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
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
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color:
                      _isEditable
                          ? Colors.black
                          : const Color.fromRGBO(97, 97, 97, 1),
                ),
                validator: (value) {
                  if (value!.isEmpty) return 'Montant requis';
                  if (double.tryParse(value) == null)
                    return 'Nombre valide requis';
                  return null;
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
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color: _isEditable ? Colors.black : Colors.grey[800],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'adresse obligatoire';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedDevise,
                decoration: InputDecoration(
                  labelText: 'Devise',
                  prefixIcon: const Icon(Icons.currency_exchange),
                  fillColor:
                      _isEditable
                          ? lightInputDecorationTheme.fillColor
                          : Colors.grey[200],
                  filled: lightInputDecorationTheme.filled,
                  border: lightInputDecorationTheme.border,
                  enabledBorder: lightInputDecorationTheme.enabledBorder,
                  focusedBorder: lightInputDecorationTheme.focusedBorder,
                ),
                items:
                    [
                      _mainCurrency,
                      if (_secondaryCurrency.isNotEmpty &&
                          _secondaryCurrency != _mainCurrency)
                        _secondaryCurrency,
                    ].map((devise) {
                      return DropdownMenuItem(
                        value: devise,
                        child: Text(
                          devise,
                          style: TextStyle(
                            color:
                                _isEditable ? Colors.black : Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                onChanged:
                    _isEditable
                        ? (value) => setState(() => _selectedDevise = value!)
                        : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Méthode pour les champs financiers en mode mobile
  Widget _buildMobileFinancialFields() {
    return Column(
      children: [
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
          ),
          readOnly: !_isEditable,
          enabled: !widget.isViewOnly,
          style: TextStyle(
            color:
                _isEditable
                    ? Colors.black
                    : const Color.fromRGBO(97, 97, 97, 1),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Montant requis';
            if (double.tryParse(value) == null) return 'Nombre valide requis';
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDevise,
          decoration: InputDecoration(
            labelText: 'Devise',
            prefixIcon: const Icon(Icons.currency_exchange),
            fillColor:
                _isEditable
                    ? lightInputDecorationTheme.fillColor
                    : Colors.grey[200],
            filled: lightInputDecorationTheme.filled,
            border: lightInputDecorationTheme.border,
            enabledBorder: lightInputDecorationTheme.enabledBorder,
            focusedBorder: lightInputDecorationTheme.focusedBorder,
          ),
          items:
              [
                _mainCurrency,
                if (_secondaryCurrency.isNotEmpty &&
                    _secondaryCurrency != _mainCurrency)
                  _secondaryCurrency,
              ].map((devise) {
                return DropdownMenuItem(
                  value: devise,
                  child: Text(
                    devise,
                    style: TextStyle(
                      color: _isEditable ? Colors.black : Colors.grey[700],
                    ),
                  ),
                );
              }).toList(),
          onChanged:
              _isEditable
                  ? (value) => setState(() => _selectedDevise = value!)
                  : null,
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
          ),
          readOnly: !_isEditable,
          enabled: !widget.isViewOnly,
          style: TextStyle(
            color: _isEditable ? Colors.black : Colors.grey[800],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'adresse obligatoire';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Nouvelle méthode pour les champs d'article en mode desktop
  Widget _buildDesktopItemFields(InvoiceItem item) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: item.descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              prefixIcon: const Icon(Icons.description),
              fillColor: lightInputDecorationTheme.fillColor,
              filled: lightInputDecorationTheme.filled,
              border: lightInputDecorationTheme.border,
              enabledBorder: lightInputDecorationTheme.enabledBorder,
              focusedBorder: lightInputDecorationTheme.focusedBorder,
            ),
            readOnly: !_isEditable,
            enabled: !widget.isViewOnly,
            style: TextStyle(
              color: _isEditable ? Colors.black : Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: item.quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantité',
              prefixIcon: const Icon(Icons.numbers),
              fillColor: lightInputDecorationTheme.fillColor,
              filled: lightInputDecorationTheme.filled,
              border: lightInputDecorationTheme.border,
              enabledBorder: lightInputDecorationTheme.enabledBorder,
              focusedBorder: lightInputDecorationTheme.focusedBorder,
            ),
            readOnly: !_isEditable,
            enabled: !widget.isViewOnly,
            style: TextStyle(
              color: _isEditable ? Colors.black : Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: item.unitPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Prix unitaire',
              prefixIcon: const Icon(Icons.price_change),
              fillColor: lightInputDecorationTheme.fillColor,
              filled: lightInputDecorationTheme.filled,
              border: lightInputDecorationTheme.border,
              enabledBorder: lightInputDecorationTheme.enabledBorder,
              focusedBorder: lightInputDecorationTheme.focusedBorder,
            ),
            readOnly: !_isEditable,
            enabled: !widget.isViewOnly,
            style: TextStyle(
              color: _isEditable ? Colors.black : const Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }

  // Méthode pour les champs d'article en mode mobile
  Widget _buildMobileItemFields(InvoiceItem item) {
    return Column(
      children: [
        TextFormField(
          controller: item.descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            prefixIcon: const Icon(Icons.description),
            fillColor: lightInputDecorationTheme.fillColor,
            filled: lightInputDecorationTheme.filled,
            border: lightInputDecorationTheme.border,
            enabledBorder: lightInputDecorationTheme.enabledBorder,
            focusedBorder: lightInputDecorationTheme.focusedBorder,
          ),
          readOnly: !_isEditable,
          enabled: !widget.isViewOnly,
          style: TextStyle(
            color: _isEditable ? Colors.black : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: item.quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantité',
                  prefixIcon: const Icon(Icons.numbers),
                  fillColor: lightInputDecorationTheme.fillColor,
                  filled: lightInputDecorationTheme.filled,
                  border: lightInputDecorationTheme.border,
                  enabledBorder: lightInputDecorationTheme.enabledBorder,
                  focusedBorder: lightInputDecorationTheme.focusedBorder,
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color: _isEditable ? Colors.black : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: item.unitPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Prix unitaire',
                  prefixIcon: const Icon(Icons.price_change),
                  fillColor: lightInputDecorationTheme.fillColor,
                  filled: lightInputDecorationTheme.filled,
                  border: lightInputDecorationTheme.border,
                  enabledBorder: lightInputDecorationTheme.enabledBorder,
                  focusedBorder: lightInputDecorationTheme.focusedBorder,
                ),
                readOnly: !_isEditable,
                enabled: !widget.isViewOnly,
                style: TextStyle(
                  color: _isEditable ? Colors.black : const Color(0xFF424242),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ... [Le reste des méthodes reste inchangé] ...
}

class DocumentBoundaryPainter extends CustomPainter {
  final List<Offset> corners;
  final bool documentDetected;

  DocumentBoundaryPainter({
    required this.corners,
    required this.documentDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = documentDetected ? Colors.green : Colors.yellow
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke;

    if (corners.length == 4) {
      final path = Path();
      path.moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);

      final dotPaint =
          Paint()
            ..color = documentDetected ? Colors.green : Colors.yellow
            ..style = PaintingStyle.fill;

      for (var corner in corners) {
        canvas.drawCircle(corner, 12.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(DocumentBoundaryPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.documentDetected != documentDetected;
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0], // Utilisez la caméra arrière
      ResolutionPreset.high,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print("Erreur initialisation caméra: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady) return;

    try {
      final XFile file = await _controller.takePicture();
      Navigator.pop(context, File(file.path));
    } catch (e) {
      print("Erreur prise de photo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prendre une photo')),
      body: Stack(
        children: [
          if (_isCameraReady) CameraPreview(_controller),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Écran de caméra simplifié
class SimpleCameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SimpleCameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _SimpleCameraScreenState createState() => _SimpleCameraScreenState();
}

class _SimpleCameraScreenState extends State<SimpleCameraScreen> {
  late CameraController _controller;
  bool _isCameraReady = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Utiliser la caméra arrière par défaut
    final backCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      print("Erreur initialisation caméra: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur initialisation caméra: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _controller.takePicture();
      Navigator.pop(context, File(file.path));
    } catch (e) {
      print("Erreur prise de photo: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur prise de photo: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('S'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_isCameraReady)
            Positioned.fill(child: CameraPreview(_controller))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Bouton de capture
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey, width: 4),
                  ),
                  child:
                      _isProcessing
                          ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                          : const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
