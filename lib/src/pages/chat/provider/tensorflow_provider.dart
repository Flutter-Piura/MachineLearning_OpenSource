import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;

class TensorflowProvider with ChangeNotifier {
  late Interpreter _interpreter;

  TensorflowProvider() {
    _loadModel();
  }

  // Método para cargar el modelo
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      debugPrint('Modelo cargado correctamente');
    } catch (e) {
      debugPrint('Error al cargar el modelo: $e');
    }
  }

  // Método para clasificar imágenes
  Future<List<dynamic>> classifyImage(Uint8List imageData) async {
    try {
      // Preprocesar imagen (ajusta según tu modelo)
      var input = _preprocessImage(imageData);
      var output = List.filled(1 * 1001, 0).reshape([1, 1001]);

      _interpreter.run(input, output);

      debugPrint('Resultado: $output');
      return output;
    } catch (e) {
      debugPrint('Error durante la clasificación: $e');
      return [];
    }
  }

  // Método auxiliar para preprocesar la imagen
  List<List<List<double>>> _preprocessImage(Uint8List imageData) {
    // Aquí puedes implementar el preprocesamiento según tu modelo
    // Por ejemplo, cambiar tamaño, normalizar valores, etc.
    // Devolveré un dummy para que funcione:
    return [
      [
        [0.0, 0.0, 0.0],
        [0.0, 0.0, 0.0]
      ]
    ];
  }

  // Método para consumir Vertex AI
  Future<String> getResponseFromVertexAI(String prompt) async {
    const apiUrl = 'https://your-vertex-endpoint';
    const apiKey = 'your-api-key';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $apiKey'},
        body: json.encode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body)['content'];
        debugPrint('Respuesta de Vertex AI: $result');
        return result;
      } else {
        debugPrint('Error de Vertex AI: ${response.body}');
        return 'Error: ${response.body}';
      }
    } catch (e) {
      debugPrint('Error al conectar con Vertex AI: $e');
      return 'Error de conexión';
    }
  }
}
