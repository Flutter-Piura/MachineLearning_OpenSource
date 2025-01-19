// ignore_for_file: library_private_types_in_public_api, file_names, unnecessary_null_comparison

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:translator/translator.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String selectedItem = '';
  File? pickedImage;
  dynamic imageFile;
  String result = '';
  bool isImageLoaded = false;
  bool isFaceDetected = false;
  List<Rect> rect = [];
  int faceCount = 0;
  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
  }

  Future<void> startScan(DocumentFormat format) async {
    try {
      _result = null;
      setState(() {});
      _documentScanner?.close();
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: format,
          mode: ScannerMode.full,
          isGalleryImport: true,
          pageLimit: 1,
        ),
      );
      _result = await _documentScanner?.scanDocument();
      if (_result != null && _result!.images.isNotEmpty) {
        final bytes = await File(_result!.images.first).readAsBytes();
        final decodedImage = await decodeImageFromList(bytes);

        setState(() {
          pickedImage = File(_result!.images.first);
          imageFile = decodedImage;
          isImageLoaded = true;
          isFaceDetected = false;
          faceCount = 0;
        });

        // Llama a la función de detección automáticamente después de cargar la imagen
        detectMLFeature(selectedItem);
      }
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  // leer texto de la imagen
  Future<void> readTextFromImage() async {
    if (pickedImage == null) return;

    final inputImage = InputImage.fromFilePath(pickedImage!.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    setState(() {
      result = recognizedText.text;
    });

    textRecognizer.close();
  }


  // detectar etiquetas en la imagen ejemplo: perro, gato, etc
  Future<void> labelsRead() async {
    if (pickedImage == null) return;

    final inputImage = InputImage.fromFile(pickedImage!);
    final imageLabeler = ImageLabeler(options: ImageLabelerOptions());
    final List<ImageLabel> labels = await imageLabeler.processImage(inputImage);

    final translator = GoogleTranslator();

    const double confidenceThreshold = 0.5;

    final translatedLabels = await Future.wait(labels.map((label) async {
      if (label.confidence < confidenceThreshold) {
        return null;
      }
      final translation =
          await translator.translate(label.label, from: 'en', to: 'es');
      final confidence =
          (label.confidence * 100).clamp(1, 100).toStringAsFixed(2);
      return '${translation.text} $confidence%';
    }).where((label) => label != null));

    setState(() {
      result = translatedLabels.join('\n');
    });

    imageLabeler.close();
  }

  // detectar rostros en la imagen
  Future<void> detectFace() async {
    if (pickedImage == null) return;

    final inputImage = InputImage.fromFile(pickedImage!);
    final faceDetector = FaceDetector(options: FaceDetectorOptions());
    final List<Face> faces = await faceDetector.processImage(inputImage);

    setState(() {
      rect = faces.map((face) => face.boundingBox).toList();
      isFaceDetected = true;
      faceCount = faces.length;
    });

    faceDetector.close();
  }

  void detectMLFeature(String selectedFeature) {
    switch (selectedFeature) {
      case 'Escáner de texto':
        readTextFromImage();
        break;
      case 'Escáner de etiquetas':
        labelsRead();
        break;
      case 'Detección de rostros':
        detectFace();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    selectedItem = ModalRoute.of(context)!.settings.arguments.toString();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(selectedItem, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          isImageLoaded && !isFaceDetected
              ? Center(
                  child: Container(
                    height: 250.0,
                    width: 250.0,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                            image: FileImage(pickedImage!), fit: BoxFit.cover)),
                  ),
                )
              : isImageLoaded && isFaceDetected
                  ? Center(
                      child: FittedBox(
                        child: SizedBox(
                          width: imageFile.width.toDouble(),
                          height: imageFile.height.toDouble(),
                          child: CustomPaint(
                            painter:
                                FacePainter(rect: rect, imageFile: imageFile),
                          ),
                        ),
                      ),
                    )
                  : Container(),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(result),
                    if (selectedItem == 'Escáner de texto' && result.isNotEmpty)
                      MaterialButton(
                        color: Colors.indigo,
                        textColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: result));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Texto copiado')),
                          );
                        },
                        child: const Text('Copiar texto'),
                      ),
                    if (selectedItem == 'Detección de rostros' &&
                        isFaceDetected)
                      Text('Hay $faceCount personas detectadas'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'gallery',
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            backgroundColor: Colors.indigo,
            onPressed: () {
              startScan(DocumentFormat.jpeg);
            },
            child: const Icon(
              Icons.photo,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'camera',
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100)),
            backgroundColor: Colors.indigo,
            onPressed: () {
              startScan(DocumentFormat.jpeg);
            },
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Rect> rect;
  final dynamic imageFile;

  FacePainter({required this.rect, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    for (Rect rectangle in rect) {
      canvas.drawRect(
        rectangle,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
