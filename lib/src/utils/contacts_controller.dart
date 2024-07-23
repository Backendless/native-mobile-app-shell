import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_contacts/flutter_contacts.dart';
import '../utils/permissions_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsController {
  static bool isInitialized = false;

  static Future<List<Contact>?> getContactsList() async {
    await requestContactPermissions();

    return await FlutterContacts.getContacts(
        withPhoto: true, withAccounts: true, withProperties: true);
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

  static Future<Map<String, dynamic>> normalizeContact(Map contact) async {
    Name contactName = Name();
    contactName.first = contact['firstName'] ?? '';
    contactName.last = contact['lastName'] ?? '';
    contactName.middle = contact['middleName'] ?? '';
    contactName.prefix = contact['prefix'] ?? '';
    contactName.suffix = contact['suffix'] ?? '';

    List<Phone> phones = List<Phone>.empty(growable: true);
    if ((contact['phones'] as List?)?.isNotEmpty ?? false) {
      phones = (contact['phones'] as List).map((e) => Phone(e)).toList();
    }

    List<Email> emails = List<Email>.empty(growable: true);
    if ((contact['emails'] as List?)?.isNotEmpty ?? false) {
      emails = (contact['emails'] as List).map((e) => Email(e)).toList();
    }

    List<Address> address = List<Address>.empty(growable: true);
    if ((contact['postalAddresses'] as List?)?.isNotEmpty ?? false) {
      address =
          (contact['postalAddresses'] as List).map((e) => Address(e)).toList();
    }

    List<Organization> organizations = List<Organization>.empty(growable: true);
    Organization organization = Organization();

    if ((contact['company'] as String?)?.isNotEmpty ?? false) {
      organization.company = contact['company'];
    }
    if ((contact['jobTitle'] as String?)?.isNotEmpty ?? false) {
      organization.title = contact['jobTitle'];
    }
    organizations.add(organization);

    Event? birthday;
    if ((contact['birthday'] as Map?)?.isNotEmpty ?? false) {
      birthday = Event.fromJson(contact['birthday']);
    }
    List<Event> birthdays = List<Event>.empty(growable: true);
    if (birthday != null) {
      birthdays.add(birthday);
    }

    Uint8List? avatar;
    if ((contact['avatar'] as String?)?.isNotEmpty ?? false) {
      avatar = base64Decode(contact['avatar']);
    }

    Account? account;
    if (contact['androidAccountName'] != null ||
        contact['androidAccountType'] != null) {
      account = Account.fromJson({
        'type': contact['androidAccountType'],
        'name': contact['androidAccountName'],
      });
    }
    List<Account> accounts = List<Account>.empty(growable: true);
    if (account != null) {
      accounts.add(account);
    }

    Map<String, dynamic> normalizeContact = {
      'phones': phones,
      'emails': emails,
      'addresses': address,
      'organizations': organizations,
      'name': contactName,
      'events': birthdays,
      'photo': avatar,
      'accounts': accounts,
      'displayName': (contact['displayName'] as String?) ?? '',
    };

    return normalizeContact;
  }
}
