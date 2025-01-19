import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/pages/chat/provider/vertex_ai_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ChatBoxVertexAi extends StatefulWidget {
  const ChatBoxVertexAi({super.key});

  @override
  State<ChatBoxVertexAi> createState() => _ChatBoxVertexAiState();
}

class _ChatBoxVertexAiState extends State<ChatBoxVertexAi> {
  late StreamSubscription _chatSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _chatSubscription = Provider.of<VertexAiProvider>(context, listen: false).messagesStream.listen((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatSubscription.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    final vertexAiProvider = Provider.of<VertexAiProvider>(context, listen: false);
    await vertexAiProvider.initializeService();
    vertexAiProvider.setServiceInitialized(true);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vertexAiProvider = Provider.of<VertexAiProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Chatbot con Vertex AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: vertexAiProvider.messages.length,
              itemBuilder: (context, index) {
                final message = vertexAiProvider.messages[index];
                return ListTile(
                  title: SelectableText(
                    message.keys.first == "user" ? "USUARIO" : "GEMINI",
                    style: TextStyle(
                      color: message.keys.first == "user" ? Colors.blue : Colors.red,
                    ),
                  ),
                  subtitle: SelectableText.rich(
                    vertexAiProvider.buildTextSpan(message.values.first),
                  ),
                );
              },
            ),
          ),
          if (vertexAiProvider.selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.memory(
                vertexAiProvider.selectedImage!,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: vertexAiProvider.formKey,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: vertexAiProvider.promptController,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Ingrese un mensaje";
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) => vertexAiProvider.sendMessage(context),
                      decoration: InputDecoration(
                        hintText: "Escribe un mensaje",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => vertexAiProvider.sendMessage(context),
                    icon: Icon(Icons.send),
                  ),
                  IconButton(
                    onPressed: () => vertexAiProvider.pickImage(),
                    icon: Icon(Icons.image),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
