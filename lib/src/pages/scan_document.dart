// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/controller/permision.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentScannerView extends StatefulWidget {
  const DocumentScannerView({super.key});

  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  DocumentScanner? _documentScanner;
  DocumentScanningResult? _result;
  final List<String> _dniImages = [];
  String? _pdfPath;

  @override
  void dispose() {
    _documentScanner?.close();
    super.dispose();
    requestStoragePermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Document Scanner',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                _elevatedButtonWidget(
                  "Scanear PDF",
                  () => startScan(DocumentFormat.pdf),
                ),
                const SizedBox(width: 8),
                _elevatedButtonWidget(
                  "Scanear PNG",
                  () => startScan(DocumentFormat.jpeg),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 10),
            _elevatedButtonWidget(
              "Scanear DNI",
              () => scanDNI('anverso'),
            ),
            const SizedBox(height: 10),
            if (_pdfPath != null) ...[
              _elevatedButtonWidget(
                "Download PDF",
                () => downloadPDF(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void startScan(DocumentFormat format) async {
    try {
      _result = null;
      _pdfPath = null;
      setState(() {});
      _documentScanner?.close();
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: format,
          mode: ScannerMode.full,
          isGalleryImport: false,
          pageLimit: 1,
        ),
      );
      _result = await _documentScanner?.scanDocument();
      print('result: $_result');
      if (_result != null && _result!.images.isNotEmpty) {
        await recognizeTextAndGeneratePDF(_result!.images.first);
      }
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  void scanDNI(String side) async {
    try {
      _result = null;
      setState(() {});
      _documentScanner?.close();
      _documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormat: DocumentFormat.jpeg,
          mode: ScannerMode.full,
          isGalleryImport: false,
          pageLimit: 1,
        ),
      );
      _result = await _documentScanner?.scanDocument();
      print('result: $_result');
      if (_result != null && _result!.images.isNotEmpty) {
        if (side == 'anverso') {
          _dniImages.insert(0, _result!.images.first);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Ahora toma una foto del reverso del DNI')),
          );
          Future.delayed(const Duration(seconds: 2), () {
            scanDNI('reverso');
          });
        } else {
          _dniImages.add(_result!.images.first);
          await generateDNIPDF();
        }
      }
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> recognizeTextAndGeneratePDF(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    if (recognizedText.text.isNotEmpty) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Text(recognizedText.text),
          ),
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/recognized_text.pdf");
      await file.writeAsBytes(await pdf.save());
      _pdfPath = file.path;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto reconocido y PDF generado')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo reconocer texto en la imagen')),
      );
    }
    setState(() {});
  }

  Future<void> generatePDF(List<String> images) async {
    final pdf = pw.Document();
    for (var imagePath in images) {
      final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Center(
            child: pw.Image(image),
          ),
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/document.pdf");
    await file.writeAsBytes(await pdf.save());
    _pdfPath = file.path;
  }

  Future<void> generateDNIPDF() async {
    final pdf = pw.Document();
    if (_dniImages.length == 2) {
      final image1 = pw.MemoryImage(File(_dniImages[0]).readAsBytesSync());
      final image2 = pw.MemoryImage(File(_dniImages[1]).readAsBytesSync());
      pdf.addPage(
        pw.Page(
          textDirection: pw.TextDirection.ltr,
          build: (pw.Context context) => pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Image(image1, width: 400, height: 300),
                pw.SizedBox(height: 40),
                pw.Image(image2, width: 400, height: 300),
              ],
            ),
          ),
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/dni_document.pdf");
    await file.writeAsBytes(await pdf.save());
    _pdfPath = file.path;
    setState(() {});
  }

  Future<void> downloadPDF() async {
    requestStoragePermission(context);
    if (_pdfPath == null) return;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_pdfPath!);
      final newFile = await file.copy('${directory.path}/document.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se guardo PDF en ${newFile.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
    }
  }

  Widget _elevatedButtonWidget(
    String text,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(Colors.indigo),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
