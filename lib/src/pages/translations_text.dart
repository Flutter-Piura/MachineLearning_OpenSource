// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:translator/translator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LanguageTranslatorView extends StatefulWidget {
  const LanguageTranslatorView({super.key});

  @override
  State<LanguageTranslatorView> createState() => _LanguageTranslatorViewState();
}

class _LanguageTranslatorViewState extends State<LanguageTranslatorView> {
  String? _translatedText;
  final _controller = TextEditingController();
  final translator = GoogleTranslator();
  var _sourceLanguage = 'en';
  var _targetLanguage = 'es';
  String? _pdfPath;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Google Translation',
              style: TextStyle(color: Colors.white)),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              Center(child: Text('Traducir de: $_sourceLanguage')),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ingrese el texto a traducir',
                  labelText: "Ingresa el Texto",
                  labelStyle: const TextStyle(color: Colors.indigo),
                  hintStyle: TextStyle(color: Colors.indigo.withOpacity(0.5)),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                maxLines: null,
              ),
              const SizedBox(height: 30),
              Center(child: Text('a: $_targetLanguage')),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_translatedText ?? ''),
              ),
              const SizedBox(height: 30),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.indigo,
                textColor: Colors.white,
                onPressed: _copyText,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Copiar Texto'),
                ),
              ),
              const SizedBox(height: 10),
              MaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                color: Colors.indigo,
                textColor: Colors.white,
                onPressed: _translateText,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Traducir'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDropdown(false),
                  const SizedBox(width: 20),
                  _buildDropdown(true),
                ],
              ),
              const SizedBox(height: 20),
              if (_pdfPath != null) ...[
                MaterialButton(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  color: Colors.indigo,
                  textColor: Colors.white,
                  onPressed: _downloadPDF,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Download PDF'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(bool isTarget) {
    final languages = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
    };

    return Expanded(
      child: DropdownButtonFormField<String>(
        value: isTarget ? _targetLanguage : _sourceLanguage,
        elevation: 16,
        style: const TextStyle(color: Colors.blue),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onChanged: (String? code) {
          if (code != null) {
            setState(() {
              if (isTarget) {
                _targetLanguage = code;
              } else {
                _sourceLanguage = code;
              }
            });
          }
        },
        items: languages.entries.map<DropdownMenuItem<String>>((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _translateText() async {
    FocusScope.of(context).unfocus();
    final inputText = _controller.text;
    if (inputText.isNotEmpty) {
      final translation = await translator.translate(
        inputText,
        from: _sourceLanguage,
        to: _targetLanguage,
      );
      setState(() {
        _translatedText = translation.text;
      });
      await _generatePDF(_translatedText!);
    }
  }

  Future<void> _generatePDF(String text) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text(text),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/translated_text.pdf");
    await file.writeAsBytes(await pdf.save());
    setState(() {
      _pdfPath = file.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generado')),
    );
  }

  Future<void> _downloadPDF() async {
    if (_pdfPath == null) return;

    final status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_pdfPath!);
      final newFile = await file.copy('${directory.path}/translated_text.pdf');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF guardado en ${newFile.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de almacenamiento denegado')),
      );
    }
  }

  void _copyText() {
    if (_translatedText != null) {
      Clipboard.setData(ClipboardData(text: _translatedText.toString()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto copiado al portapapeles')),
      );
    }
  }
}
