import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/pages/chat/provider/tensorflow_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class TensorFlowLitePage extends StatefulWidget {
  const TensorFlowLitePage({Key? key}) : super(key: key);

  @override
  State<TensorFlowLitePage> createState() => _TensorFlowLitePageState();
}

class _TensorFlowLitePageState extends State<TensorFlowLitePage> {
  Uint8List? _image;
  String _classificationResult = '';
  String _aiResponse = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _image = bytes;
      });

      // Clasificar imagen
      final tensorflowService = context.read<TensorflowProvider>();
      final result = await tensorflowService.classifyImage(_image!);
      setState(() {
        _classificationResult = 'Resultado: $result';
      });
    }
  }

  Future<void> _askAI(String prompt) async {
    final tensorflowService = context.read<TensorflowProvider>();
    final response = await tensorflowService.getResponseFromVertexAI(prompt);
    setState(() {
      _aiResponse = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter TensorFlow')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Cargar Imagen'),
            ),
            if (_image != null)
              Image.memory(
                _image!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Text(_classificationResult),
            const SizedBox(height: 16),
            TextField(
              onSubmitted: _askAI,
              decoration: const InputDecoration(
                labelText: 'Escribe tu pregunta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Respuesta de IA: $_aiResponse'),
          ],
        ),
      ),
    );
  }
}