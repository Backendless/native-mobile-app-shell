import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'coder.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ShellInitializer {
  static const platform = MethodChannel('backendless/push_notifications');
  static bool bridgeInitialized = false;
  static StreamController initController = StreamController.broadcast();
  static Map? waitingInitializationData;
  static NotificationAppLaunchDetails? launchDetails;

  static Future<void> initApp({required String pathToSettings}) async {
    kNotificationSlideDuration = const Duration(milliseconds: 500);
    kNotificationDuration = const Duration(milliseconds: 7000);

    try {
      final initData = await Coder.readJson(path: pathToSettings);

      launchDetails = await Backendless.appLaunchDetails;

      if (initData['apiDomain'] != null) {
        await Backendless.initApp(
          customDomain: initData['apiDomain'],
        );
        return;
      }

      await Backendless.initApp(
          applicationId: initData['appId'],
          iosApiKey: initData['apiKey'],
          androidApiKey: initData['apiKey']);

      Backendless.url = initData['serverURL'];
      // await Firebase.initializeApp();
      // await FirebaseMessaging.instance
      //     .setForegroundNotificationPresentationOptions(
      //   alert: true,
      //   badge: true,
      //   sound: true,
      // );
      // await FirebaseMessaging.instance.requestPermission(
      //   alert: true,
      //   announcement: false,
      //   badge: true,
      //   carPlay: false,
      //   criticalAlert: false,
      //   provisional: false,
      //   sound: true,
      // );
    } catch (ex) {
      print('====== Error during initialization application ======\n$ex');
    }
  }
}
