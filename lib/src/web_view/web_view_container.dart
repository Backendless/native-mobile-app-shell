import 'dart:io' as io;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/initializer.dart';
import '../bridge/bridge.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../types/push_notification_message.dart';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'package:overlay_support/overlay_support.dart';
import '../push_notifications/message_notification.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewContainer extends StatefulWidget {
  final syncPath;

  WebViewContainer(this.syncPath);

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

  @override
  _WebViewContainerState createState() => _WebViewContainerState(syncPath);
}

class _WebViewContainerState extends State<WebViewContainer> {
  final _key = UniqueKey();

  String? syncPath;
  bool registerForPushNotificationsOnRun = true;

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions? options;
  Bridge? manager;
  _WebViewContainerState(this.syncPath);

  @override
  void initState() {
    super.initState();
    options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        allowUniversalAccessFromFileURLs: true,
        allowFileAccessFromFileURLs: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        javaScriptCanOpenWindowsAutomatically: true,
        javaScriptEnabled: true,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        useOnLoadResource: true,
      ),
      android: AndroidInAppWebViewOptions(
        mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        useHybridComposition: true,
        allowFileAccess: true,
        allowContentAccess: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
        isPagingEnabled: true,
        disallowOverScroll: true,
      ),
    );

    if (registerForPushNotificationsOnRun) {
      WebViewContainer.registerForPushNotifications();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () => _exitApp(context),
          child: InAppWebView(
            key: _key,
            initialOptions: options,
            onWebViewCreated: (InAppWebViewController controller) async {
              webViewController = controller;
              manager = Bridge(controller: webViewController!);
              setBridge();

              await controller.loadFile(assetFilePath: syncPath!);
            },
            androidOnPermissionRequest: (InAppWebViewController controller,
                String origin, List<String> resources) async {
              return PermissionRequestResponse(
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              var uri = navigationAction.request.url!;

              if (![
                "http",
                "https",
                "file",
                "chrome",
                "data",
                "javascript",
                "about"
              ].contains(uri.scheme)) {
                if (await canLaunch(uri.toString())) {
                  // Launch the App
                  await launch(
                    uri.toString(),
                  );
                  // and cancel the request
                  return NavigationActionPolicy.CANCEL;
                }
              }

              return NavigationActionPolicy.ALLOW;
            },
            onConsoleMessage: (controller, consoleMessage) {
              print(consoleMessage);
            },
            onLoadStart: (InAppWebViewController controller, url) {},
            onLoadError: (controller, url, code, message) {
              print('code: $code\n'
                  'url: $url\n'
                  'message: $message');
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  titlePadding: EdgeInsets.all(8.0),
                  insetPadding: EdgeInsets.symmetric(horizontal: 8.0),
                  contentPadding: EdgeInsets.all(8.0),
                  title: Text('Error'),
                  content: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          children: [
                            Text(
                              'code:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              code.toString(),
                            ),
                          ],
                        ),
                        Wrap(
                          children: [
                            Text(
                              'message:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              message,
                              maxLines: 10,
                              softWrap: true,
                            ),
                            Text(
                              '\nTry restarting the app',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Ok'),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                  scrollable: true,
                ),
              );
            },
            onLoadHttpError: (controller, url, code, message) {
              print('code: $code\n'
                  'url: $url\n'
                  'message: $message');
            },
            onLoadStop: (controller, url) async {
              print('load stopped: $url');
              print('progress: ' + (await controller.getProgress()).toString());
            },
            onLoadResource: (controller, loadedResources) {
              print('type: $loadedResources');
            },
            onProgressChanged: (controller, progress) {
              print('progress: $progress %');
            },
            iosOnNavigationResponse: (controller, response) async {
              print(response.response);
            },
            onDownloadStart: (controller, url) {
              print('Downloading started with url: $url');
            },
            onPrint: (controller, url) {
              print('onPrint event: $url');
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await webViewController!.canGoBack()) {
      print('onwill goback');
      webViewController!.goBack();
      return Future.value(false);
    } else {
      //await SystemNavigator.pop();
      return Future.value(true);
    }
  }

  void setBridge() async {
    if (!io.Platform.isAndroid ||
        await AndroidWebViewFeature.isFeatureSupported(
            AndroidWebViewFeature.WEB_MESSAGE_LISTENER))
      await manager!.addWebMessageListener();
  }
}
