// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/controller/permision.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:excel/excel.dart';
import 'package:permission_handler/permission_handler.dart';

class CodeBarrasPage extends StatefulWidget {
  const CodeBarrasPage({super.key});

  @override
  State<CodeBarrasPage> createState() => _CodeBarrasPageState();
}

class _CodeBarrasPageState extends State<CodeBarrasPage> {
  dynamic pickedImage;
  String result = '';
  List<Map<String, String>> products = [];
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
        final imagePath = _result!.images.first;
        final inputImage = InputImage.fromFilePath(imagePath);
        final barcodeScanner = BarcodeScanner();
        final List<Barcode> barcodes =
            await barcodeScanner.processImage(inputImage);

        if (barcodes.isNotEmpty) {
          final barcodeValue = barcodes.first.displayValue;
          _showAddProductDialog(barcodeValue);
        }

        barcodeScanner.close();

        setState(() {
          pickedImage = File(imagePath);
          result = '';
        });
      }
      setState(() {});
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showAddProductDialog(String? barcode) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Producto'),
              ),
              TextField(
                controller: TextEditingController(text: barcode),
                decoration:
                    const InputDecoration(labelText: 'Código de Barras'),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  products.add({
                    'name': nameController.text,
                    'barcode': barcode ?? '',
                  });
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> downloadExcel() async {
    requestStoragePermission(context);

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      sheetObject.appendRow([
        TextCellValue('Nombre del Producto'),
        TextCellValue('Código de Barras'),
      ]);
      for (var product in products) {
        sheetObject.appendRow([
          TextCellValue(product['name']!),
          TextCellValue(product['barcode']!),
        ]);
      }

      final excelFile = File('${directory.path}/Inventario.xlsx');
      await excelFile.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se guardó Excel en ${excelFile.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Inventario', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: downloadExcel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            if (pickedImage != null)
              Center(
                child: Container(
                  height: 250.0,
                  width: 250.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                          image: FileImage(pickedImage!), fit: BoxFit.cover)),
                ),
              ),
            const SizedBox(height: 30),
            ListView.builder(
              shrinkWrap: true,
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(products[index]['name']!),
                  subtitle: Text(products[index]['barcode']!),
                );
              },
            ),
          ],
        ),
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
