import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:square_in_app_payments/in_app_payments.dart';
import 'package:square_in_app_payments/models.dart';
import '../types/push_notification_message.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';
import '../push_notifications/message_notification.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../utils/geo_controller.dart';
import 'bridge_event.dart';

class BridgeUIBuilderFunctions {
  static const GOOGLE_CLIENT_ID_IOS = 'xxxxxx.apps.googleusercontent.com';
  static const GOOGLE_CLIENT_ID_WEB = 'xxxxxx.apps.googleusercontent.com';

  static late LocationPermission permission;

  static Future<dynamic> registerForPushNotifications(
      {List<String>? channels}) async {
    List<String> channelsList = [];

    if (channels != null)
      channelsList.addAll(channels);
    else
      channelsList.add('default');

    try {
      DateTime time = DateTime.now().add(const Duration(days: 15));
      return await Backendless.messaging
          .registerDevice(channelsList, time, onMessage);
    } catch (ex) {
      return ex;
    }
  }

  static Future<void> addListener(BridgeEvent event) async {
    // if (event.isExist) throw Exception('Event with same id already exists');
    BridgeEvent.addToContainer(event);
  }

  static Future<bool> removeListener(String name, String id) async {
    return BridgeEvent.removeEvent(name, id);
  }

  static Future<Position?> getCurrentLocation() async {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await GeoController.getCurrentLocation();
  }

  static void onMessage(Map<String, dynamic> message) async {
    AudioCache pushSound = AudioCache();
    pushSound.play('notification_sounds/push_sound.wav');
    PushNotificationMessage notification = PushNotificationMessage();

    if (io.Platform.isIOS) {
      Map pushData = message['aps']['alert'];
      notification.title = pushData['title'];
      notification.body = pushData['body'];
    } else if (io.Platform.isAndroid) {
      notification.title = message['android-content-title'];
      notification.body = message['message'];
    }

    showSimpleNotification(
      MessageNotification(
        id: 0,
        title: notification.title,
        body: notification.body,
      ),
      slideDismissDirection: DismissDirection.up,
      contentPadding: EdgeInsets.zero,
      background: Color.fromRGBO(0, 0, 0, 0.0),
      foreground: Color.fromRGBO(0, 0, 0, 0.0),
    );
  }

  static Future<void> alertUnsupportedPlatform(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unsupported for this platform'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Signing in with an Apple ID is not supported for this platform.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  static Future setIOSCardEntryTheme() async {
    var themeConfiguationBuilder = IOSThemeBuilder();
    themeConfiguationBuilder.saveButtonTitle = 'Save';
    themeConfiguationBuilder.errorColor = RGBAColorBuilder()
      ..r = 255
      ..g = 0
      ..b = 0;
    themeConfiguationBuilder.tintColor = RGBAColorBuilder()
      ..r = 36
      ..g = 152
      ..b = 141;
    themeConfiguationBuilder.keyboardAppearance = KeyboardAppearance.light;
    themeConfiguationBuilder.messageColor = RGBAColorBuilder()
      ..r = 114
      ..g = 114
      ..b = 114;

    await InAppPayments.setIOSCardEntryTheme(themeConfiguationBuilder.build());
  }
}
