import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class VertexAiService {
  final String _projectId = "machinelearning---flutterpiura";
  final String _location = "us-central1";
  final String _modelId = "gemini-2.0-flash-exp";
  final String fileJson = "assets/api_vertex.json";

  late AccessCredentials _credentials;

  Future<void> initilizeApiVertex() async {
    try {
      final fileContent = await rootBundle.loadString(fileJson);
      print("Contenido del archivo JSON: $fileContent");

      final accountCredentials = ServiceAccountCredentials.fromJson(json.decode(fileContent));

      _credentials = await obtainAccessCredentialsViaServiceAccount(
        accountCredentials,
        [
          "https://www.googleapis.com/auth/cloud-platform",
          //"https://www.googleapis.com/auth/cloud-vertex-ai",
        ],
        http.Client(),
      );
      print("Credentials: $_credentials");
    } catch (e) {
      print("Error initializing API: $e");
      rethrow;
    }
  }

  Stream<String> getResponseAi(String prompt, Uint8List? imageBytes) async* {
    if (_credentials == null) {
      throw Exception('API no inicializada. Llama a initilizeApi() primero.');
    }

    final endpoint =
        "https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/google/models/$_modelId:streamGenerateContent";

    final contents = [
      {
        "role": "user",
        "parts": [
          {
            "text": prompt,
          }
        ]
      }
    ];

    if (imageBytes != null) {
      final base64Image = base64Encode(imageBytes);
      print("Imagen en base64: $base64Image");
      contents.add({
        "role": "user",
        "parts": [
          {
            "inlineData": {
              "mimeType": "image/jpeg",
              "data": base64Image,
            }
          }
        ]
      });
    }

    final response = await http.post(Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer ${_credentials.accessToken.data}",
        },
        body: jsonEncode({
          "contents": contents,
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 800,
            "topP": 0.9,
            "topK": 40,
          },
        }));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Response: ${data}");

      if (data is List && data.isNotEmpty) {
        for (var item in data) {
          for (var candidate in item['candidates']) {
            for (var part in candidate['content']['parts']) {
              yield part['text'];
            }
          }
        }
      } else {
        throw Exception('Estructura de respuesta inesperada: ${response.body}');
      }
    } else {
      print("Error: ${response.body}");
      throw Exception('Error al cargar la respuesta: ${response.body}');
    }
  }
}
