import 'package:flutter/material.dart';
import 'package:flutter_ml_kit/src/pages/chat/provider/tensorflow_provider.dart';
import 'package:flutter_ml_kit/src/pages/chat/provider/vertex_ai_provider.dart';
import 'package:flutter_ml_kit/src/pages/home_screen.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final vertexAiProvider = VertexAiProvider();
  vertexAiProvider.initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TensorflowProvider()),
        ChangeNotifierProvider(create: (_) => VertexAiProvider()..initializeService()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Machine Learning Kit',
        home: HomeScreen(),
      ),
    );
  }
}
