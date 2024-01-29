import 'package:flutter_contacts/flutter_contacts.dart';
import '../utils/permissions_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsController {
  static bool isInitialized = false;

  static Future<List<Contact>?> getContactsList() async {
    await requestContactPermissions();

    return await FlutterContacts.getContacts(
        withPhoto: true, withAccounts: true);
  }

  static Future<bool> contactExists(Contact contact) async {
    await requestContactPermissions();

    if (contact.id.isNotEmpty) {
      var contactData = await FlutterContacts.getContact(contact.id);

      if (contactData != null) {
        return true;
      }
    }

    return false;
  }

  static Future<Contact> createNewContact(Contact contact) async {
    await requestContactPermissions();

    return await FlutterContacts.insertContact(contact);
  }

  static Future<Contact> updateContact(Contact contact) async {
    await requestContactPermissions();

    return await FlutterContacts.updateContact(contact);
  }

  static Future<void> requestContactPermissions() async {
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
  }
}
