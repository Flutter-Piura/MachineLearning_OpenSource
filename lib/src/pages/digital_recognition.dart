// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart' hide Ink;
import 'package:flutter_ml_kit/src/controller/description_controller.dart';
import 'package:flutter_ml_kit/src/pages/activity_indicator/activity_indicator.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/services.dart';

class DigitalInkView extends StatefulWidget {
  const DigitalInkView({super.key});

  @override
  State<DigitalInkView> createState() => _DigitalInkViewState();
}

class _DigitalInkViewState extends State<DigitalInkView> {
  final _digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'en');
  final DigitalInkRecognizerModelManager _modelManager =
      DigitalInkRecognizerModelManager();
  final Ink _ink = Ink();
  List<StrokePoint> _points = [];
  String _recognizedText = '';
  String _description = '';
  final DescriptionController _descriptionController = DescriptionController();

  @override
  void dispose() {
    _digitalInkRecognizer.close();
    super.dispose();
    _downloadModel();
  }

  Future<void> _downloadModel() async {
    Toast().show(
        'Descargando modelo...',
        _modelManager
            .downloadModel('en')
            .then((value) => value ? 'éxito' : 'fallo'),
        context,
        this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Reconocimiento de tinta digital',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.indigo,
                    textColor: Colors.white,
                    onPressed: _recogniseText,
                    child: const Text('Reconocer texto'),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    color: Colors.indigo,
                    textColor: Colors.white,
                    onPressed: _clearPad,
                    child: const Text('Limpiar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  _ink.strokes.add(Stroke());
                },
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    final RenderObject? object = context.findRenderObject();
                    final localPosition = (object as RenderBox?)
                        ?.globalToLocal(details.localPosition);
                    if (localPosition != null) {
                      _points = List.from(_points)
                        ..add(StrokePoint(
                          x: localPosition.dx,
                          y: localPosition.dy,
                          t: DateTime.now().millisecondsSinceEpoch,
                        ));
                    }
                    if (_ink.strokes.isNotEmpty) {
                      _ink.strokes.last.points = _points.toList();
                    }
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  _points.clear();
                  setState(() {});
                },
                child: CustomPaint(
                  painter: Signature(ink: _ink),
                  size: Size.infinite,
                ),
              ),
            ),
            if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Panel: $_recognizedText',
                      style: const TextStyle(fontSize: 23),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descripción: $_description',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    MaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      color: Colors.indigo,
                      textColor: Colors.white,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _description));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Descripción copiada al portapapeles'),
                          ),
                        );
                      },
                      child: const Text('Copiar descripción'),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearPad() {
    setState(() {
      _ink.strokes.clear();
      _points.clear();
      _recognizedText = '';
      _description = '';
    });
  }

  Future<void> _recogniseText() async {
    //si no hay nada escrito en el pad no se hace nada y se muestra un mensaje
    if (_ink.strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay texto para reconocer.'),
        ),
      );
      return;
    }

    showDialog(
        context: context,
        builder: (context) => const AlertDialog(
              title: Text('Reconociendo...'),
            ),
        barrierDismissible: true);
    try {
      final candidates = await _digitalInkRecognizer.recognize(_ink);
      if (candidates.isNotEmpty) {
        _recognizedText = candidates.first.text;
      } else {
        _recognizedText = 'No se reconoció texto.';
      }
      _generateDescription();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
      print("ERROR: $e");
    }
    Navigator.pop(context);
  }

  void _generateDescription() {
    // Aquí puedes agregar lógica para generar una descripción basada en el texto reconocido
    _description = _descriptionController.getDescription(_recognizedText);
  }
}

class Signature extends CustomPainter {
  Ink ink;

  Signature({required this.ink});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (final stroke in ink.strokes) {
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(Offset(p1.x.toDouble(), p1.y.toDouble()),
            Offset(p2.x.toDouble(), p2.y.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => true;
}
