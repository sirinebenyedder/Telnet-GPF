import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:Telnet/screens/addInvoice/ML_invoice.dart';
import 'package:Telnet/screens/addInvoice/manuel_invoice.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class CameraScreen extends StatefulWidget {
  final String? userId;

  const CameraScreen({
    super.key,
    required this.userId,
    //required List<CameraDescription> cameras,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? controller;
  bool isInitialized = false;
  bool isCameraReady = false;
  bool isProcessing = false;

  // Variables pour la détection
  List<Offset>? _corners;
  bool _documentDetected = false;
  bool _processingFrame = false;
  int _frameCount = 0;

  // Rectangle de guidage agrandi pour mieux capturer les factures
  final Rect _guideRect = const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95);

  @override
  void initState() {
    super.initState();
    // Forcer l'orientation portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _corners = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeController(cameraController.description);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        CameraDescription? backCamera;
        for (var camera in cameras) {
          if (camera.lensDirection == CameraLensDirection.back) {
            backCamera = camera;
            break;
          }
        }
        await _initializeController(backCamera ?? cameras[0]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune caméra disponible')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _initializeController(
    CameraDescription cameraDescription,
  ) async {
    final CameraController cameraController = CameraController(
      cameraDescription,
      // éviter les problèmes de mémoire
      ResolutionPreset.high, //resolution behya ama mouch max
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    try {
      await cameraController.initialize();

      // Démarrer le flux d'images pour la détection
      await cameraController.startImageStream(_processImageStream);

      setState(() {
        isInitialized = true;
        isCameraReady = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'initialisation de la caméra: $e'),
        ),
      );
    }
  }

  // Traitement du flux d'images pour la détection en temps réel
  void _processImageStream(CameraImage imageStream) async {
    _frameCount++;
    if (_frameCount % 15 != 0) return;

    if (_processingFrame) return;
    _processingFrame = true;

    try {
      final brightnessSample = _sampleImageBrightness(imageStream);
      final isDocumentDetected = brightnessSample > 0.6;

      if (mounted) {
        setState(() {
          _documentDetected = isDocumentDetected;
        });
      }
    } catch (e) {
      print('Erreur de traitement: $e');
    } finally {
      _processingFrame = false;
    }
  }

  double _sampleImageBrightness(CameraImage image) {
    try {
      final bytes = image.planes[0].bytes;
      final stride = image.planes[0].bytesPerRow;
      final height = image.height;
      final width = image.width;

      final centerX = width ~/ 2;
      final centerY = height ~/ 2;
      final sampleWidth = (width * 0.3).toInt();
      final sampleHeight = (height * 0.3).toInt();
      final startX = centerX - sampleWidth ~/ 2;
      final startY = centerY - sampleHeight ~/ 2;
      final endX = centerX + sampleWidth ~/ 2;
      final endY = centerY + sampleHeight ~/ 2;
      int sum = 0;
      int count = 0;

      for (int y = startY; y < endY; y += 2) {
        for (int x = startX; x < endX; x += 2) {
          if (y >= 0 && y < height && x >= 0 && x < width) {
            sum += bytes[y * stride + x];
            count++;
          }
        }
      }

      // Normaliser entre 0 et 1
      return count > 0 ? (sum / count) / 255.0 : 0.0;
    } catch (e) {
      print("Erreur lors de l'échantillonnage de la luminosité: $e");
      return 0.0; // Valeur par défaut en cas d'erreur
    }
  }

  Future<void> _takePicture() async {
    if (controller == null ||
        !controller!.value.isInitialized ||
        isProcessing) {
      return;
    }
    await controller!.stopImageStream();

    setState(() {
      isProcessing = true;
    });

    try {
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
                        "Traitement de la facture en cours...",
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

      // Prendre la photo
      final XFile originalImage = await controller!.takePicture();

      // Ajouter un délai court pour donner le temps au système de libérer des ressources
      await Future.delayed(const Duration(milliseconds: 100));

      final File processedImage = await _processInvoiceImage(
        File(originalImage.path),
      );

      // Naviguer vers l'écran de facture avec l'image traitée
      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de chargement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => AddInvoiceML(
                  userId: widget.userId,
                  initialImage: processedImage,
                ),
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la prise de photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<File> _processInvoiceImage(File imageFile) async {
    try {
      // Charger l'image avec le package image
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception("Impossible de décoder l'image");
      }
      final imageWidth = originalImage.width;
      final imageHeight = originalImage.height;

      // Calculer les coordonnées du cadre dans l'image
      final cropX = (imageWidth * 0.05).round();
      final cropY = (imageHeight * 0.05).round();
      final cropWidth = (imageWidth * 0.9).round();
      final cropHeight = (imageHeight * 0.9).round();

      // Rogner l'image pour ne garder que la zone du cadre
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
        croppedImage =
            originalImage; // En cas d'erreur, utiliser l'image originale
      }

      croppedImage = img.grayscale(croppedImage);
      croppedImage = img.contrast(croppedImage, contrast: 150);

      // Sauvegarder l'image traitée
      final tempDir = await getTemporaryDirectory();
      final processedFilePath =
          '${tempDir.path}/processed_invoice_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(processedFilePath);

      // Utiliser JPEG au lieu de PNG pour réduire la taille du fichier et éviter les problèmes de mémoire
      await processedFile.writeAsBytes(
        img.encodeJpg(croppedImage, quality: 85),
      );

      return processedFile;
    } catch (e) {
      print("Erreur lors du traitement de l'image: $e");
      // En cas d'erreur, retourner l'image originale non traitée
      return imageFile;
    }
  }

  // Obtenir la boîte englobante des coins
  Rect _getBoundingBox(List<Offset> points) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final point in points) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _skipToManualInvoice() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddInvoiceManuelle(userId: widget.userId),
      ),
    );
  }

  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized || !isCameraReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;

    final corners = [
      Offset(
        screenSize.width * _guideRect.left,
        screenSize.height * _guideRect.top,
      ),
      Offset(
        screenSize.width * _guideRect.right,
        screenSize.height * _guideRect.top,
      ),
      Offset(
        screenSize.width * _guideRect.right,
        screenSize.height * _guideRect.bottom,
      ),
      Offset(
        screenSize.width * _guideRect.left,
        screenSize.height * _guideRect.bottom,
      ),
    ];

    // Utiliser les coins calculés pour l'affichage
    _corners = corners;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Aperçu de la caméra en plein écran
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: CameraPreview(controller!),
          ),

          // Overlay pour dessiner les coins détectés - toujours affiché
          Positioned.fill(
            child: CustomPaint(
              painter: DocumentBoundaryPainter(
                corners: corners,
                documentDetected: _documentDetected,
              ),
            ),
          ),

          // Bouton retour en haut à gauche
          Positioned(
            top: 20,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.5),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goBack,
              ),
            ),
          ),

          // Bouton Skip en haut à droite
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _skipToManualInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Passer",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Message d'instruction
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          // Bouton de capture en bas
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _documentDetected
                              ? Colors.green
                              : Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            _documentDetected
                                ? Colors.green
                                : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
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
          ..strokeWidth =
              5.0 // Ligne plus épaisse pour meilleure visibilité
          ..style = PaintingStyle.stroke;

    if (corners.length == 4) {
      final path = Path();
      path.moveTo(corners[0].dx, corners[0].dy);
      for (int i = 1; i < corners.length; i++) {
        path.lineTo(corners[i].dx, corners[i].dy);
      }
      path.close();
      canvas.drawPath(path, paint);

      // Dessiner des cercles aux coins pour une meilleure visualisation
      final dotPaint =
          Paint()
            ..color = documentDetected ? Colors.green : Colors.yellow
            ..style = PaintingStyle.fill;

      for (var corner in corners) {
        canvas.drawCircle(
          corner,
          12.0,
          dotPaint,
        ); // Cercles plus grands pour meilleure visibilité
      }
    }
  }

  @override
  bool shouldRepaint(DocumentBoundaryPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.documentDetected != documentDetected;
  }
}
