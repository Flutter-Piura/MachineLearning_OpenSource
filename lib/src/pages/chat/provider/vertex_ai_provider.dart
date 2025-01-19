import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/pages/chat/services/vertex_ai_service.dart';
import 'package:flutter_ml_kit/src/utils/utils_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class VertexAiProvider with ChangeNotifier {
  final VertexAiService _vertexAiService = VertexAiService();
  bool _isInitialized = false;

  VertexAiService get vertexAiService => _vertexAiService;
  bool get isInitialized => _isInitialized;

  final promptController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  List<Map<String, String>> _messages = [];
  List<Map<String, String>> get messages => _messages;

  bool _isServiceInitialized = false;
  bool get isServiceInitialized => _isServiceInitialized;
  Uint8List? _selectedImage;
  Uint8List? get selectedImage => _selectedImage;

  final StreamController<List<Map<String, String>>> _messagesStreamController = StreamController.broadcast();
  Stream<List<Map<String, String>>> get messagesStream => _messagesStreamController.stream;

  void setServiceInitialized(bool value) {
    _isServiceInitialized = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      _selectedImage = bytes;
      notifyListeners();
    }
  }

  Future<void> initializeService() async {
    try {
      await _vertexAiService.initilizeApiVertex();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print("Error initializing Vertex AI Service: $e");
    }
  }

  Stream<String> getResponse(String prompt, Uint8List? selectedImage) {
    if (!_isInitialized) {
      throw Exception('El servicio no está inicializado. Llama a initializeService() primero.');
    }
    return _vertexAiService.getResponseAi(prompt, selectedImage);
  }

  void sendMessage(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      showSnackbar(context, "Ingrese un mensaje");
      return;
    }

    if (!_isServiceInitialized) {
      showSnackbar(context, "El servicio no está inicializado. Por favor, espera.");
      return;
    }

    final message = promptController.text;
    if (message.isEmpty) return;

    _messages.add({"user": message});
    _messagesStreamController.add(_messages); // Emitir los mensajes actualizados
    notifyListeners();
    promptController.clear();

    try {
      String accumulatedResponse = "";
      await for (var response in getResponse(message, _selectedImage)) {
        accumulatedResponse += response;
        // Actualiza el último mensaje de Gemini con la respuesta acumulada
        if (_messages.isNotEmpty && _messages.last.keys.first == "Gemini") {
          _messages.last = {"Gemini": accumulatedResponse};
        } else {
          _messages.add({"Gemini": accumulatedResponse});
        }
        _messagesStreamController.add(_messages); // Emitir los mensajes actualizados
        notifyListeners();
      }
      _selectedImage = null;
    } catch (e) {
      _messages.add({"Gemini": "Error: $e"});
      _messagesStreamController.add(_messages); // Emitir los mensajes actualizados
      notifyListeners();
      print(e);
    }
  }

//para las respuestas
  TextSpan buildTextSpan(String text) {
    final RegExp exp = RegExp(r"\*\*(.*?)\*\*");
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: TextStyle(color: Colors.black)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: TextStyle(color: Colors.black)));
    }

    return TextSpan(children: spans);
  }

  @override
  void dispose() {
    _messagesStreamController.close();
    super.dispose();
  }
}
