import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../types/push_notification_message.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';
import '../push_notifications/message_notification.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BridgeUIBuilderFunctions {
  static const CLIENT_ID_IOS =
      'xxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com';
  static const CLIENT_ID_WEB =
      'xxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com';
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
    BackendlessUser? user;
    String? result = await Backendless.userService.getAuthorizationUrlLink(
      providerCode,
      fieldsMappings: fieldsMappings,
      scope: scope,
    );

    String? userId;
    String? userToken;

    if (providerCode == 'googleplus') {
      GoogleSignIn _googleSignIn = GoogleSignIn(
        clientId: io.Platform.isIOS ? CLIENT_ID_IOS : CLIENT_ID_WEB,
        scopes: [
          'email',
          'https://www.googleapis.com/auth/plus.login',
        ],
      );

      await _googleSignIn.signOut();
      var resLog = await _googleSignIn.signIn();
      var token = (await resLog!.authentication).accessToken;

      user = await Backendless.userService
          .loginWithOauth2(providerCode, token!, <String, String>{}, false);
      userId = user!.getUserId();

      if (io.Platform.isAndroid) {
        userToken = await Backendless.userService.getUserToken();
        user.setProperty('user-token', userToken);
      } else {
        userToken = user.getProperty('userToken');
        user.removeProperty('userToken');
        user.setProperty('user-token', userToken);
      }
    } else if (result?.isNotEmpty ?? false) {
      await showDialog(
          useSafeArea: true,
          context: context,
          builder: (context) {
            return Container(
              width: MediaQuery.of(context).size.width * 1.2,
              height: MediaQuery.of(context).size.height,
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
                                disableHorizontalScroll: true,
                                cacheEnabled: true,
                                userAgent:
                                    'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1'
                                //providerCode != 'facebook' ? 'random' : '',
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
                            print('${navigationAction.request.url}');
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
            );
          });
    }

    if (userId != null && user == null) {
      user = await Backendless.userService.findById(userId!);
      user!.setProperty('user-token', userToken);
    }

    return user;
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
}
