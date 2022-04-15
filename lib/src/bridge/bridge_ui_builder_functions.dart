import 'package:audioplayers/audioplayers.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:flutter/material.dart';
import 'package:native_app_shell_mobile/src/push_notifications/message_notification.dart';
import 'package:native_app_shell_mobile/src/types/push_notification_message.dart';
import 'package:native_app_shell_mobile/src/web_view/web_view_container.dart';
import 'package:overlay_support/overlay_support.dart';
import 'dart:io' as io;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BridgeUIBuilderFunctions {
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

  static Future<dynamic> socialLogin(String providerCode, BuildContext context,
      {Map<String, String>? fieldsMappings, List<String>? scope}) async {
    String? result = await Backendless.userService.getAuthorizationUrlLink(
      providerCode,
      fieldsMappings: fieldsMappings,
      scope: scope,
    );

    String? userId;

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
                                disableHorizontalScroll: true,
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
                                Navigator.pop(context);
                              }
                            }))
                  ],
                ),
              ),
            );
          });

    if (userId != null) return await Backendless.userService.findById(userId!);

    return;
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

    showOverlayNotification((context) {
      return MessageNotification(
        title: notification.title,
        body: notification.body,
      );
    });
  }
}
