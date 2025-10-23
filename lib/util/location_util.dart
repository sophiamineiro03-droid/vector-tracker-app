import 'package:geolocator/geolocator.dart';

class LocationUtil {
  /// Determina a posição atual do dispositivo.
  ///
  /// Quando os serviços de localização não estão ativados ou as permissões
  /// são negadas, a função Future retornará um erro.
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Testa se os serviços de localização estão ativados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviços de localização não estão ativados, não é possível continuar.
      return Future.error('Os serviços de localização estão desativados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // As permissões foram negadas, da próxima vez você pode tentar
        // pedir as permissões novamente (aqui não é o caso).
        return Future.error('As permissões de localização foram negadas.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // As permissões foram negadas para sempre, lide com isso apropriadamente.
      return Future.error(
          'As permissões de localização foram negadas permanentemente, não é possível solicitar permissões.');
    }

    // Quando chegamos aqui, as permissões foram concedidas e podemos
    // continuar a acessar a posição do dispositivo.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
