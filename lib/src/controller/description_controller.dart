// description_controller.dart
import 'package:diacritic/diacritic.dart';

class DescriptionController {
  final Map<String, String> descriptions = {
    'bird':
        'Pájaro. Los pájaros son vertebrados de sangre caliente con plumas y alas. Son conocidos por su capacidad de volar, aunque no todos los pájaros pueden hacerlo.',
    'cat':
        'Gato. Los gatos son pequeños mamíferos carnívoros que son populares como mascotas. Son conocidos por su agilidad y sus habilidades de caza.',
    'dog':
        'Perro. Los perros son mamíferos domesticados que son conocidos por su lealtad y compañía. Son una de las mascotas más populares en el mundo.',
    'house':
        'Casa. Las casas son edificios destinados a la habitación humana. Proporcionan refugio y un lugar para vivir y descansar.',
    'tree':
        'Árbol. Los árboles son plantas perennes con un tronco leñoso y ramas. Son conocidos por su capacidad de producir oxígeno y proporcionar sombra.',
    'car':
        'Coche. Un coche es un vehículo de motor con ruedas que se utiliza para el transporte de personas y mercancías. Es uno de los medios de transporte más comunes.',
    'flower':
        'Flor. Las flores son órganos reproductivos de las plantas que producen semillas. Son conocidas por su belleza y fragancia.',
    'fruit':
        'Fruta. Las frutas son órganos de las plantas que contienen semillas. Son conocidas por su sabor dulce y su alto contenido de vitaminas.',
    'vegetable':
        'Verdura. Las verduras son plantas comestibles que se cultivan para su consumo. Son conocidas por su alto contenido de nutrientes y fibra.',
    'book':
        'Libro. Un libro es una obra escrita o impresa que contiene información o entretenimiento. Es una fuente importante de conocimiento y cultura.',
    'computer':
        'Computadora. Una computadora es una máquina electrónica que procesa datos y realiza cálculos. Es una herramienta importante en la era digital.',
    'phone':
        'Teléfono. Un teléfono es un dispositivo de comunicación que se utiliza para hacer llamadas y enviar mensajes. Es una herramienta esencial en la vida moderna.',
    'watch':
        'Reloj. Un reloj es un dispositivo que se utiliza para medir el tiempo. Es una herramienta esencial para la organización y la puntualidad.',
    'glasses':
        'Gafas. Las gafas son dispositivos ópticos que se utilizan para corregir la visión. Son conocidas por su capacidad de mejorar la vista.',
    'shirt':
        'Camisa. Una camisa es una prenda de vestir que se usa en la parte superior del cuerpo. Es una prenda básica en el armario de cualquier persona.',
    'flutter':
        'Flutter. Flutter es un marco de desarrollo de código abierto creado por Google. Se utiliza para desarrollar aplicaciones móviles de alta calidad en iOS y Android.',
    'dart':
        'Dart. Dart es un lenguaje de programación desarrollado por Google. Se utiliza para desarrollar aplicaciones web y móviles de alto rendimiento.',
    'firebase':
        'Firebase. Firebase es una plataforma de desarrollo de aplicaciones móviles creada por Google. Proporciona una amplia gama de servicios en la nube para desarrolladores.',
    'google':
        'Google. Google es una empresa de tecnología multinacional que se especializa en servicios en línea y software. Es conocida por su motor de búsqueda y otros productos.',
    'android':
        'Android. Android es un sistema operativo móvil desarrollado por Google. Es el sistema operativo más utilizado en el mundo para dispositivos móviles.',
    'ios':
        'iOS. iOS es un sistema operativo móvil desarrollado por Apple. Es el sistema operativo utilizado en los dispositivos móviles de Apple, como el iPhone y el iPad.',
    'macos':
        'macOS. macOS es un sistema operativo de escritorio desarrollado por Apple. Es el sistema operativo utilizado en los ordenadores Mac de Apple.',
    'windows':
        'Windows. Windows es un sistema operativo de escritorio desarrollado por Microsoft. Es uno de los sistemas operativos más utilizados en el mundo.',
    'linux':
        'Linux. Linux es un sistema operativo de código abierto basado en Unix. Es conocido por su estabilidad, seguridad y flexibilidad.',
    'angular':
        'Angular. Angular es un marco de desarrollo de aplicaciones web desarrollado por Google. Se utiliza para crear aplicaciones web de una sola página y aplicaciones empresariales.',
    'react':
        'React. React es una biblioteca de JavaScript desarrollada por Facebook. Se utiliza para crear interfaces de usuario interactivas y dinámicas en aplicaciones web.',
    'vue':
        'Vue. Vue es un marco de desarrollo de aplicaciones web progresivo desarrollado por Evan You. Se utiliza para crear aplicaciones web interactivas y dinámicas.',
    'flutter web':
        'Flutter Web. Flutter Web es una versión de Flutter que permite desarrollar aplicaciones web utilizando el mismo código base que las aplicaciones móviles.',
  };

  String getDescription(String recognizedText) {
    String normalizedText = removeDiacritics(recognizedText).toLowerCase();
    String description =
        'No hay descripción disponible para el texto reconocido.';
    descriptions.forEach((key, value) {
      if (normalizedText.contains(removeDiacritics(key).toLowerCase())) {
        description = value;
      }
    });
    return description;
  }
}
