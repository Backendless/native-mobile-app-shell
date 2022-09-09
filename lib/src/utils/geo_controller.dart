import 'package:geolocator/geolocator.dart';

class GeoController {
  static Future<void> geoInit() async {
    LocationPermission permission = await Geolocator.checkPermission();
    await Geolocator.requestPermission();
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<Position?> getCurrentLocation() async {
    var temp = await Geolocator.getLocationAccuracy();

    try {
      return await Geolocator.getCurrentPosition(
          timeLimit: Duration(seconds: 5));
    } catch (ex) {
      print('Timeout in getCurrentPosition method');
      return null;
    }
  }
}
