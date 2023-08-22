import 'package:geolocator/geolocator.dart';
import '../utils/permissions_controller.dart';

class GeoController {
  static Future<void> geoInit() async {
    LocationPermission permission =
        await PermissionsController.checkGeolocationPermissions();
    await PermissionsController.requestGeolocationPermissions();
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<Position?> getCurrentLocation() async {
    var temp = await Geolocator.getLocationAccuracy();

    try {
      return await Geolocator.getCurrentPosition();
    } catch (ex) {
      print('Timeout in getCurrentPosition method');
      return null;
    }
  }
}
