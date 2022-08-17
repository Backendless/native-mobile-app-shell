import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../types/push_notification_message.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';
import '../push_notifications/message_notification.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BridgeUIBuilderFunctions {
  /*static late FlutterLocalNotificationsPlugin _notifications;
  static late AndroidInitializationSettings androidInit;
  static late IOSInitializationSettings iosInit;
  static late InitializationSettings initSetting;
  static late AndroidNotificationDetails androidDetails;
  static late IOSNotificationDetails iosDetails;
  static late NotificationDetails generalNotificationDetails;
  static bool isInitialized = false;*/

  static Future<dynamic> registerForPushNotifications(
      {List<String>? channels}) async {
    List<String> channelsList = [];

    if (channels != null)
      channelsList.addAll(channels);
    else
      channelsList.add('default');

    try {
      return await Backendless.messaging
          .registerDevice(channelsList, null, onMessage);
    } catch (ex) {
      return ex;
    }
  }

  static Future<BackendlessUser?> socialLogin(
      String providerCode, BuildContext context,
      {Map<String, String>? fieldsMappings, List<String>? scope}) async {
    String? result = await Backendless.userService.getAuthorizationUrlLink(
      providerCode,
      fieldsMappings: fieldsMappings,
      scope: scope,
    );

    String? userId;
    String? userToken;

    if (result?.isNotEmpty ?? false)
      await showDialog(
          useSafeArea: true,
          context: context,
          builder: (context) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Expanded(
                        child: InAppWebView(
                            initialUrlRequest: URLRequest(
                              url: Uri.parse(result!),
                            ),
                            initialOptions: InAppWebViewGroupOptions(
                              crossPlatform: InAppWebViewOptions(
                                useShouldOverrideUrlLoading: true,
                                disableHorizontalScroll: false,
                                userAgent:
                                    providerCode != 'facebook' ? 'random' : '',
                              ),
                              android: AndroidInAppWebViewOptions(
                                useHybridComposition: true,
                                safeBrowsingEnabled: false,
                              ),
                            ),
                            onLoadStop: (controller, url) async {
                              print('!!! called onLoadStop');
                              print("AUTH_WEBVIEW: $url");
                            },
                            shouldOverrideUrlLoading:
                                (controller, navigationAction) async {
                              print('override');
                              if (navigationAction.request.url
                                  .toString()
                                  .contains('userId')) {
                                userId = navigationAction
                                    .request.url!.queryParameters['userId'];
                                userToken = navigationAction
                                    .request.url!.queryParameters['userToken'];
                                Navigator.pop(context);
                              }
                              return null;
                            }))
                  ],
                ),
              ),
            );
          });

    if (userId != null) {
      BackendlessUser? user = await Backendless.userService.findById(userId!);
      user!.setProperty('user-token', userToken);
      return user;
    }

    return null;
  }

  static void onMessage(Map<String, dynamic> message) async {
    /*if (!isInitialized) {
      androidInit =
          AndroidInitializationSettings('backendless_logo'); //for logo
      iosInit = IOSInitializationSettings();
      initSetting = InitializationSettings(android: androidInit, iOS: iosInit);
      _notifications = FlutterLocalNotificationsPlugin();
      await _notifications.initialize(initSetting);
      androidDetails =
          AndroidNotificationDetails('1', 'channelName', 'channel Description');
      iosDetails = IOSNotificationDetails();
      generalNotificationDetails =
          NotificationDetails(android: androidDetails, iOS: iosDetails);
      isInitialized = true;
    }

    await _notifications.show(0, message['android-content-title'],
        message['message'], generalNotificationDetails);
        */
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
      background: Color.fromRGBO(0, 0, 0, 0.4),
      foreground: Color.fromRGBO(0, 0, 0, 0.4),
    );
  }
}
