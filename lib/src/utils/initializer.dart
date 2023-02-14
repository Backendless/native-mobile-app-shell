import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'coder.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';

class ShellInitializer {
  static const platform = MethodChannel('backendless/push_notifications');

  static Future<void> initApp({required String pathToSettings}) async {
    kNotificationSlideDuration = const Duration(milliseconds: 500);
    kNotificationDuration = const Duration(milliseconds: 7000);

    final initData = await Coder.readJson(path: pathToSettings);

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

    await Backendless.setUrl(initData['serverURL']);
  }
}
