import 'package:contacts_service/contacts_service.dart';
import '../utils/permissions_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsController {
  static bool isInitialized = false;

  static Future<List<Contact>?> getContactsList() async {
    if (!isInitialized) {
      var isGranted =
          await PermissionsController.isContactsPermissionsGranted();

      if (!isGranted) {
        var status = await PermissionsController.requestContactsPermissions();

        if (status.isDenied || status.isPermanentlyDenied) {
          throw Exception(
              'Contacts permissions was not granted by user. Access to contact list is denied');
        }

        isInitialized = true;
        //some work with status if need
      }
    }

    return await ContactsService.getContacts();
  }
}
