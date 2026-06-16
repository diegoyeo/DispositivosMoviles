import 'package:url_launcher/url_launcher.dart';

import 'api_exception.dart';

class LauncherService {
  static Future<void> openSalonMap(String salon) async {
    final query = Uri.encodeComponent(
      '$salon ESCOM IPN Gustavo A. Madero Ciudad de Mexico',
    );
    final url = Uri.parse(
      'https://www.openstreetmap.org/search?query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw const ApiException(
        message: 'No se pudo abrir el mapa',
        type: ApiErrorType.unknown,
      );
    }
  }

  static Future<void> openSupport({
    String subject = 'Soporte MOVIDA ETS ESCOM',
    String body = '',
  }) async {
    final url = Uri(
      scheme: 'mailto',
      path: 'cosmesantamariaosvaldo@gmail.com',
      queryParameters: {'subject': subject, 'body': body},
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw const ApiException(
        message:
            'No se pudo abrir el correo. Escríbenos a: cosmesantamariaosvaldo@gmail.com',
        type: ApiErrorType.unknown,
      );
    }
  }

  static Future<void> openEscomMap() async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=19.5043&mlon=-99.1467&zoom=17',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
