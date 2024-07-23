import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsController {
  static Future<LocationPermission> checkGeolocationPermissions() async {
    return await Geolocator.checkPermission();
  }

  static Future<void> requestGeolocationPermissions() async {
    await Geolocator.requestPermission();
  }

  static Future<bool> isContactsPermissionsGranted() async {
    var isGrantedContactsPermissions =
        await Permission.contacts.status.isGranted;

    return isGrantedContactsPermissions;
  }

  static Future<PermissionStatus> requestContactsPermissions() async {
    var statusContactsPermissions = await Permission.contacts.request();

    return statusContactsPermissions;
  }
}
