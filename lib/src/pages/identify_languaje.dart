import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class LanguageIdentifierView extends StatefulWidget {
  const LanguageIdentifierView({super.key});

  @override
  State<LanguageIdentifierView> createState() => _LanguageIdentifierViewState();
}

class _LanguageIdentifierViewState extends State<LanguageIdentifierView> {
  final List<IdentifiedLanguage> _identifiedLanguages = <IdentifiedLanguage>[];
  final TextEditingController _controller = TextEditingController();
  final _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);
  var _identifiedLanguage = '';

  @override
  void dispose() {
    _languageIdentifier.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Identificación de idioma',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ingrese el texto a identificar',
                labelText: 'Ingresa el Texto',
                labelStyle: const TextStyle(color: Colors.indigo),
                hintStyle: TextStyle(color: Colors.indigo.withOpacity(0.5)),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          _identifiedLanguage == ''
              ? Container()
              : Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'Idioma identificado: $_identifiedLanguage',
                    style: const TextStyle(fontSize: 20),
                  )),
          MaterialButton(
              color: Colors.indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              textColor: Colors.white,
              onPressed: _identifyLanguage,
              child: const Text('Identificar idioma')),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _identifiedLanguages.length,
            itemBuilder: (context, index) {
              final languageTag = _identifiedLanguages[index].languageTag;
              final languageName = _getLanguageName(languageTag);
              return ListTile(
                title: Text(
                    'Language: $languageName  Confidence: ${_identifiedLanguages[index].confidence.toString()}'),
              );
            },
          )
        ],
      ),
    );
  }

  Future<void> _identifyLanguage() async {
    if (_controller.text == '') return;
    String language;
    try {
      language = await _languageIdentifier.identifyLanguage(_controller.text);
      language = _getLanguageName(language);
    } on PlatformException catch (pe) {
      if (pe.code == _languageIdentifier.undeterminedLanguageCode) {
        language = 'error: no language identified!';
      }
      language = 'error: ${pe.code}: ${pe.message}';
    } catch (e) {
      language = 'error: ${e.toString()}';
    }
    setState(() {
      _identifiedLanguage = language;
    });
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'Ingles';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Francés';
      case 'de':
        return 'Alemán';
      case 'it':
        return 'Italiano';
      case 'pt':
        return 'Portugués';
      case 'ru':
        return 'Ruso';
      case 'ja':
        return 'Japonés';
      case 'ko':
        return 'Coreano';
      case 'zh':
        return 'Chino';
      case 'ar':
        return 'Árabe';
      // Agrega más idiomas según sea necesario
      default:
        return languageCode;
    }
  }
}
